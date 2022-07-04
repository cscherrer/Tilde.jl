module Tilde

import Base.rand
using Random
using Reexport: @reexport

@reexport using StatsFuns
@reexport using MeasureTheory
using MeasureBase: productmeasure, Returns

import DensityInterface: logdensityof
import DensityInterface: densityof
import DensityInterface: DensityKind
using DensityInterface

using NamedTupleTools
using SampleChains
# using SymbolicCodegen

# using SymbolicUtils: Symbolic
# const MaybeSym{T} = Union{T, Symbolic{T}}

# MeasureTheory.For(f, dims::MaybeSym{<: Integer}...) = ProductMeasure(mappedarray(i -> f(Tuple(i)...), CartesianIndices(dims))) 
# MeasureTheory.For(f, dims::MaybeSym{<: AbstractUnitRange}...) = ProductMeasure(mappedarray(i -> f(Tuple(i)...), CartesianIndices(dims))) 

import MacroTools: prewalk, postwalk, @q, striplines, replace, @capture
import MacroTools
import MLStyle
# import MonteCarloMeasurements
# using MonteCarloMeasurements: Particles, StaticParticles, AbstractParticles

using Requires
using ArrayInterface: StaticInt
using Static

using IfElse: ifelse
using TransformVariables: asℝ, as𝕀, asℝ₊
import TransformVariables as TV

using TupleVectors: unwrap

# using SimplePosets: SimplePoset
# import SimplePosets

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)
using MeasureBase: AbstractTransitionKernel

using NestedTuples: TypelevelExpr

using MeasureTheory: ∞
import MeasureTheory: as

include("GG/src/GeneralizedGenerated.jl")
using .GeneralizedGenerated
const GG = GeneralizedGenerated

"""
we use this to avoid introduce static type parameters
for generated functions
"""
_unwrap_type(a::Type{<:Type}) = a.parameters[1]

export model, Model, tilde, @model

using MLStyle
include("callify.jl")

@generated function MeasureTheory.For(
    f::GG.Closure{F,Free},
    inds::I,
) where {F,Free,I<:Tuple}
    freetypes = Free.types
    eltypes = eltype.(I.types)
    T = Core.Compiler.return_type(F, Tuple{freetypes...,eltypes...})
    quote
        $(Expr(:meta, :inline))
        For{$T,GG.Closure{F,Free},I}(f, inds)
    end
end

include("optics.jl")
include("maybe.jl")
include("core/models/abstractmodel.jl")
include("core/models/astmodel/astmodel.jl")
include("core/models/model.jl")
include("core/dependencies.jl")
include("core/utils.jl")
include("core/models/closure.jl")
include("core/models/posterior.jl")
include("primitives/interpret.jl")
include("distributions/iid.jl")

include("primitives/rand.jl")
include("primitives/logdensity.jl")
include("primitives/logdensity_rel.jl")
include("primitives/insupport.jl")

# include("primitives/basemeasure.jl")
include("primitives/testvalue.jl")
include("primitives/testparams.jl")
include("primitives/weightedsampling.jl")
include("primitives/measures.jl")
include("primitives/basemeasure.jl")

include("transforms/utils.jl")

function __init__()
    @require SampleChainsDynamicHMC = "6d9fd711-e8b2-4778-9c70-c1dfb499d4c4" begin
        include("inference/dynamichmc.jl")
    end
end

end # module
