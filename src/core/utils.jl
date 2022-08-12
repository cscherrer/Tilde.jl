using MLStyle
# import SimplePosets
using NestedTuples
using NestedTuples: LazyMerge


schema_shallow(::NamedTuple{(), Tuple{}}) = NamedTuple()
schema_shallow(::Type{NamedTuple{(), Tuple{}}}) = NamedTuple()

function schema_shallow(NT::Type{NamedTuple{names, T}}) where {names, T}
    return namedtuple(NestedTuples.ntkeys(NT), schema_shallow(NestedTuples.ntvaltype(NT)))
end

function schema_shallow(TT::Type{T}) where {T <: Tuple} 
    return Tuple(TT.types)
end

schema_shallow(t::T) where {T <: NamedTuple} = schema_shallow(T) 

schema_shallow(T) = T

expr(x) = :(identity($x))

# like `something`, but doesn't throw an error
maybesomething() = nothing
maybesomething(x::Nothing, y...) = maybesomething(y...)
maybesomething(x::Some, y...) = x.value
maybesomething(x::Any, y...) = x

export argtuple
argtuple(m) = arguments(m) |> astuple

astuple(x) = Expr(:tuple, x...)
astuple(x::Symbol) = Expr(:tuple, x)

export arguments
arguments(m::AbstractModel) = model(m).args

export parameters
parameters(m::AbstractModel) = parameters(m.body)

parameters(m::AbstractConditionalModel) = parameters(model(m))

function parameters(ast)
    leaf(x) = Set{Symbol}()
    @inline function branch(f, head, args)
        default() = mapreduce(f, union, args)
        head == :call || return default()
        first(args) == :~ || return default()
        length(args) == 3 || return default()

        # If we get here, we know we're working with something like `lhs ~ rhs`
        lhs = args[2]
        rhs = args[3]

        lhs′ = @match lhs begin
            :(($(x::Symbol), $o)) => return Set{Symbol}((x,))
            :(($(x::Var), $o)) => return Set{Symbol}((x.name,))
            _ => begin
                (x, o) = parse_optic(lhs)
                return Set{Symbol}((x,))
            end
        end
    end

    foldast(leaf, branch)(ast)
end

export variables
variables(m::AbstractModel) = union(arguments(m), parameters(m))

function variables(expr::Expr)
    leaf(s::Symbol) = begin
        [s]
    end
    leaf(x) = []
    branch(head, newargs) = begin
        union(newargs...)
    end
    foldall(leaf, branch)(expr)
end

variables(s::Symbol) = [s]
variables(x) = []

export foldast

function foldast(leaf, branch; kwargs...)
    @inline f(ast::Expr; kwargs...) = branch(f, ast.head, ast.args; kwargs...)
    @inline f(x; kwargs...) = leaf(x; kwargs...)
    return f
end

export foldall
function foldall(leaf, branch; kwargs...)
    function go(ast)
        MLStyle.@match ast begin
            Expr(head, args...) => branch(head, map(go, args); kwargs...)
            x                   => leaf(x; kwargs...)
        end
    end

    return go
end

export foldall1
function foldall1(leaf, branch; kwargs...)
    function go(ast)
        MLStyle.@match ast begin
            Expr(head, arg1, args...) => branch(head, arg1, map(go, args); kwargs...)
            x                         => leaf(x; kwargs...)
        end
    end

    return go
end

import MacroTools: striplines, @q

allequal(xs) = all(xs[1] .== xs)

# # fold example usage:
# # ------------------
# # function leafCount(ast)
# #     leaf(x) = 1
# #     expr(head, arg1, newargs) = sum(newargs)
# #     fold(leaf, expr)(ast)
# # end

# # leaves = begin
# #     leaf(x) = [x]
# #     expr(head, arg1, newargs) = union(newargs...)
# #     fold(leaf, expr)
# # end

# # ast = :(f(x + 3y))

# # leaves(ast)

# # Example of Tamas Papp's `as` combinator:
# # julia> as((;s=as(Array, as𝕀,4), a=asℝ))(randn(5))
# # (s = [0.545324, 0.281332, 0.418541, 0.485946], a = 2.217762640580984)

# using BenchmarkTools
# f(;kwargs...) = kwargs[:a] + kwargs[:b]

