using Graphs, SimpleWeightedGraphs

# Computes the 1-tree bound for a given instance
function one_tree_bound(g::SimpleWeightedGraph, dat::TSPInstance)

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
function hk_bound(dat::TSPInstance, upper_bound::Int64)

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

        # Create the weighted graph
        g = SimpleWeightedGraph(dat.n)

        for i in 1:dat.n
            for j in 1:dat.n
                wt = dat.d[i,j]-y_vals[i]-y_vals[j]
                add_edge!(g, i, j, max(wt, 1e-6))
            end
        end

        one_tree_weight, tree = one_tree_bound(g,dat)

        if one_tree_weight > H_star
            H_star = one_tree_weight
        end

        # Skip the check that we have a tour

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
