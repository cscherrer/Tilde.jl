# Identify variables with a non-trivial lens
function lensvars(ast)
    result = Symbol[]
    leaf(x;kwargs...) = nothing
    
    function branch(f, head, args; kwargs...)
        @match Expr(head, args...) begin
            :(($x, $l) ~ $rhs) => begin
                @match l begin
                    :((Accessors.opticcompose)())  => nothing  
                    :(identity) => nothing
                    _ => push!(result, x) 
                end
            end
            _ => begin
                foreach(f, args)
            end
        end

        return result
    end 
    
    foldast(leaf, branch)(opticize(ast))
end
