using SimplePartitions: find_part
import SimpleGraphs
using SimplePosets: interval

export parents
parents(g::SimpleDigraph, v) = g.NN[v] |> collect

export children
children(g::SimpleDigraph, v) = g.N[v] |> collect

export partners
function partners(g::SimpleDigraph, v::Symbol)
    s = map(collect(children(g,v))) do x 
        parents(g,x) 
    end

    isempty(s) && return []

    setdiff(union(s...),[v]) |> collect
end


# function stochParents(m::DAGModel, g::SimpleDigraph, v::Symbol, acc=Symbol[])
#     pars = parents(g,v)

#     result = union(pars, acc)
#     for p in pars
#         union!(result, _stochParents(m, g, findStatement(m,p)))
#     end
#     result
# end
