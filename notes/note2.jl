using Tilde

m = @model x begin
    n = length(x)
    p ~ Uniform()
    for j in 1:n 
        x[j] ~ Bernoulli(p/√j)
    end
end;

x = Vector{Bool}(undef, 3);
r = rand(m(x))

# 2-argument form of `predict` takes an `AbstractConditionalModel` (a
# `ModelClosure` or `ModelPosterior`) and some parameters to fix. This form is
# like running `rand` on the closure or posterior resulting from a causal
# intervention.
predict(m(x), (p = 0.9,))

# We can also pass an `f` as the first argument. Having such a method makes it
# convenient to use Juila's `do` syntax. The above is equivalent to
predict(m(x), (p = 0.9,)) do d,x
    rand(d)
end

# Instead of sampling, maybe we want to evaluate the log-density
predict(m(x) | (x = [true, false, false],), (p = 0.9,)) do d,x
    logdensityof(d, x)
end

# Or find the conditional mean
predict(m(x) | (x = [true, false, false],), (p = 0.9,)) do d,x
    mean(d)
end




predict(m(x), (x=x,))




measures(m(x))


logdensityof(m(x), r)

testvalue(m(x))

predict(m(x), (p=0.9,))




# Broken
getdag(m(x), r)


# Broken