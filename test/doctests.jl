using Documenter
using Random
using Tilde
using StableRNGs

DocMeta.setdocmeta!(Tilde, :DocTestSetup, quote
    using Random
    using Tilde
    using StableRNGs
    using MeasureTheory
    Random.seed!(3)
end; recursive = true)

@testset "Doctests" begin
    doctest(Tilde)
end
