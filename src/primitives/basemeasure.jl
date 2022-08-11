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
    obj::Unobserved{X},
    lens,
    d,
    ctx,
) where {X}
    x = value(obj)
    xj = lens(x)
    b = basemeasure(d, xj)
    ctx = mymerge(ctx, NamedTuple{(X,)}((b,)))
    (x, ctx)
end

@inline function tilde(
    cfg::BasemeasureConfig,
    obj::Observed{X},
    lens,
    d,
    ctx,
) where {X}
    x = value(obj)
    (x, ctx)
end

function rproduct(nt::NamedTuple)
    productmeasure(map(rproduct, nt))
end

rproduct(m::AbstractMeasure) = m
