using Random: GLOBAL_RNG
using TupleVectors: chainvec

export rand
EmptyNTtype = NamedTuple{(),Tuple{}} where T<:Tuple

@inline function Base.rand(m::ModelClosure, args...; kwargs...) 
    rand(GLOBAL_RNG, Float64, m, args...; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure, args...; kwargs...) 
    rand(rng, Float64, m, args...; kwargs...)
end

@inline function Base.rand(::Type{T_rng}, m::ModelClosure, args...; kwargs...) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m, args...; kwargs...)
end

@inline function Base.rand(m::ModelClosure, d::Integer, dims::Integer...; kwargs...) 
    rand(GLOBAL_RNG, Float64, m, d, dims...; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure, d::Integer, dims::Integer...; kwargs...) 
    rand(rng, Float64, m, d, dims...; kwargs...)
end

@inline function Base.rand(::Type{T_rng}, m::ModelClosure, d::Integer, dims::Integer...; kwargs...) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m, d, dims...; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, ::Type{T_rng}, d::ModelClosure, N::Integer, v::Vararg{Integer}) where {T_rng}
    @assert isempty(v)
    r = chainvec(rand(rng, T_rng, d), N)
    for j in 2:N
        @inbounds r[j] = rand(rng, T_rng, d)
    end
    return r
end

@inline Base.rand(d::ModelClosure, N::Int) = rand(GLOBAL_RNG, d, N)

@inline function Base.rand(m::ModelClosure; kwargs...) 
    rand(GLOBAL_RNG, m; kwargs...)
end

@inline Base.rand(rng::AbstractRNG, m::ModelClosure) = rand(rng, Float64, m)

@inline function Base.rand(rng::AbstractRNG, ::Type{T_rng}, m::ModelClosure; ctx=NamedTuple(), retfun = (r, ctx) -> r) where {T_rng}
    cfg = (rng=rng, T_rng=T_rng)
    gg_call(rand, m, NamedTuple(), cfg, ctx, retfun)
end

###############################################################################
# ctx::NamedTuple
@inline function tilde(::typeof(Base.rand), x::Unobserved{X}, lens, d, cfg, ctx::NamedTuple) where {X}
    xnew = set(value(x), Lens!!(lens), rand(cfg.rng, d))
    ctx′ = merge(ctx, NamedTuple{(X,)}((xnew,)))
    (xnew, ctx′, nothing)
end

@inline function tilde(::typeof(Base.rand), x::Observed{X}, lens, d, cfg, ctx::NamedTuple) where {X}
    (value(x), ctx, nothing)
end
