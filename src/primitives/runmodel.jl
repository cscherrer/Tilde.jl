export runmodel

@inline function inkeys(::StaticSymbol{s}, ::Type{NamedTuple{N,T}}) where {s,N,T}
    return s ∈ N
end

@inline function inkeys(::StaticSymbol{s}, ::NamedTuple{N,T}) where {s,N,T}
    return s ∈ N
end

function make_body(M, f, m::AbstractModel)
    make_body(M, body(m))
end

call(f, g, args...; kwargs...) = g(args...; kwargs...)

function make_body(M, ast::Expr, argsT, obsT, parsT)
    knownvars = union(keys.(schema.((argsT, obsT, parsT)))...)
    function go(ex, scope = (bounds = Var[], freevars = Var[], bound_inits = Symbol[]))
        @match ex begin
            :(($x, $l) ~ $rhs) => begin
                # varnames = Tuple(locals(l)) # ∪ locals(rhs))
                # varvals = Expr(:tuple, varnames...)

                x = unsolve(x)
                l = unsolve(l)
                # q = quote
                #     _vars = NamedTuple{$varnames}($varvals)
                #     # @show _vars
                # end

                # unsolved_lhs = unsolve(lhs)
                # x == unsolved_lhs && delete!(varnames, x)
                qx = QuoteNode(x)
                sx = static(x)
                # X = to_type(unsolved_lhs)
                # M = to_type(unsolve(rhs))

                rhs = unsolve(rhs)

                z_obs = if inkeys(sx, obsT)
                    # TODO: Even if `x` is observed, we may have `lens(x) == missing`
                    :($Observed{$qx}(_obs.$x))
                elseif inkeys(sx, argsT)
                    :($Unobserved{$qx}(_args.$x))
                elseif inkeys(sx, parsT)
                    :($Unobserved{$qx}(_pars.$x))
                else
                    :($Unobserved{$qx}(missing))
                end

                @gensym xj

                q = quote
                    ($xj, _ctx) = $tilde(_cfg, $z_obs, $l, AbstractMeasure($rhs), _ctx)
                    # _ctx isa Tilde.ReturnNow && return _ctx.value
                end

                # If we have e.g.`x ~ ...`, the lens is `identity`, but that's
                # only after it's evaluated. Syntactically it starts as `(opticcompose)()`.
                if l == Expr(:call, Accessors.opticcompose)
                    # An identity lens means we've never seen this variable before
                    push!(q.args, :($x = $xj))
                else
                    # For other lenses, we need to refer to the parent object
                    push!(q.args, :($x = $set($x, $Lens!!($l), $xj)))
                end

                q
            end

            :(return $r) => quote
                return Tilde.retfun(_cfg, $r, _ctx)
                # return Tilde.retfun(_cfg, NamedTuple{$paramnames}($paramvals) => $r, _ctx)
            end

            Expr(:scoped, new_scope, ex) => begin
                go(ex, new_scope)
            end

            Expr(head, args...) => Expr(head, map(Base.Fix2(go, scope), args)...)

            x => x
        end
    end

    body = go(@q begin
        $(solve_scope(opticize(ast)))
    end) |> unsolve |> MacroTools.flatten

    body
end

function _get_gg_func_body(::GG.RuntimeFn{Args,Kwargs,Body}) where {Args,Kwargs,Body}
    Body
end

# function _get_gg_func_body(ex)
#     error(ex)
# end

struct KnownVars{A,O,P}
    args::A
    obs::O
    pars::P
end

@generated function runmodel(_cfg, _mc::MC, _pars::NamedTuple{N,T}, _ctx) where {MC,N,T}
    _m = type2model(MC)
    M = getmodule(_m)

    argsT = argvalstype(MC)
    obsT = obstype(MC)
    parsT = NamedTuple{N,T}

    body = _m.body |> loadvals(argsT)

    paramnames = tuple(parameters(_m)...)
    paramvals = Expr(:tuple, paramnames...)
    argsT = schema(argsT)
    obsT = schema(obsT)
    parsT = schema(parsT)
    body = make_body(M, body, argsT, obsT, parsT)

    q = MacroTools.flatten(@q function (_mc, _cfg, _ctx, _pars)
        _args = $argvals(_mc)
        _obs = $observations(_mc)
        # _vars = KnownVars(_args, _obs, _pars)
        $body
        # If body doesn't have a return, default to `return ctx`
        _params = NamedTuple{$paramnames}($paramvals)
        return Tilde.retfun(_cfg, _params, _ctx)
    end)

    q = from_type(_get_gg_func_body(mk_function(M, q))) |> MacroTools.flatten

    pushfirst!(q.args, :($(Expr(:meta, :inline))))

    q
end
