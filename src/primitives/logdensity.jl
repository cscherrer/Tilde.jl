
export logdensityof

using NestedTuples: lazymerge
import MeasureTheory

using Accessors


@inline function MeasureBase.logdensityof(cm::AbstractConditionalModel, pars::NamedTuple; cfg=NamedTuple(), ctx=NamedTuple())
    # cfg = merge(cfg, (pars=pars,))
    ctx = merge(ctx, (ℓ = 0.0,))
    gg_call(logdensityof, cm, pars, cfg, ctx, DropReturn())
end

@inline function tilde(::typeof(logdensityof), lens, xname, x, d, cfg, ctx::NamedTuple)
    insupport(d, x) || return (x, ctx, ReturnNow(-Inf))
    @reset ctx.ℓ += MeasureBase.unsafe_logdensityof(d, lens(x))
    (x, ctx, ctx.ℓ)
end

@inline function MeasureBase.unsafe_logdensityof(cm::AbstractConditionalModel, pars::NamedTuple; cfg=NamedTuple(), ctx=NamedTuple())
    # cfg = merge(cfg, (pars=pars,))
    ctx = merge(ctx, (ℓ = 0.0,))
    gg_call(unsafe_logdensityof, cm, pars, cfg, ctx, DropReturn())
end

@inline function tilde(::typeof(unsafe_logdensityof), lens, xname, x, d, cfg, ctx::NamedTuple)
    
    @reset ctx.ℓ += MeasureBase.unsafe_logdensityof(d, lens(x))
    (x, ctx, ctx.ℓ)
end
