abstract type MaybeObserved{N,T} end

struct Observed{N,T} <: MaybeObserved{N,T}
    value::T
end

Observed{N}(x::T) where {N,T} = Observed{N,T}(x)

struct Unobserved{N,T} <: MaybeObserved{N,T}
    value::T
end

Unobserved{N}(x::T) where {N,T} = Unobserved{N,T}(x)
NamedTuple(o::MaybeObserved{N,T}) where {N,T} = NamedTuple{(N,)}((o.value,))

value(obj::MaybeObserved) = obj.value
