using Tilde
import Pkg
Pkg.activate("benchmarks")
using LinearAlgebra
using Revise
using ZigZagBoomerang
using StatsFuns
const ZZB = ZigZagBoomerang
using LinearAlgebra
const ∅ = nothing
using DelimitedFiles
using Random
using ForwardDiff
using ForwardDiff: Dual
Random.seed!(1)

# read data
function readlrdata()
    fname = joinpath("/home/chad/git/Turing.jl/benchmarks/nuts/lr_nuts.data")
    z = readdlm(fname)
    x = z[:,1:end-1]
    x = [ones(size(x,1)) x]
    y = z[:,end] .- 1
    return x, y
end
x, y = readlrdata()

xt = collect(x')

m = @model (xt, y, σ) begin
    d,n = size(xt)
    θ ~ Normal(σ=σ)^d
    for j in 1:n
        logitp = dot(view(xt,:,j), θ)
        y[j] ~ Bernoulli(logitp = logitp)
    end
end

σ = 100.0

post = m(xt,y, σ) | (;y)

# using SampleChainsDynamicHMC

# Tilde.sample(post, dynamichmc(), 2,1)

# @time s = Tilde.sample(post, dynamichmc(), 1000, 1)

ℓ(θ) = logdensityof(post, (;θ))
obj(θ) = -ℓ(θ)

function dneglogp(t, x, v, args...) # two directional derivatives
    u = ForwardDiff.derivative(t -> obj(x + t*v), Dual{:hSrkahPmmC}(0.0, 1.0))
    u.value, u.partials[]
end

function ∇neglogp!(y, t, x, args...)
    ForwardDiff.gradient!(y, obj, x)
    y
end

# Try things out
# dneglogp(2.4, randn(25), randn(25))
# ∇neglogp!(randn(25), 2.1, randn(25))


d = 1 + 24 # number of parameters 
t0 = 0.0
x0 = zeros(d) # starting point sampler
T = 500. # end time (similar to number of samples in MCMC)
c = 5.0 # initial guess for the bound
#M = I
M = Diagonal(1 ./ [1.7, 0.08, 0.01, 0.09, 0.01, 0.06, 0.08, 0.12, 0.09, 0.11, 0.01, 0.11, 0.18, 0.29, 0.21, 0.88, 0.21, 0.39, 0.44, 0.65, 0.4, 0.35, 0.6, 0.31, 0.3])
θ0 = M\randn(d) # starting direction sampler

# define BouncyParticle sampler (has two relevant parameters) 
Z = BouncyParticle(∅, ∅, # ignored
    2.0, # momentum refreshment rate 
    0.95, # momentum correlation / only gradually change momentum in refreshment/momentum update
    0.0, # ignored
    M # cholesky of momentum precision
) 

sampler = ZZB.NotFactSampler(Z, (dneglogp, ∇neglogp!), ZZB.LocalBound(c), t0 => (x0, θ0), ZZB.Rng(ZZB.Seed()),
(), (;adapt=true, # adapt bound c
subsample=true, # keep only samples at refreshment times
))

# let
# ϕ = iterate(sampler)
# while ϕ !== nothing
#     val, state = ϕ
#     val[1]> 1 && break
#     println(val[1])
#     ϕ = iterate(sampler, state)
# end
# end

using TupleVectors: chainvec

function collect_sampler(t, sampler, n)
    x1 = transform(t, sampler.u0[2][1])
    tv = chainvec(x1, n)
    ϕ = iterate(sampler)
    j = 1
    while ϕ !== nothing && j < n
        j += 1
        val, state = ϕ
        tv[j] = transform(t, val[2])
        ϕ = iterate(sampler, state)
    end
    tv
end



tv = @time collect_sampler(as(post), sampler, 1000)

using OnlineStats



trace, final, (acc, num), cs = @time pdmp(
        dneglogp, # return first two directional derivatives of negative target log-likelihood in direction v
        ∇neglogp!, # return gradient of negative target log-likelihood
        t0, x0, θ0, T, # initial state and duration
        ZZB.LocalBound(c), # use Hessian information 
        Z; # sampler
        adapt=true, # adapt bound c
        progress=true, # show progress bar
        subsample=true # keep only samples at refreshment times
)


t, x = ZigZagBoomerang.sep(trace)

# tv = chainvec(transform(as(post), first(sampler)[2]))

# tvs = (push!(tv, transform(as(post), s[2])) for s in Iterators.drop(sampler,1));

# @time first(Iterators.drop(tvs,1000))

using TupleVectors: chainvec

using MeasureTheory: transform
function tuplevector(t, x::Vector{Vector{T}}) where {T}
    x1 = transform(t, x[2])
    tv = chainvec(x1, length(x))
    for j in 2:length(x)
        tv[j] = transform(t, x[j])
    end
    return tv
end

tv = tuplevector(as(post), x)



# bps_chain = MCMCChains.Chains([xj[i] for xj in x[end÷4:end], i in 1:d])
# bps_chain = setinfo(bps_chain,  (;start_time=0.0, stop_time = elapsed_time))
# bps_chain

# # for BPS
using Pathfinder
init_scale=1
@time result = pathfinder(ℓ; dim=d, init_scale)
# M = Diagonal(1 ./ sqrt.(diag(result.fit_distribution.Σ)))
# x0 = result.fit_distribution.μ
# θ0 = M\randn(d) # starting direction sampler