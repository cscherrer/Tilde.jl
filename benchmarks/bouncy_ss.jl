using Tilde
using ProgressMeter
using LinearAlgebra
using Revise
using Optim

using ZigZagBoomerang
const ZZB = ZigZagBoomerang
using LinearAlgebra
using DelimitedFiles
using Random
using ForwardDiff
using ForwardDiff: Dual
using ZigZagBoomerang.PDMats
using MappedArrays
struct LazyRand{T,R}
    sampler::T
    n::Int
    rng::R
end

function Base.iterate(iter::LazyRand)
    iter.n > 0 ? (rand(iter.rng, iter.sampler), iter.n - 1) : nothing
end
Base.iterate(iter::LazyRand, n) = n > 0 ? (rand(iter.rng, iter.sampler), n - 1) : nothing
lazyrand(rng, r::UnitRange, n) = LazyRand(Random.SamplerRangeNDL(r), n, rng)
lazyrand(r::UnitRange, n) = LazyRand(Random.SamplerRangeNDL(r), n, Random.GLOBAL_RNG)
Base.length(iter::LazyRand) = iter.n
N = 100000 # no. observations
C = 400 # no. covariates
Random.seed!(1)
A = rand(1:C, N) # covariates selected at random

# The model we are interested in
full_model = @model N1, C, A, y begin
    α ~ Normal()
    cc ~ Normal()^C
    for i in 1:N1
        v = α + cc[A[i]]
        y[i] ~ Bernoulli(logitp = v)
    end
end

# This is an model which gives unbiased gradient estimates of the full model
# by subsampling using MeasureTheory's `PowerWeightedMeasure`
ss_model = @model N1, C, A, K, seed, y begin
    # same prior
    α ~ Normal()
    cc ~ Normal()^C
    # but random subset of observations
    for i in lazyrand(ZZB.Rng(seed), 1:N1, K)
        v = α + cc[A[i]]
        y[i] ~ Bernoulli(logitp = v)↑(N / K) # increase weight by power (N/K) 
    end
end

¦(a, b) = Tilde.:|(a, b)

# Helper function to make stochastic gradient and directional first and second derivatives
# The sampler will run in the transformed parameter space
function make_grads(full_model, ss_model, N1, C, A, MAP, ∇MAP, K, y)
    post = full_model(N1, C, A, y) ¦ (; y)
    as_post = as(post) # get transform from the full model
    post1(seed) = ss_model(N1, C, A, K, seed, y) ¦ (; y)
    obj(θ, seed) = -unsafe_logdensityof(post1(seed), transform(as_post, θ))

    @inline function dneglogp(t, x, v) # two directional derivatives
        seed = hash(t)
        f(t) = obj(x + t * v, seed) - obj(MAP + t * v, seed) # obj(MAP + t*v, seed) as control variate
        u = ForwardDiff.derivative(f, Dual{:hSrkahPmmC}(0.0, 1.0)) # use forwarddiff for this
        u.value - dot(∇MAP, v), u.partials[] # substract dot(∇MAP, v) for the control (should be zero for the MAP)
    end
    y2 = copy(MAP)
    function ∇neglogp!(y, t, x) # stochastic gradient with control variate
        seed = hash(t)
        f(x) = obj(x, seed)
        ForwardDiff.gradient!(y, f, x) # could also try reverse diff
        ForwardDiff.gradient!(y2, f, MAP) # control variate
        y .-= y2 .- ∇MAP # substract debiased control
        return
    end
    dneglogp, ∇neglogp!
end

# Generate data from model
y = zeros(Int, N)
Random.seed!(1)
data = rand(full_model(N, C, A, y)) # generated data
post = full_model(N, C, A, y) ¦ (; y)
as_post = as(post)
d = C + 1 # number of parameters 

