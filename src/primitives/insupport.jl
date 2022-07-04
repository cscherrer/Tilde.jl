import MeasureBase: insupport
export insupport

@inline function insupport(m::AbstractConditionalModel, x::NamedTuple)
    mapreduce(insupport, (a, b) -> a && b, measures!(m, x), x)
end
