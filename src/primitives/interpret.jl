export interpret

@inline function inkeys(::StaticSymbol{s}, ::Type{NamedTuple{N,T}}) where {s,N,T}
    return s ∈ N
end

function interpret(m::Model{A,B,M}, tilde, ctx0) where {A,B,M}
    theModule = getmodule(m)
    mk_function(theModule, make_body(theModule, m.body, tilde, ctx0))
end

function make_body(M, f, m::AbstractModel)
    make_body(M, body(m))
end

struct Observed{T}
    value::T
end

struct Unobserved{T}
    value::T
end

function make_body(M, f, ast::Expr, retfun, argsT, obsT, parsT)
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

                inargs = inkeys(sx, argsT)
                inobs = inkeys(sx, obsT)
                inpars = inkeys(sx, parsT)
                rhs = unsolve(rhs)

                xval = if inobs
                    :($Observed($x))
                else
                    (x ∈ knownvars ? :($Unobserved($x)) : :($Unobserved(missing)))
                end
                st = :(($x, _ctx, _retn) = $tilde($f, $l, $sx, $xval, $rhs, _cfg, _ctx))
                qst = QuoteNode(st)
                q = quote
                    # println($qst)
                    $st
                    _retn isa Tilde.ReturnNow && return _retn.value
                end

                q
            end

            :(return $r) => :(return $retfun($r, _ctx))

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

@generated function gg_call(
    ::F,
    _mc::MC,
    _pars::NamedTuple{N,T},
    _cfg,
    _ctx,
    ::R,
) where {F,MC,N,T,R}
    _m = type2model(MC)
    M = getmodule(_m)

    argsT = argvalstype(MC)
    obsT = obstype(MC)
    parsT = NamedTuple{N,T}

    body = _m.body |> loadvals(argsT, obsT, parsT)

    f = MeasureBase.instance(F)
    _retfun = MeasureBase.instance(R)
    body = make_body(M, f, body, _retfun, argsT, obsT, parsT)

    q = MacroTools.flatten(
        @q @inline function (_mc, _cfg, _ctx, _pars, _retfun)
            local _retn
            _args = $argvals(_mc)
            _obs = $observations(_mc)
            _cfg = merge(_cfg, (args = _args, obs = _obs, pars = _pars))
            $body
            # If body doesn't have a return, default to `return ctx`
            return $_retfun(_ctx, _ctx)
        end
    )

    q = from_type(_get_gg_func_body(mk_function(M, q))) |> MacroTools.flatten

    pushfirst!(q.args, :($(Expr(:meta, :inline))))

    q
end