# Find MAP
obj(θ) = -logdensityof(post, transform(as_post, θ))
#∇obj!(y, θ) = ReverseDiff.gradient!(y, obj, θ) # could also try
∇obj!(y, θ) = ForwardDiff.gradient!(y, obj, θ)
@time opt_result = optimize(obj, ∇obj!, zeros(d), ConjugateGradient())
MAP = opt_result.minimizer
∇MAP = zeros(d)
∇obj!(∇MAP, MAP)

# Sample
K = 500 # number of observations sampled for stochastic gradient
dneglogp, ∇neglogp! = make_grads(full_model, ss_model, N, C, A, MAP, ∇MAP, K, data.y)

t0 = 0.0;
n = 1000 # no of samples we want
c = 10.0 # initial guess for the bound

if norm(∇MAP) > 1e-4 # warn if not really a MAP (but valid anyway because we substract bias)
    @warn "norm(∇MAP) = $(norm(∇MAP))"
end

x0 = copy(MAP)
# Use diagonal mass matrix (with guesstimate of posterior variance from CLT)
M = PDMats.PDiagMat([i == 1 ? 9 / N : 4 * (C / N) for i in 1:d])
v0 = PDMats.unwhiten(M, normalize!(randn(length(x0))));

# define BouncyParticle sampler (has two relevant parameters) 
Z = BouncyParticle(
    missing, # graphical structure 
    MAP, # MAP estimate, unused
    1.0, # momentum refreshment rate and sample saving rate 
    0.9, # momentum correlation / only gradually change momentum in refreshment/momentum update
    M, # metric (PDMat compatible object for momentum covariance)
    missing, # legacy
);

sampler = ZZB.NotFactSampler(
    Z,
    (dneglogp, ∇neglogp!),
    ZZB.LocalBound(c),
    t0 => (x0, v0),
    ZZB.Rng(ZZB.Seed()),
    (),
    (;
        adapt = true, # adapt bound c
        subsample = true, # keep only samples at refreshment times
    ),
);

using TupleVectors: chainvec
using Tilde.MeasureTheory: transform

# ZigZag provides a iterative interface, this function collects n samples transformed back to the parameter space
function collect_sampler(t, sampler, n; progress = true, progress_stops = 20)
    if progress
        prg = Progress(progress_stops, 1)
    else
        prg = missing
    end
    stops = ismissing(prg) ? 0 : max(prg.n - 1, 0) # allow one stop for cleanup
    nstop = n / stops

    x1 = transform(t, sampler.u0[2][1])
    tv = chainvec(x1, n)
    ϕ = iterate(sampler)
    j = 1
    local state
    while ϕ !== nothing && j < n
        j += 1
        val, state = ϕ
        tv[j] = transform(t, val[2])
        ϕ = iterate(sampler, state)
        if j > nstop
            nstop += n / stops
            next!(prg)
        end
    end
    ismissing(prg) || ProgressMeter.finish!(prg)
    tv, (; uT = state[1], acc = state[3][1], total = state[3][2], bound = state[4].c)
end
#collect_sampler(as(post), sampler, 10; progress=false); # warmup

elapsed_time = @elapsed @time begin
    global bps_samples, info2
    bps_samples2, info2 =
        collect_sampler(as(post), sampler, n; progress = true, progress_stops = 500)
end

using MCMCChains
bps_chain2 = MCMCChains.Chains([bps_samples2.α bps_samples2.cc.data'])
bps_chain2 = setinfo(bps_chain2, (; start_time = 0.0, stop_time = elapsed_time));
ess_bps2 = MCMCChains.ess_rhat(bps_chain2).nt.ess_per_sec;

μ̂2 = round.(mean(bps_chain2).nt[:mean], sigdigits = 4)
ŝ2 = round.(vec(std([bps_samples2.α bps_samples2.cc.data'], dims = 1)), sigdigits = 4)
println("μ̂ (BPS-SS) = ", μ̂2)

@show info2.bound
@show round(info2.acc / info2.total, sigdigits = 2)

bps_chain2
