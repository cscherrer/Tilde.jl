using GeneralizedGenerated
using TupleVectors: chainvec
import MeasureTheory: testvalue

export testvalue
EmptyNTtype = NamedTuple{(),Tuple{}} where T<:Tuple

@inline function testvalue(mc::ModelClosure; cfg = NamedTuple(), ctx=NamedTuple())
    gg_call(mc, testvalue, cfg, ctx, KeepReturn())
end

###############################################################################
# ctx::NamedTuple

@inline function tilde(::typeof(testvalue), lens::typeof(identity), xname, x, d, cfg, ctx::NamedTuple, _, _)
    xnew = testvalue(d)
    ctx′ = merge(ctx, NamedTuple{(dynamic(xname),)}((xnew,)))
    (xnew, ctx′, ctx′)
end

@inline function tilde(::typeof(testvalue), lens, xname, x, d, cfg, ctx::NamedTuple, _, _)
    xnew = set(x, Lens!!(lens), testvalue(d))
    ctx′ = merge(ctx, NamedTuple{(dynamic(xname),)}((xnew,)))
    (xnew, ctx′, ctx′)
end