# @btime invokefrozen(f, Int; a=3,b=4)  # 3.466 ns (0 allocations: 0 bytes)
# @btime f(;a=3,b=4)                    # 1.152 ns (0 allocations: 0 bytes)

# @isdefined
# Base.@locals
# @__MODULE__
# names



function loadvals(argstype)
    args = schema_shallow(argstype)
   
    loader = @q begin end

    for k in keys(args)
        T = getproperty(args, k)
        push!(loader.args, :(local $k::$T = _args.$k))
    end


    # for k in keys(pars) ∩ keys(data)
    #     qk = QuoteNode(k)
    #     if typejoin(getproperty(pars, k), getproperty(data, k)) <: NamedTuple
    #         push!(loader.args, :($k = Tilde.NestedTuples.lazymerge(_obs.$k, _pars.$k)))
    #     else
    #         T = getproperty(pars, k)
    #         push!(loader.args, quote
    #             _k = $qk
    #             @warn "Duplicate key, ignoring $_k in data"
    #             $k::$T = _pars.$k
    #         end)
    #     end
    # end

    src -> (@q begin
        $loader
        $src
    end) |> MacroTools.flatten
end


function loadvals(argstype, obstype, parstype)
    args = schema_shallow(argstype)
    data = schema_shallow(obstype)
    pars = schema_shallow(parstype)

    loader = @q begin end

    for k in keys(args) ∪ keys(pars) ∪ keys(data)
        push!(loader.args, :(local $k))
    end
    for k in setdiff(keys(args), keys(pars) ∪ keys(data))
        T = getproperty(args, k)
        push!(loader.args, :($k::$T = _args.$k))
    end
    for k in setdiff(keys(data), keys(pars))
        T = getproperty(data, k)
        push!(loader.args, :($k::$T = _obs.$k))
    end

    for k in setdiff(keys(pars), keys(data))
        T = getproperty(pars, k)
        push!(loader.args, :($k::$T = _pars.$k))
    end

    # for k in keys(pars) ∩ keys(data)
    #     qk = QuoteNode(k)
    #     if typejoin(getproperty(pars, k), getproperty(data, k)) <: NamedTuple
    #         push!(loader.args, :($k = Tilde.NestedTuples.lazymerge(_obs.$k, _pars.$k)))
    #     else
    #         T = getproperty(pars, k)
    #         push!(loader.args, quote
    #             _k = $qk
    #             @warn "Duplicate key, ignoring $_k in data"
    #             $k::$T = _pars.$k
    #         end)
    #     end
    # end

    src -> (@q begin
        $loader
        $src
    end) |> MacroTools.flatten
end

# This is just handy for REPLing, no direct connection to Tilde

# julia> tower(Int)
# 6-element Array{DataType,1}:
#  Int64
#  Signed
#  Integer
#  Real
#  Number
#  Any

const TypeLevel = GG.TypeLevel

export dropreturn

function dropreturn(m::Model)
    Model(getmodule(m), arguments(m), dropreturn(body(m)))
end

function dropreturn(ast)
    leaf(x) = x
    function branch(f, head, args)
        head === :return && return quote end
        return Expr(head, map(f, args)...)
    end 
    foldast(leaf, branch)(ast) |> MacroTools.flatten
end

export setreturn

function setreturn(m::Model, expr)
    Model(getmodule(m), arguments(m), setreturn(dropreturn(body(m)), expr))
end

function setreturn(ast, expr)
    ast = copy(ast)
    push!(ast.args, expr)
end

function detilde(ast)
    q = MLStyle.@match ast begin
        :($x ~ $rhs)        => :($x = __SAMPLE__($rhs))
        Expr(head, args...) => Expr(head, map(detilde, args)...)
        x                   => x
    end

    MacroTools.flatten(q)
end

retilde(s::Symbol) = s
retilde(s::Number) = s

function retilde(v::JuliaVariables.Var)
    ifelse(v.name == :__SAMPLE__, :__SAMPLE__, v)
end

function retilde(ast)
    MLStyle.@match ast begin
        :($x = $v($rhs))    => begin
            rx = retilde(x)
            rv = retilde(v)
            rrhs = retilde(rhs)
            if rv == :__SAMPLE__
                return :($rx ~ $rrhs)
            else
                return :($rx = $rv($rrhs))
            end
        end
        Expr(head, args...) => Expr(head, map(retilde, args)...)
        x                   => x
    end
