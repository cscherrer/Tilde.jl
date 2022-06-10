import Pkg
#Pkg.activate("benchmarks")
using Tilde
using LinearAlgebra
using Revise
using ZigZagBoomerang
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
    fname = joinpath("lr.data")
    z = readdlm(fname)
    A = z[:,1:end-1]
    A = [ones(size(A,1)) A]
    y = z[:,end] .- 1
    return A, y
end
A, y = readlrdata()

At = collect(A')

model = @model (At, y, σ) begin
    d,n = size(At)
    θ ~ Normal(σ=σ)^d
    for j in 1:n
        logitp = dot(view(At,:,j), θ)
        y[j] ~ Bernoulli(logitp = logitp)
    end
end

σ = 100.0

post = model(At, y, σ) | (;y)

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


d = 25 # number of parameters 
t0 = 0.0
x0 = zeros(d) # starting point sampler
# estimated posterior mean
xhat = [3.412, -0.5916, 0.03527, -0.3873, 0.004466, -0.2345, -0.15, -0.2164, 0.01229, 0.1739, -0.009764, -0.3217, 0.2173, 0.08189, -0.2851, -1.59, 0.6661, -1.003, 1.078, 1.401, 0.3271, -0.1361, -0.6437, -0.06795, -0.05282]

T = 5000. # end time (similar to number of samples in MCMC)
c = 0.01 # initial guess for the bound
using Pathfinder
init_scale=1
@time result = pathfinder(ℓ; dim=d, init_scale)
M = Diagonal(1 ./ sqrt.(diag(result.fit_distribution.Σ)))
x0 = result.fit_distribution.μ
θ0 = M\randn(d) # starting direction sampler
MAP = result.optim_solution # MAP, could be useful for control variates

# define BouncyParticle sampler (has two relevant parameters) 
Z = BouncyParticle(∅, ∅, # ignored
    2.0, # momentum refreshment rate 
    0.95, # momentum correlation / only gradually change momentum in refreshment/momentum update
    0.0, # ignored
    M # cholesky of momentum precision
) 

sampler = ZZB.NotFactSampler(Z, (dneglogp, ∇neglogp!), ZZB.LocalBound(c), t0 => (x0, θ0), ZZB.Rng(ZZB.Seed()), (),
(; adapt=true, # adapt bound c
      subsample=true, # keep only samples at refreshment times
))


using TupleVectors: chainvec
using MeasureTheory: transform


function collect_sampler(t, sampler, n)
    x1 = transform(t, sampler.u0[2][1])
    tv = chainvec(x1, n)
    ϕ = iterate(sampler)
    j = 1
    global state
    while ϕ !== nothing && j < n
        j += 1
        val, state = ϕ
        tv[j] = transform(t, val[2])
        ϕ = iterate(sampler, state)
    end
    tv
end
tv = @time collect_sampler(as(post), sampler, 1000)

using MCMCChains
bps_chain = MCMCChains.Chains(tv.θ)
bps_chain = setinfo(bps_chain,  (;start_time=0.0, stop_time = elapsed_time))
bps_chain

