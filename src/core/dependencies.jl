using JuliaVariables
using MLStyle
import MacroTools

unwrap_scoped(ex) = @match ex begin
    Expr(:scoped, _, a) => unwrap_scoped(a)
    Expr(head, args...) => Expr(head, map(unwrap_scoped, args)...)
    a => a
end

globals(s::Symbol) = [s]
globals(x) = []

function globals(ex::Expr)
    branch(head, newargs) = union(newargs...)

    function leaf(v::JuliaVariables.Var)
        v.is_global ? [v.name] : Symbol[]
    end

    leaf(x) = []

    solved_ex = unwrap_scoped(solve_from_local!(simplify_ex(ex)))

    return foldall(leaf, branch)(solved_ex)
end
