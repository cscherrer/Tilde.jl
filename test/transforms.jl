m = @model (n,α,β) begin
    p ~ Beta(α, β)
    x ~ Binomial(n, p)
    z ~ Binomial(n, α/(α+β))
end

@testset "prior" begin
    m1 = Tilde.prior(m, :x)
    @test Tilde.prior(m, :x) ≊ @model (α, β) begin
        p ~ Beta(α, β)
    end
end


@testset "likelihood" begin
    m1 = Tilde.likelihood(m, :x)
    @test Tilde.likelihood(m, :x) ≊ @model (p, n) begin
        x ~ Binomial(n, p)
    end
end

m1 = prune(m, :z)
@testset "prune" begin
    @test prune(m, :x, :z) ≊ @model (α, β) begin
        p ~ Beta(α, β)
    end
    @test prune(m1, :n) ≊ @model (α, β) begin
        p ~ Beta(α, β)
    end
    @test prune(m, :p) ≊ @model (α, n, β) begin
        z ~ Binomial(n, α / (α + β))
    end

    # When I define these variables, the tests pass.
    # Doing "@test prune(m1, :p) ≊ @model begin end" strangely causes an error in @model about reducing over an empty collection.
    emptymodel = @model begin end
    @test prune(m1, :p) ≊ emptymodel
end

@testset "predictive" begin
    @test predictive(m, :p) ≊ @model (n, p) begin
        x ~ Binomial(n, p)
    end
end

@testset "Do" begin
    @test Do(m, :p, :z) ≊ @model (n, p) begin
        x ~ Binomial(n, p)
    end
    empty = @model begin end
    @test Do(m, variables(m)...) ≊ empty
end
