import MeasureBase: basemeasure

struct BasemeasureConfig end

retfun(::BasemeasureConfig, r, ctx) = ctx

@inline function basemeasure(m::AbstractConditionalModel, pars; ctx = NamedTuple())
    rproduct(runmodel(BasemeasureConfig(), m, pars, ctx))
end

@inline function basemeasure(m::AbstractConditionalModel; ctx = NamedTuple())
    basemeasure(m, _rand(FixedRNG(), m); ctx=ctx)
end

@inline function tilde(
    cfg::BasemeasureConfig,
    z_obs::Unobserved{Z},
    lens,
    d,
    ctx,
) where {Z}
    z = value(z_obs)
    zj = lens(z)
    b = basemeasure(d, zj)
    ctx = mymerge(ctx, NamedTuple{(Z,)}((b,)))
    xj = predict(FixedRNG(), d, zj)
    (xj, ctx)
end

@inline function tilde(
    cfg::BasemeasureConfig,
    z_obs::Observed{Z},
    lens,
    d,
    ctx,
) where {Z}
    z = value(z_obs)
    zj = lens(z)
    xj = predict(FixedRNG(), d, zj)
    (xj, ctx)
end

function rproduct(nt::NamedTuple)
    productmeasure(map(rproduct, nt))
end

rproduct(m::AbstractMeasure) = m
