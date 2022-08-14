using MLStyle

"""
    callify(mycall, ast)

Replace every `f(args...; kwargs..)` with `mycall(f, args...; kwargs...)` 
"""
function callify(g, ast)
    leaf(x) = x
    function branch(f, head, args)
        default() = Expr(head, map(f, args)...)

        # Convert `for` to `while`
        if head == :for
            arg1 = args[1]
            @assert arg1.head == :(=)
            a, A0 = arg1.args
            A0 = callify(g, A0)
            @gensym temp
            @gensym state
            @gensym A
            return quote
                $A = $A0
                $temp = $call($g, iterate, $A)
                while $temp !== nothing
                    $a, $state = $temp
                    $(args[2])
                    $temp = $call($g, iterate, $A, $state)
                end
            end
        end

        head == :call || return default()

        if first(args) == :~ && length(args) == 3
            return default()
        end

        # At this point we know it's a function call
        length(args) == 1 && return Expr(:call, call, g, first(args))

        fun = args[1]
        arg2 = args[2]

        if arg2 isa Expr && arg2.head == :parameters
            # keyword arguments (try dump(:(f(x,y;a=1, b=2))) to see this)
            return Expr(:call, call, g, arg2, fun, map(f, Base.rest(args, 3))...)
        else
            return Expr(:call, call, g, map(f, args)...)
        end
    end

    foldast(leaf, branch)(ast) |> MacroTools.flatten
end