end

asfun(m::AbstractModel) = :(($(arguments(m)...),) -> $(Tilde.body(m)))

function solve_scope(m::AbstractModel)
    solve_scope(asfun(m))
end

function solve_scope(ex::Expr)
    ex |> detilde |> simplify_ex |> MacroTools.flatten |> solve_from_local! |> retilde
end

function locally_bound(ex, optic)
    isolated = solve_scope(optic(ex))
    in_context = optic(solve_scope(ex))

    setdiff(globals(isolated), globals(in_context))
end

"""
Given a JuliaVariables "solved" expression, convert back to a standard expression
"""
function unsolve(ex)
    ex = unwrap_scoped(ex)
    @match ex begin
        v::JuliaVariables.Var => v.name
        Expr(head, args...) => Expr(head, map(unsolve, args)...)
        x => x
    end
end

"""
Return the set of local variable names from a *solved* expression (using JuliaVariables)
"""
function locals(ex)
    go(ex) = @match ex begin
        v::JuliaVariables.Var => ifelse(v.is_global, Set{Symbol}(), Set((v.name,)))
        Expr(head, args...) => union(map(go, args)...)
        x => Set{Symbol}()
    end

    Tuple(go(ex))
end

# make_closure(funexpr)

# @gg function make_closure(__vars::NamedTuple{N,T}, funexpr) where {N,T}
#     funexpr = 
#     fdict = MacroTools.splitdef(funexpr)
#     for v in N
#         qv = QuoteNode(v)
#         pushfirst!(fdict[:body], :($v = getproperty(__vars, $qv)))
#     end

#     fdict[:args] = Any[:__ctx, Expr(:tuple, fdict[:args]...)]  

# f(ctx) = Base.Fix1(ctx) do ctx, j
#     p = ctx.p
#     Bernoulli(p/j)
# end

struct ReturnNow{T}
    value::T
end

"""
    julia> a = Any[1, 2, 3.0];

    julia> narrow_array(a)
    3-element Vector{Real}:
     1
     2
     3.0
"""
narrow_array(x) = collect(Base.Generator(identity, x))

function parse_optic(ex)
    unescape.(Accessors.parse_obj_optic(ex))
end

Base.@pure function merge_names(an::Tuple{Vararg{Symbol}}, bn::Tuple{Vararg{Symbol}})
    @nospecialize an bn
    names = Symbol[an...]
    for n in bn
        if !Base.sym_in(n, an)
            push!(names, n)
        end
    end
    (names...,)
end

Base.@pure function merge_types(names::Tuple{Vararg{Symbol}}, a::Type{<:NamedTuple}, b::Type{<:NamedTuple})
    @nospecialize names a b
    bn = Base._nt_names(b)
    return Tuple{Any[ fieldtype(Base.sym_in(names[n], bn) ? b : a, names[n]) for n in 1:length(names) ]...}
end


@generated function mymerge(a::NamedTuple{an}, b::NamedTuple{bn}) where {an, bn}
    names = Base.merge_names(an, bn)
    types = Base.merge_types(names, a, b)
    vals = Any[ :(getfield($(Base.sym_in(names[n], bn) ? :b : :a), $(QuoteNode(names[n])))) for n in 1:length(names) ]
    quote
        # $(Expr(:meta, :inline))
        NamedTuple{$names,$types}(($(vals...),))::NamedTuple{$names,$types}
    end
end



abstract type MayReturn end
struct HasReturn <: MayReturn end
struct NoReturn <: MayReturn end

export hasreturn

# These work just fine without the `@generated` but take *much* longer 
# (92μs vs 1.3ns on a small model)
@generated function hasreturn(::M) where {M<:AbstractModel}
    _hasreturn(body(M)) ? HasReturn() : NoReturn()
end

@generated function hasreturn(::M) where {M<:AbstractConditionalModel}
    _hasreturn(body(model(M))) ? HasReturn() : NoReturn()
end


_hasreturn(x) = false

function _hasreturn(ast::Expr)
    ast.head == :return && return true
    return any(_hasreturn, ast.args)
end
