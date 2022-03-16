using GeneralizedGenerated
using TupleVectors: chainvec

export testparams
EmptyNTtype = NamedTuple{(),Tuple{}} where T<:Tuple

testparams(d::AbstractMeasure) = testvalue(d)

@inline function testparams(c::ModelClosure)
    m =model(c)
    return _testparams(getmoduletypencoding(m), m, argvals(c))
end

@inline function testparams(m::ModelClosure; kwargs...) 
    testparams(m; kwargs...)
end

@inline function testparams(mc::ModelClosure; cfg = NamedTuple(), ctx=NamedTuple())
    gg_call(mc, testparams, cfg, ctx, DropReturn())
end

###############################################################################
# ctx::NamedTuple

@inline function tilde(::typeof(testparams), lens::typeof(identity), xname, x, d, cfg, ctx::NamedTuple)
    xnew = testparams(d)
    ctx′ = merge(ctx, NamedTuple{(xname,)}((xnew,)))
    (xnew, ctx′, ctx′)
end

@inline function tilde(::typeof(testparams), lens, xname, x, d, cfg, ctx::NamedTuple)
    xnew = set(x, Lens!!(lens), testparams(d))
    ctx′ = merge(ctx, NamedTuple{(xname,)}((xnew,)))
    (xnew, ctx′, ctx′)
end
