using GeneralizedGenerated
using TupleVectors: chainvec
import MeasureTheory: testvalue

export testvalue
EmptyNTtype = NamedTuple{(),Tuple{}} where T<:Tuple

@inline function testvalue(c::ModelClosure)
    m =model(c)
    return _testvalue(getmoduletypencoding(m), m, argvals(c))
end

function testvalue(d::ModelClosure, N::Int)
    r = chainvec(testvalue(d), N)
    for j in 2:N
        @inbounds r[j] = testvalue(d)
    end
    return r
end

@inline function testvalue(m::ModelClosure; kwargs...) 
    testvalue(m; kwargs...)
end

@inline function testvalue(mc::ModelClosure; cfg = NamedTuple(), ctx=NamedTuple())
    gg_call(mc, testvalue, cfg, ctx, KeepReturn())
end

###############################################################################
# ctx::NamedTuple

@inline function tilde(::typeof(testvalue), lens::typeof(identity), xname, x, d, cfg, ctx::NamedTuple)
    xnew = testvalue(d)
    ctx′ = merge(ctx, NamedTuple{(xname,)}((xnew,)))
    (xnew, ctx′, ctx′)
end

@inline function tilde(::typeof(testvalue), lens, xname, x, d, cfg, ctx::NamedTuple)
    xnew = set(x, Lens!!(lens), testvalue(d))
    ctx′ = merge(ctx, NamedTuple{(xname,)}((xnew,)))
    (xnew, ctx′, ctx′)
end
