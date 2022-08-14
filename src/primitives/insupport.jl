import MeasureBase: insupport
export insupport

struct InsupportConfig <: AbstractConfig end

@inline retfun(cfg::InsupportConfig, r, ctx) = ctx.insupport

@inline function insupport(
    cm::AbstractConditionalModel{M,A,O},
    pars::NamedTuple{N,T};
) where {M,A,O,N,T}
    cfg = InsupportConfig()
    runmodel(cfg, cm, pars, (insupport=true,))
end

@inline function tilde(
    cfg::InsupportConfig,
    z_obs::MaybeObserved{Z},
    lens,
    d,
    ctx::NamedTuple,
) where {Z}
    z = value(z_obs)
    zj = lens(z)
    # insupport(d, lens(x)) || return (x, ReturnNow(-Inf))
    xj = predict(FixedRNG(), d, zj)
    @reset ctx.insupport = ctx.insupport && insupport(d, zj)
    (xj, ctx)
end
