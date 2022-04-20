using Random: GLOBAL_RNG

export weightedrand

@inline function weightedrand(m::AbstractConditionalModel; ctx=NamedTuple())
    return weightedrand(GLOBAL_RNG, m; ctx=ctx)
end


@inline function weightedrand(rng::AbstractRNG, m::AbstractConditionalModel; ctx=NamedTuple())
    cfg = (rng=rng,)
    ctx = (ℓ = 0.0, pars=NamedTuple())
    gg_call(weightedrand, m, NamedTuple(), cfg, ctx, (r, ctx) -> ctx)
end

@inline function tilde(::typeof(weightedrand), lens, xname, x, d, cfg, ctx::NamedTuple)
    xname = dynamic(xname)
    Δℓ = logdensityof(d, x)
    @reset ctx.ℓ += Δℓ
    (x, ctx, ctx)
end

@inline function tilde(::typeof(weightedrand), lens, xname, x::Missing, d, cfg, ctx::NamedTuple)
    x = rand(cfg.rng, d)
    ctx = set(ctx, PropertyLens{:pars}() ⨟ Lens!!(lens), x)
    (x, ctx, ctx)
end