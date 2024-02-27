using JuMP
using Gurobi
using Combinatorics
using LKH
using Graphs, SimpleWeightedGraphs

#This is the same as Julia's Code, but everything is integer-valued. 
#We use the l_1 distance instead of l_2, and we use integer coordinates.
# Integer coordinates are used in the LKH code, so we adjust things here.

# Auxiliary data keys
SOLN_KEY = "solution"
SUBTOUR_KEY = "subtour"

# Contains the data, model and edge variables
struct TSPModel
    dat::TSPInstanceInt        # Problem data
    model::JuMP.Model       # Model data structure
    x::Matrix{VariableRef}  # Edge variables
    aux::Dict{Any, Any}     # Optional; Stores auxiliary model data (used for DFJ subtours)
end
Base.show(io::IO, mdl::TSPModel) = print(io, "TSP Model with $(mdl.dat.n) cities")

# Constructor for core TSP model with degree constraints
function TSPModel(dat::TSPInstanceInt;
    OutputFlag = 0,
    TimeLimit = 60,
	silent = false)
    n = dat.n
    d = dat.d

    optimizer = optimizer_with_attributes(Gurobi.Optimizer, 
        "OutputFlag" => OutputFlag,
        "TimeLimit" => TimeLimit)
    model = Model(optimizer)
        
    @variable(model, x[1:n, 1:n], Bin) # x[i, j] = 1 if edge (i, j) is used in the tour
    @objective(model, Min, sum(d .* x))
    @constraint(model, outflow[i in 1:n], sum(x[i, :]) == 1)
    @constraint(model, inflow[i in 1:n], sum(x[:, i]) == 1)
    @constraint(model, noself[i in 1:n], x[i, i] == 0)
    @constraint(model, subtour1[i in 1:n, j in 1:n], x[i, j] + x[j, i] <= 1)
    return TSPModel(dat, model, x, Dict())
end

# Returns a list of edges selected in solution `x`
function selected_edges(x::Matrix{Float64})
    n = size(x)[1]
    return Tuple{Int,Int}[(i, j) for i in 1:n, j in 1:n if x[i, j] > TOL]
end

# Adds ALL Dantzig-Fulkerson-Johnson constraints to a TSPModel
function add_dfj_constraints!(mdl::TSPModel)
    n = mdl.dat.n
    x = mdl.x
    if n >= 20
        @warn "Full DFJ model not recommended for large n"
    end
    node_subsets = collect(Combinatorics.powerset(1:n))
    @constraint(mdl.model, 
        [ss=node_subsets; 1 < length(ss) < n],
        sum(x[i, j] for (i, j) in Iterators.product(ss, ss)) <= length(ss) - 1
    )
    return
end

# Adds the Dantzig-Fulkerson-Johnson constraints lazily to a TSPModel
# Note that lazy constraints are faster than a naive iterative method if the problem size
# is large enough (about n=50 or larger)
function add_dfj_callback!(mdl::TSPModel)

    model = mdl.model
    x = mdl.x
    n = mdl.dat.n
    
    # Identifies shortest subtour in solution given by vector of edges
    function subtour(edges::Vector{Tuple{Int, Int}})
        shortest_subtour, unvisited = collect(1:n), Set(collect(1:n))
        while !isempty(unvisited)
            this_cycle, neighbors = Int[], unvisited
            while !isempty(neighbors)
                current = pop!(neighbors)
                push!(this_cycle, current)
                if length(this_cycle) > 1
                    pop!(unvisited, current)
                end
                neighbors =
                    [j for (i, j) in edges if i == current && j in unvisited]
            end
            if length(this_cycle) < length(shortest_subtour)
                shortest_subtour = this_cycle
            end
        end
        return shortest_subtour
    end

    # See https://jump.dev/JuMP.jl/stable/manual/callbacks/ for more about callbacks
    # This callback lazily adds subtour elimination constraints to the original model
    function subtour_elimination_callback(cb_data)
        
        # Only run at integer solutions
        status = callback_node_status(cb_data, model)
        if status != MOI.CALLBACK_NODE_STATUS_INTEGER
            return  
        end

        # Get incumbent (integral) solution
        edges = selected_edges(callback_value.(cb_data, x))
        cycle = subtour(edges)
        
        # Solution is made of a single tour of length n
        if length(cycle) == n
            return
        end

        # Save subtour
        if !haskey(mdl.aux, SOLN_KEY)
            mdl.aux[SOLN_KEY] = [edges]
            mdl.aux[SUBTOUR_KEY] = [cycle]
        else
            push!(mdl.aux[SOLN_KEY], edges)
            push!(mdl.aux[SUBTOUR_KEY], cycle)
        end

        # Add lazy constraint
        S = [(i, j) for (i, j) in Iterators.product(cycle, cycle)]
        con = @build_constraint(
            sum(x[i, j] for (i, j) in S) <= length(cycle) - 1,
        )
        MOI.submit(model, MOI.LazyConstraint(cb_data), con)
        return

    end
    set_attribute(
        model,
        MOI.LazyConstraintCallback(),
        subtour_elimination_callback,
    )
    return

