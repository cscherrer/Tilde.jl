using Random: GLOBAL_RNG
using TupleVectors: chainvec

export rand
EmptyNTtype = NamedTuple{(),Tuple{}} where T<:Tuple

@inline function Base.rand(rng::AbstractRNG, d::ModelClosure, N::Int)
    r = chainvec(rand(rng, d), N)
    for j in 2:N
        @inbounds r[j] = rand(rng, d)
    end
    return r
end

@inline Base.rand(d::ModelClosure, N::Int) = rand(GLOBAL_RNG, d, N)

@inline function Base.rand(m::ModelClosure; kwargs...) 
    rand(GLOBAL_RNG, m; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure; ctx=NamedTuple(), retfun = (r, ctx) -> r)
    cfg = (rng=rng,)
    gg_call(rand, m, NamedTuple(), cfg, ctx, retfun)
end

###############################################################################
# ctx::NamedTuple
@inline function tilde(::typeof(Base.rand), lens, xname, x, d, cfg, ctx::NamedTuple)
    xnew = set(x.value, Lens!!(lens), rand(cfg.rng, d))
    ctx′ = merge(ctx, NamedTuple{(dynamic(xname),)}((xnew,)))
    (xnew, ctx′, nothing)
end



###############################################################################
# ctx::Dict

@inline function tilde(::typeof(Base.rand), lens::typeof(identity), xname, x, d, cfg, ctx::Dict)
    x = rand(cfg.rng, d)
    ctx[dynamic(xname)] = x 
    (x, ctx, nothing)
end

@inline function tilde(::typeof(Base.rand), lens, xname, x, m::ModelClosure, cfg, ctx::Dict)
    args = get(cfg.args, dynamic(xname), Dict())
    cfg = merge(cfg, (args = args,))
    tilde(rand, lens, xname, x, m(cfg.args), cfg, ctx)
end
