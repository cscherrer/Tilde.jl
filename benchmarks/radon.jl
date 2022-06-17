
# def build_model(pm):
#     with pm.Model(coords=coords) as hierarchical_model:
#         # Intercepts, non-centered
#         mu_a = pm.Normal("mu_a", mu=0.0, sigma=10)
#         sigma_a = pm.HalfNormal("sigma_a", 1.0)
#         a = pm.Normal("a", dims="county") * sigma_a + mu_a
        
#         # Slopes, non-centered
#         mu_b = pm.Normal("mu_b", mu=0.0, sigma=2.)
#         sigma_b = pm.HalfNormal("sigma_b", 1.0)
#         b = pm.Normal("b", dims="county") * sigma_b + mu_b
        
#         eps = pm.HalfNormal("eps", 1.5)
        
#         radon_est = a[county_idx] + b[county_idx] * data.floor.values
        
#         radon_like = pm.Normal(
#             "radon_like", mu=radon_est, sigma=eps, observed=data.log_radon, 
#             dims="obs_id"
#         )
        
#     return hierarchical_model

using Tilde, CSV, DataFrames, MappedArrays

# using RDatasets
# radon=dataset("HLMdiag","radon")

# data from 
# https://github.com/twiecki/WhileMyMCMCGentlySamples/blob/master/content/downloads/notebooks/radon.csv
data = CSV.read("radon.csv", DataFrame);
flr = data.floor;
county_idx = data.county_code .+ 1;

a = randn(maximum(county_idx));
b = copy(a);
y = data.log_radon;


radon = @model county_idx, flr begin
    n = length(county_idx)
    num_counties = 85
    μa ~ Normal(σ=10)
    σa ~ HalfNormal()
    a_raw ~ Normal() ^ num_counties
    a = mappedarray(a_raw) do z
        σa * z + μa
    end

    μb ~ Normal(0, 2)
    σb ~ HalfNormal()
    b_raw ~ Normal() ^ num_counties
    b = mappedarray(b_raw) do z
        σb * z + μb
    end

    ε ~ HalfNormal(1.5)

    # for j in 1:n
    #     i = county_idx[j]
    #     yhat_j = a[i] + b[i] * flr[j]
    #     y[j] ~ Normal(yhat_j, ε)
    # end
    y ~ For(n) do j
        @inbounds i = county_idx[j]
        @inbounds yhat_j = a[i] + b[i] * flr[j]
        Normal(yhat_j, ε)
    end
end

# radon2 = @model county_idx, flr, y begin
#     num_counties = 85
#     n = length(county_idx)
#     μa ~ Normal(σ = 10)
#     σa ~ HalfNormal()
#     a ~ Normal() ^ num_counties

#     μb ~ Normal(σ = 2)
#     σb ~ HalfNormal()
#     b ~ Normal() ^ num_counties

#     ε ~ HalfNormal(1.5)
#     s(x, μ, σ) = x*σ + μ


#     for j in 1:n
#         yhat_j = s(a[county_idx[j]], μa, σa) + s(b[county_idx[j]], μb, σb)* flr[j]
#         y ~ Normal(yhat_j, ε)
#     end
# end


post = radon(county_idx, flr) | (y = y,)

using SampleChainsDynamicHMC
# @time sample(post, dynamichmc())

using PDMats, LinearAlgebra

const as_post = as(post)
d = TV.dimension(as_post)
tr(θ) = TV.transform(as_post, θ)
ℓ(θ) = unsafe_logdensityof(radon(county_idx, flr) | (y = y,), tr(θ))
obj(θ) = -ℓ(θ)

using Pathfinder

init_scale=1;
@time pf_result = pathfinder(ℓ; dim=d, init_scale=1);
M = PDMats.PDiagMat(diag(pf_result.fit_distribution.Σ));
M = pf_result.fit_distribution.Σ;
x0 = pf_result.fit_distribution.μ;
v0 = PDMats.unwhiten(M, randn(length(x0)));

MAP = pf_result.optim_solution; # MAP, could be useful for control variates



function dneglogp(t, x, v, args...) # two directional derivatives
    u = ForwardDiff.derivative(t -> obj(x + t*v), Dual{:hSrkahPmmC}(0.0, 1.0))
    u.value, u.partials[]
end

function ∇neglogp!(y, t, x, args...)
    ForwardDiff.gradient!(y, obj, x)
    y
end


# # for BPS

init_scale=1
@time pf_result = pathfinder(ℓ; dim=d, init_scale)
# M = Diagonal(1 ./ sqrt.(diag(result.fit_distribution.Σ)))
# x0 = result.fit_distribution.μ
# θ0 = M\randn(d) # starting direction sampler