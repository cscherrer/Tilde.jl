using MLStyle

"""
    callify(mycall, ast)

Replace every `f(args...; kwargs..)` with `mycall(f, args...; kwargs...)` 
"""
function callify(mycall, ast)
    leaf(x) = x
    function branch(f, head, args)
        default() = Expr(head, map(f, args)...)
        head == :call || return default()

        if first(args) == :~ && length(args) == 3
            return default()
        end

        # At this point we know it's a function call
        length(args) == 1 && return Expr(:call, mycall, first(args))

        fun = args[1]
        arg2 = args[2]

        if arg2 isa Expr && arg2.head == :parameters
            # keyword arguments (try dump(:(f(x,y;a=1, b=2))) to see this)
            return Expr(:call, mycall, arg2, fun, map(f, Base.rest(args, 3))...)
        else
            return Expr(:call, mycall, map(f, args)...)
        end
    end

    foldast(leaf, branch)(ast)
end

# struct Provenance{T,S}
#     value::T
#     sources::S
# end

# getvalue(p::Provenance) = p.value
# getvalue(x) = x

# getsources(p::Provenance) = p.sources
# getsources(x) = Set()

# function trace_provenance(f, args...; kwargs...)
#     (newargs, arg_sources) = (getvalue.(args), union(getsources.(args)...))

#     k = keys(kwargs)
#     v = values(kwargs)
#     newkwargs = NamedTuple{k}(map(getvalue, v))

#     k = keys(kwargs)
#     v = values(NamedTuple(kwargs))
#     newkwargs = NamedTuple{k}(getvalue.(v))
#     kwarg_sources = union(getsources.(args)...)

#     sources = union(arg_sources, kwarg_sources)
#     Provenance(f(newargs...; newkwargs), sources)
# end

# macro call(expr)
#     callify(expr)
# end

# julia> callify(:(f(g(x,y))))
# :(call(f, call(g, x, y)))

# julia> callify(:(f(x; a=3)))
# :(call(f, x; a = 3))

# julia> callify(:(a+b))
# :(call(+, a, b))

# julia> callify(:(call(f,3)))
# :(call(f, 3))

# f(x) = x+1

# @call f(2)

# using SymbolicUtils

# @syms x::Vector{Float64} i::Int

# @call getindex(x,i)
