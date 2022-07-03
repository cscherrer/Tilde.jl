using Random: GLOBAL_RNG
using TupleVectors: chainvec

export rand
EmptyNTtype = NamedTuple{(),Tuple{}} where T<:Tuple

@inline function Base.rand(rng::AbstractRNG, d::AbstractConditionalModel, N::Int)
    r = chainvec(rand(rng, d), N)
    for j in 2:N
        @inbounds r[j] = rand(rng, d)
    end
    return r
end

@inline Base.rand(d::AbstractConditionalModel, N::Int) = rand(GLOBAL_RNG, d, N)

@inline function Base.rand(m::AbstractConditionalModel; kwargs...) 
    rand(GLOBAL_RNG, m; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::AbstractConditionalModel; ctx=NamedTuple(), retfun = (r, ctx) -> r)
    cfg = (rng=rng,)
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
