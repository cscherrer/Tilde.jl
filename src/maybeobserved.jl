abstract type MaybeObserved{N,T} end

struct Observed{N,T} <: MaybeObserved{N,T}
    value::T
end

struct Unobserved{N,T} <: MaybeObserved{N,T}
    value::T
end

NamedTuple(o::MaybeObserved{N,T}) where {N,T} = NamedTuple{(N,)}((o.value,))

Observed{N}(x::T) where {N,T} = Observed{N, T}(x)
Unobserved{N}(x::T) where {N,T} = Unobserved{N, T}(x)
