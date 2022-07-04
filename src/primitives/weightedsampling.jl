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
    gg_call(weightedrand, m, NamedTuple(), cfg, ctx, (r, ctx) -> ctx)
end

@inline function tilde(
    ::typeof(weightedrand),
    lens,
    xname,
    x::Observed,
    d,
    cfg,
    ctx::NamedTuple,
)
    x = x.value
    xname = dynamic(xname)
    Δℓ = logdensityof(d, lens(x))
    @reset ctx.ℓ += Δℓ
    (x, ctx, ctx)
end

@inline function tilde(
    ::typeof(weightedrand),
    lens,
    xname,
    x::Unobserved,
    d,
    cfg,
    ctx::NamedTuple,
)
    xnew = set(x.value, Lens!!(lens), rand(cfg.rng, d))
    pars = merge(ctx.pars, NamedTuple{(dynamic(xname),)}((xnew,)))
    ctx = merge(ctx, (pars = pars,))
    (xnew, ctx, nothing)
end
