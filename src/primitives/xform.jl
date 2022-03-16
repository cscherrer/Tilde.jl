using Reexport

using MLStyle
using NestedTuples
import NestedTuples
import MeasureTheory: testvalue

function NestedTuples.schema(::Type{TV.TransformTuple{T}}) where {T} 
    schema(T)
end

# In Bijectors.jl,
# logdensity_with_trans(dist, x, true) == logdensity_def(transformed(dist), link(dist, x))


export xform

xform(m::ModelClosure{M,A}, _data::NamedTuple) where {M,A} = xform(m | _data)

function xform(m::ModelPosterior{M,A,O}) where {M,A,O}
    return _xform(getmoduletypencoding(m), model(m), argvals(m), observations(m))
end


export sourceXform

using Distributions: support

@inline function xform(d, _data::NamedTuple)
    if hasmethod(support, (typeof(d),))
        return asTransform(support(d)) 
    end

    error("Not implemented:\nxform($d)")
end

using TransformVariables: ShiftedExp, ScaledShiftedLogistic, as

function asTransform(supp:: Dists.RealInterval) 
    (lb, ub) = (supp.lb, supp.ub)

    (lb, ub) == (-Inf, Inf) && (return asℝ)
    isinf(ub) && return ShiftedExp(true,lb)
    isinf(lb) && return ShiftedExp(false,lb)
    return ScaledShiftedLogistic(ub-lb, lb)
end

xform(d, _data) = nothing

xform(μ::AbstractMeasure,  _data::NamedTuple) = xform(μ)

xform(d::Dists.AbstractMvNormal, _data::NamedTuple=NamedTuple()) = as(Array, size(d))

function xform(d::Dists.Distribution{Dists.Univariate}, _data::NamedTuple=NamedTuple())
    sup = Dists.support(d)
    lo = isinf(sup.lb) ? -TV.∞ : sup.lb
    hi = isinf(sup.ub) ? TV.∞ : sup.ub
    as(Real, lo,hi)
end

function xform(d::Dists.Product, _data::NamedTuple=NamedTuple())
    n = length(d)
    v = d.v
    as(Vector, xform(v[1]), n)
end
