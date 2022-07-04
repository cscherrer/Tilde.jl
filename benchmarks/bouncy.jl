import Pkg
#Pkg.activate("benchmarks")
using Tilde
using ProgressMeter
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
using Pathfinder
using Pathfinder.PDMats

Random.seed!(1)

# read data
function readlrdata()
    fname = joinpath("lr.data")
    z = readdlm(fname)
    A = z[:, 1:end-1]
    A = [ones(size(A, 1)) A]
    y = z[:, end] .- 1
    return A, y
end
A, y = readlrdata();
At = collect(A');

model_lr = @model (At, y, σ) begin
    d, n = size(At)
    θ ~ Normal(σ = σ)^d
    for j in 1:n
        logitp = dot(view(At, :, j), θ)
        y[j] ~ Bernoulli(logitp = logitp)
    end
end
σ = 100.0

function make_grads(model_lr, At, y, σ)
    post = model_lr(At, y, σ) | (; y)
    as_post = as(post)
    obj(θ) = -Tilde.unsafe_logdensityof(post, transform(as_post, θ))
    ℓ(θ) = -obj(θ)
    @inline function dneglogp(t, x, v) # two directional derivatives
        f(t) = obj(x + t * v)
        u = ForwardDiff.derivative(f, Dual{:hSrkahPmmC}(0.0, 1.0))
        u.value, u.partials[]
    end

    gconfig = ForwardDiff.GradientConfig(obj, rand(25), ForwardDiff.Chunk{25}())
    function ∇neglogp!(y, t, x)
        ForwardDiff.gradient!(y, obj, x, gconfig)
        return
    end
    post, ℓ, dneglogp, ∇neglogp!
end

post, ℓ, dneglogp, ∇neglogp! = make_grads(model_lr, At, y, σ)
# Try things out
dneglogp(2.4, randn(25), randn(25));
∇neglogp!(randn(25), 2.1, randn(25));

d = 25 # number of parameters 
t0 = 0.0;
x0 = zeros(d); # starting point sampler
# estimated posterior mean (n=100000, 797s)
μ̂ = [
    3.406,
    -0.5918,
    0.0352,
    -0.3874,
    0.004481,
    -0.2346,
    -0.1495,
    -0.2184,
    0.01219,
    0.1731,
    -0.00976,
    -0.3224,
    0.2168,
    0.08002,
    -0.2829,
    -1.581,
    0.6666,
    -0.9984,
    1.081,
    1.405,
    0.327,
    -0.1357,
    -0.6446,
    -0.06583,
    -0.04994,
]
n = 2000
c = 4.0 # initial guess for the bound

init_scale = 1;
@time pf_result = pathfinder(ℓ; dim = d, init_scale);
M = PDMats.PDiagMat(diag(pf_result.fit_distribution.Σ));
M = pf_result.fit_distribution.Σ;
x0 = pf_result.fit_distribution.μ;
v0 = PDMats.unwhiten(M, randn(length(x0)));

MAP = pf_result.optim_solution; # MAP, could be useful for control variates

# define BouncyParticle sampler (has two relevant parameters) 
Z = BouncyParticle(
    missing, # graphical structure 
    MAP, # MAP estimate, unused
    2.0, # momentum refreshment rate and sample saving rate 
    0.95, # momentum correlation / only gradually change momentum in refreshment/momentum update
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
collect_sampler(as(post), sampler, 10; progress = false);

elapsed_time = @elapsed @time begin
    global bps_samples, info
    bps_samples, info = collect_sampler(as(post), sampler, n; progress = false)
end

using MCMCChains
bps_chain = MCMCChains.Chains(bps_samples.θ);
bps_chain = setinfo(bps_chain, (; start_time = 0.0, stop_time = elapsed_time));

μ̂1 = round.(mean(bps_chain).nt[:mean], sigdigits = 4)
println("μ̂ (BPS) = ", μ̂1)

using SampleChainsDynamicHMC
init_params = pf_result.draws[:, 1];
inv_metric = (pf_result.fit_distribution.Σ);
Tilde.sample(
    post,
    dynamichmc(;
        init = (; q = init_params, κ = GaussianKineticEnergy(inv_metric)),
        warmup_stages = default_warmup_stages(; middle_steps = 0, doubling_stages = 0),
    ),
    1,
    1,
);
hmc_time = @elapsed @time (
    hmc_samples = Tilde.sample(
        post,
        dynamichmc(;
            init = (; q = init_params, κ = GaussianKineticEnergy(inv_metric)),
            warmup_stages = default_warmup_stages(; middle_steps = 0, doubling_stages = 0),
        ),
        2000,
        1,
    )
);
hmc_chain = MCMCChains.Chains(hmc_samples.θ);
μ̂2 = round.(mean(hmc_chain).nt[:mean], sigdigits = 4);
println("μ̂ (HMC) = ", μ̂2)
hmc_chain = MCMCChains.setinfo(hmc_chain, (; start_time = 0.0, stop_time = hmc_time));

ess_bps = MCMCChains.ess_rhat(bps_chain).nt.ess_per_sec;
ess_hmc = MCMCChains.ess_rhat(hmc_chain).nt.ess_per_sec;

using UnicodePlots

plt = scatterplot(ess_bps, ess_hmc);
UnicodePlots.title!(plt, "Effective Samples Per Second");
xlabel!(plt, "Bouncy Particle Sampler");
ylabel!(plt, "DynamicHMC");
plt_bounds = collect(extrema(ess_hmc));
lineplot!(plt, plt_bounds, plt_bounds);
plt
@info "For each coordinate, a point (x,y) shows the effective sample size per second for BPS (x) and HMC (y) . In blue is the diagonal x=y"
