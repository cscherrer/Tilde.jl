using TupleVectors: chainvec

export testparams
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

testparams(d::AbstractMeasure) = testvalue(d)

@inline function testparams(mc::ModelClosure; cfg = NamedTuple(), ctx = NamedTuple())
    gg_call(testparams, mc, NamedTuple(), cfg, ctx, (r, ctx) -> ctx)
end

###############################################################################
# ctx::NamedTuple

@inline function tilde(
    ::typeof(testparams),
    lens::typeof(identity),
    xname,
    x,
    d,
    cfg,
    ctx::NamedTuple,
    _,
    _,
)
    xnew = testparams(d)
    ctx′ = merge(ctx, NamedTuple{(dynamic(xname),)}((xnew,)))
    (xnew, ctx′, ctx′)
end

@inline function tilde(::typeof(testparams), lens, xname, x, d, cfg, ctx::NamedTuple, _, _)
    xnew = set(x, Lens!!(lens), testparams(d))
    ctx′ = merge(ctx, NamedTuple{(dynamic(xname),)}((xnew,)))
    (xnew, ctx′, ctx′)
end