end

# Computes the 1-tree bound for a given instance
function one_tree_bound(g::SimpleWeightedGraph, dat::TSPInstanceInt)

    #Create a copy that removes node n; we do this to help with indexing
    h = SimpleWeightedGraph(g)
    rem_vertex!(h,dat.n)    

    #Find an MST
    mst = kruskal_mst(h, weights(h); minimize=true)
    
    #Compute the MST weight
    mst_weight = sum([get_weight(g,src(mst[i]), dst(mst[i])) for i in 1:(dat.n-2)])

    #Find the cheapest edges to n
    #The first edge in this list will be n itself.
    cheapest_edges = partialsortperm(dat.d[dat.n,:],1:3)
    one_tree_weight = mst_weight + dat.d[dat.n,cheapest_edges[2]] + dat.d[dat.n,cheapest_edges[3]]

    #Now we create the one-tree
    tree = SimpleWeightedGraph(dat.n)

    for i in 1:(dat.n-2)
        add_edge!(tree,src(mst[i]), dst(mst[i]),get_weight(g,src(mst[i]), dst(mst[i])))
    end

    add_edge!(tree,dat.n,cheapest_edges[2],get_weight(g,dat.n,cheapest_edges[2]))
    add_edge!(tree,dat.n,cheapest_edges[3],get_weight(g,dat.n,cheapest_edges[3]))
    
    return one_tree_weight, tree

end


# Computes the Held-Karp iterative bound for a given instance
# Our implementation follows the exposition in 'Combinatorial Optimization' by Cook et al.
function HK_bound(dat::TSPInstanceInt, upper_bound::Int64)

    #Intialize
    max_changes = 100
    t_small = 0.001
    y_vals = [0 for i in 1:dat.n]
    H_star = -(dat.n^2)
    alpha = 2
    beta = 0.5
    num_iterations = Int.(.1*dat.n)

    
    for c in 1:max_changes
        for k in 1:num_iterations

        #Create the weighted graph
        g = SimpleWeightedGraph(dat.n)

        for i in 1:dat.n
            for j in 1:dat.n
                add_edge!(g,i,j,dat.d[i,j]-y_vals[i]-y_vals[j])
            end
        end

        one_tree_weight, tree = one_tree_bound(g,dat)

        if one_tree_weight > H_star
            H_star = one_tree_weight
        end

        #Skip the check that we have a tour

        degrees = degree(tree)

        deg_sum_violation = sum([(2-degrees[i])^2 for i in 1:dat.n])
            
        t_k = alpha*(upper_bound-one_tree_weight) / deg_sum_violation

        if t_k < t_small
            return H_star
        end
            
        y_vals = [(y_vals[i] + t_k*(2-degrees[i])) for i in 1:dat.n]
        alpha = alpha*beta
        
        end
    end
    
    return H_star

end

    
