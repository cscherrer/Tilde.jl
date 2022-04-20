export lenses


@inline function lenses(m::AbstractConditionalModel, pars; ctx=NamedTuple())
    gg_call(lenses, m, pars, NamedTuple(), ctx, (r, ctx) -> ctx)
end

@inline function tilde(::typeof(lenses), lens, xname, x, d, cfg, ctx::NamedTuple{N}, _, _) where {N}
    xname = dynamic(xname)
    x = get(cfg.pars, xname, get(cfg.obs, xname, missing))
    if xname ∈ N
        @show xname
        @show lens
        push!(getproperty(ctx, xname), lens)
    else
        @show xname
        @show lens
        ctx = merge(ctx, NamedTuple{(xname,)}((Set((lens,)),)))
    end
    (x, ctx, ctx)
end

