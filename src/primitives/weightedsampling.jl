using Random: GLOBAL_RNG

export weightedrand

@inline function weightedrand(m::AbstractConditionalModel; ctx=NamedTuple())
    return weightedrand(GLOBAL_RNG, m; ctx=ctx)
end


@inline function weightedrand(rng::AbstractRNG, m::AbstractConditionalModel; ctx=NamedTuple())
    cfg = (rng=rng,)
    ctx = (ℓ = 0.0, pars=ctx)
    gg_call(m, weightedrand, cfg, ctx, DropReturn())
end

@inline function tilde(::typeof(weightedrand), lens::typeof(identity), xname, x, d, cfg, ctx::NamedTuple, _, ::True)
    xname = dynamic(xname)
    xobs = getproperty(cfg.obs, xname)
    Δℓ = logdensity_def(d, xobs)
    @reset ctx.ℓ += Δℓ
    (xobs, ctx, ctx)
end


@inline function tilde(::typeof(weightedrand), lens::typeof(identity), xname, x, d, cfg, ctx::NamedTuple, _, ::False)
    xname = dynamic(xname)
    xnew = rand(cfg.rng, d)
    @reset ctx.pars = merge(ctx.pars, NamedTuple{(xname,)}(xnew))
    (xnew, ctx, ctx)
end

@inline function tilde(::typeof(weightedrand), lens, xname, x, d, cfg, ctx::NamedTuple, _, ::True)
    xname = dynamic(xname)
    xobs = getproperty(cfg.obs, xname)

    if ismissing(lens(xobs))
        xnew = set(x, Lens!!(lens), rand(cfg.rng, d))
        pars = merge(ctx.pars, NamedTuple{(xname,)}((xnew,)))
        ctx = merge(ctx, (pars=pars,))
    else
        xnew = xobs
        Δℓ = logdensity_def(d, lens(xnew))
        @reset ctx.ℓ += Δℓ
    end
    (xnew, ctx, ctx)
end


@inline function tilde(::typeof(weightedrand), lens, xname, x, d, cfg, ctx::NamedTuple, _, ::False)
    xname = dynamic(xname)
    xnew = set(x, Lens!!(lens), rand(cfg.rng, d))
    pars = merge(ctx.pars, NamedTuple{(xname,)}((xnew,)))
    ctx = merge(ctx, (pars=pars,))    
    (xnew, ctx, ctx)
end

