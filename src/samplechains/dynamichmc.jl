using .SampleChainsDynamicHMC
using Random

export sample

using ..Tilde

using .SampleChainsDynamicHMC: DynamicHMCConfig

function sample(
    rng::AbstractRNG,
    m::ModelClosure,
    config::DynamicHMCConfig,
    nsamples::Int = 1000,
    nchains::Int = 4,
)
    ℓ(x) = MeasureTheory.logdensityof(m, x)
    tr = as(m)

    chains = newchain(rng, nchains, config, ℓ, tr)
    sample!(chains, nsamples - 1)
    return chains
end

function sample(
    m::ModelClosure,
    config::DynamicHMCConfig,
    nsamples::Int = 1000,
    nchains::Int = 4,
)
    sample(Random.GLOBAL_RNG, m, config, nsamples, nchains)
end
