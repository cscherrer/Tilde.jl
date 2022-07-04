import MeasureBase: basemeasure

@inline function basemeasure(m::AbstractConditionalModel, pars; ctx = NamedTuple())
    gg_call(basemeasure, m, pars, NamedTuple(), ctx, (r, ctx) -> ctx)
end

@inline function tilde(
    ::typeof(basemeasure),
    x::MaybeObserved{X},
    lens,
    d,
    cfg,
    ctx::NamedTuple
) where {X}
    xparent = getproperty(cfg.obs, X)
    x = lens(xparent)
    b = basemeasure(d, x)
    ctx = merge(ctx, NamedTuple{(X,)}((b,)))
    (x, ctx, productmeasure(ctx))
end
