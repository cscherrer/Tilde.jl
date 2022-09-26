import Tilde

using TransformVariables  
using TransformVariables: asℝ, transform

m = @model begin
    a ~ Normal()
    b ~ Normal(a,1)
end

as(::typeof(m())) = as((a=asℝ, b=asℝ))

t = as(m())

transform(t, randn(2))

using LinearAlgebra
using SparseArrays
using ZigZagBoomerang

function zigzag(m::Tilde.AbstractConditionalModel, T = 1000.0; c=10.0, adapt=false)

    ℓ(pars) = unsafe_logdensityof(m, pars)

    t = as(m)

    function f(x)
        (θ, logjac) = TransformVariables.transform_and_logjac(t, x)
        -ℓ(θ) - logjac
    end

    d = t.dimension

    z = zeros(d)

    function partiali()
        # ith = zeros(n)
        ith = z
        
        function (x,i)
            @inbounds ith[i] = 1.0
            sa = StructArray{ForwardDiff.Dual{}}((x, ith))
            result = f(sa)
            @inbounds ith[i] = 0.0
            return result
        end

    end

    ∇ϕi = partiali()

    # Draw a random starting points and velocity
    tkeys = keys(transform(t, z))
    vars = NamedTuple{tkeys}(rand(m))

    t0 = 0.0
    x0 = TransformVariables.inverse(t, vars)
    θ0 = randn(d)
    
    pdmp(∇ϕi, t0, x0, θ0, T, c*ones(d), ZigZag(sparse(I(d)), 0*x0); adapt=adapt)
end

zigzag(m())