using Random: GLOBAL_RNG

export measures


@inline function measures(m::AbstractConditionalModel, pars; ctx=NamedTuple())
    cfg = (pars=pars,)
    gg_call(m, measures, cfg, ctx, DropReturn())
end

@inline function tilde(::typeof(measures), lens, xname, x, d, cfg, ctx::NamedTuple, _, _)
    xname = dynamic(xname)
    x = get(cfg.pars, xname, get(cfg.obs, xname, missing))
    ctx = merge(ctx, NamedTuple{(xname,)}((d,)))
    (x, ctx, ctx)
end

