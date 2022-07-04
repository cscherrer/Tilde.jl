import MeasureBase: basemeasure

@inline function basemeasure(m::AbstractConditionalModel, pars; ctx = NamedTuple())
    gg_call(basemeasure, m, pars, NamedTuple(), ctx, (r, ctx) -> ctx)
end

@inline function tilde(
    ::typeof(basemeasure),
    lens,
    xname,
    x,
    d,
    cfg,
    ctx::NamedTuple,
    _,
    ::True,
)
    xname = dynamic(xname)
    xparent = getproperty(cfg.obs, xname)
    x = lens(xparent)
    b = basemeasure(d, x)
    ctx = merge(ctx, NamedTuple{(xname,)}((b,)))
    (x, ctx, productmeasure(ctx))
end

@inline function tilde(
    ::typeof(basemeasure),
    lens,
    xname,
    x,
    d,
    cfg,
    ctx::NamedTuple,
    _,
    ::False,
)
    xname = dynamic(xname)
    xparent = getproperty(cfg.pars, xname)
    x = getproperty(cfg.pars, xname)
    b = basemeasure(d, x)
    ctx = merge(ctx, NamedTuple{(xname,)}((b,)))
    (x, ctx, productmeasure(ctx))
end
