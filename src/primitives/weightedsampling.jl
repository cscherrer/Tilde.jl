using Random: GLOBAL_RNG

export weightedrand

@inline function weightedrand(m::AbstractConditionalModel; ctx = NamedTuple())
    return weightedrand(GLOBAL_RNG, m; ctx = ctx)
end

@inline function weightedrand(
    rng::AbstractRNG,
    m::AbstractConditionalModel;
    ctx = NamedTuple(),
)
    cfg = (rng = rng,)
    ctx = (ℓ = 0.0, pars = NamedTuple())
    runmodel(weightedrand, m, NamedTuple(), cfg, ctx, (r, ctx) -> ctx)
end

@inline function tilde(
    ::typeof(weightedrand),
    x::Observed{X},
    lens,
    d,
    cfg,
    ctx::NamedTuple,
) where {X}
    x = value(x)
    Δℓ = logdensityof(d, lens(x))
    @reset ctx.ℓ += Δℓ
    (x, ctx)
end

@inline function tilde(
    ::typeof(weightedrand),
    x::Unobserved{X},
    lens,
    d,
    cfg,
    ctx::NamedTuple,
) where {X}
    xnew = set(value(x), Lens!!(lens), rand(cfg.rng, d))
    pars = merge(ctx.pars, NamedTuple{(X,)}((xnew,)))
    ctx = merge(ctx, (pars = pars,))
    (xnew, ctx)
end
