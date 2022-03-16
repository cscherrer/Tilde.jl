export interpret

function interpret(m::Model{A,B,M}, tilde, ctx0) where {A,B,M}
    theModule = getmodule(m)
    mk_function(theModule, make_body(theModule, m.body, tilde, ctx0))
end

function make_body(M, f, m::AbstractModel)
    make_body(M, body(m))
end

function make_body(M, f, ast::Expr, return_action)
    function go(ex, scope=(bounds = Var[], freevars = Var[], bound_inits = Symbol[]))
        @match ex begin
            :(($x, $l) ~ $rhs) => begin
                varnames = Tuple(locals(l)) # ∪ locals(rhs))
                varvals = Expr(:tuple, varnames...)

                x = unsolve(x)
                l = unsolve(l)
                # q = quote
                #     _vars = NamedTuple{$varnames}($varvals)
                #     # @show _vars
                # end

                # unsolved_lhs = unsolve(lhs)
                # x == unsolved_lhs && delete!(varnames, x)

                sx = static(x)
                # X = to_type(unsolved_lhs)
                M = to_type(unsolve(rhs))
            
                q = quote
                    __old_x = $l == identity ? nothing : $x
                    ($x, _ctx, _retn) = $tilde($f, $l, $sx, __old_x, $rhs, _cfg, _ctx)
                    _retn isa Tilde.ReturnNow && return _retn.value
                end

                q
            end

            Expr(:scoped, new_scope, ex) => begin
                go(ex, new_scope)
            end

            Expr(head, args...) => Expr(head, map(Base.Fix2(go, scope), args)...)
            
            x => x
        end
    end

    if return_action isa DropReturn
        ast = drop_return(ast)
    end

    body = go(@q begin 
            $(solve_scope(opticize(ast)))
    end) |> unsolve |> MacroTools.flatten

    body
end


function _get_gg_func_body(::RuntimeFn{Args,Kwargs,Body}) where {Args,Kwargs,Body}
    Body
end

function _get_gg_func_body(ex)
    error(ex)
end


struct DropReturn end
struct KeepReturn end



@generated function gg_call(_mc::MC, ::F, _cfg, _ctx, R) where {MC, F}
    _m = type2model(MC)
    M = getmodule(_m)

    _args = argvalstype(MC)
    _obs = obstype(MC)

    body = _m.body |> loadvals(_args, _obs)

    f = MeasureBase.instance(F)
    return_action = MeasureBase.instance(R)
    body = make_body(M, f, body, return_action)

    q = MacroTools.flatten(@q function (_mc, _cfg, _ctx)
            local _retn
            _args = Tilde.argvals(_mc)
            _obs = Tilde.observations(_mc)
            _cfg = merge(_cfg, (args=_args, obs=_obs))
            $body
            _retn
        end)

    from_type(_get_gg_func_body(mk_function(M, q)))
end
