import MeasureBase: logdensity_rel

@inline function logdensity_rel(μ::AbstractConditionalModel, ν::AbstractConditionalModel, x)
    mapreduce(logdensity_rel, +, measures(μ, x), measures(ν, x), x)
end
