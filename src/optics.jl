using Accessors
using Accessors: IndexLens, PropertyLens, ComposedOptic

struct Lens!!{L}
    pure::L
end

function Base.show(io::IO, l::Lens!!)
    print(io, "Lens!!", l.pure)
end

(l::Lens!!)(o) = l.pure(o)

@inline function Accessors.set(o, l::Lens!!{<: ComposedOptic}, val)
    set(o, Lens!!(l.pure.outer) ∘ Lens!!(l.pure.inner), val)
end

@inline function Accessors.set(o, l::Lens!!{PropertyLens{prop}}, val) where {prop}
    if ismutable(o)
        setproperty!(o, prop, val)
    else
        setproperties(o, NamedTuple{(prop,)}((val,)))
    end
end

using Tricks

@inline function Accessors.set(o::O, l::Lens!!{typeof(identity)}, val::V) where {O,V}
    if ismutable(o) && static_hasmethod(iterate, Tuple{O}) && static_hasmethod(iterate, Tuple{V})
        o .= val
    else
        val 
    end
end

@inline function Accessors.set(o, l::Lens!!{<:IndexLens}, val)
    if ismutable(o)
        _setindex!(o, val, l)
    else
        Base.setindex(o, val, l.pure.indices...)
    end
end

@inline function _setindex!(o::AbstractArray{T}, val::T, l::Lens!!{<:IndexLens}) where {T}
    setindex!(o, val, l.pure.indices...)
end

# Attempting to set a value outside the current eltype widens the eltype
@inline function _setindex!(o::AbstractArray{T}, val::V, l::Lens!!{<:IndexLens}) where {T,V}
    new_o = similar(o, Union{T,V})
    new_o .= o
    setindex!(new_o, val, l.pure.indices...)
end

@inline function Accessors.modify(f, o, l::Lens!!)
    set(o, l, f(l(o)))
end

@inline function Accessors.modify(f, o, l::Lens!!{<:ComposedOptic})
    o_inner = l.pure.inner(o)
    modify(f, o_inner, Lens!!(l.pure.outer))
end

using Accessors: setmacro, opticmacro, modifymacro

macro set!!(ex)
    setmacro(Lens!!, ex; overwrite=true)
end

macro optic!!(ex)
    opticmacro(Lens!!, ex)
end

macro modify!!(f, ex)
    modifymacro(Lens!!, f, ex)
end

###############################################################################

function unescape(ast)
    leaf(x) = x
    @inline function branch(f, head, args)
        default() = Expr(head, map(f, args)...)
        
        head == :escape ? f(args[1]) : default()
    end
    foldast(leaf, branch)(ast)
end

function opticize(ast)
    leaf(x) = x
    @inline function branch(f, head, args)
        default() = Expr(head, map(f, args)...)
        head == :call || return default()
        first(args) == :~ || return default()
        length(args) == 3 || return default()

        # If we get here, we know we're working with something like `lhs ~ rhs`
        lhs = args[2]
        rhs = args[3]
        
        lhs′ = @match lhs begin
            :(($(x::Symbol), $o)) => :(($x, $o))
            :(($(x::Var), $o)) => :(($x, $o))
            _ => begin
                (x, o) = parse_optic(lhs)
                :(($x, $o))
            end
        end
        rhs′ = f(rhs)
        :($lhs′ ~ $rhs′)
    end

    foldast(leaf, branch)(ast)
end