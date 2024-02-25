using Plots

TOL = 0.5

#This is the same as Julia's Code, but everything is integer-valued. 
#We use the l_1 distance instead of l_2, and we use integer coordinates.
# Integer coordinates are used in the LKH code, so we adjust things here.

# Stores TSP solution and computational results
struct TSPSolution
    dat::TSPInstanceInt
    edges::Vector{Tuple{Int,Int}}
    objective_value::Float64
    solve_time::Float64
end
Base.show(io::IO, solution::TSPSolution) = print(io, "TSP Solution with $(solution.dat.n) cities")

# Optimizes the model and returns the TSPSolution
function solve!(mod::TSPModel)
    JuMP.optimize!(mod.model)
    if termination_status(mod.model) == TIME_LIMIT && !has_values(mod.model)
        return Nothing
    end
    return TSPSolution(
        mod.dat, 
        selected_edges(JuMP.value.(mod.x)), 
        JuMP.objective_value(mod.model),
        JuMP.solve_time(mod.model))
end

# Plots `edges` using coordinates from instance `dat`
# Optional `highlight` argument highlights edges in/out of certain nodes in red
function plot_tour(
    dat::TSPInstanceInt, 
    edges::Vector{Tuple{Int,Int}};
    highlight::Vector{Int} = Int[]
)
    plt = Plots.plot()
    for (i, j) in edges
        color = ((i in highlight) && (j in highlight)) ? :red : :black
        Plots.plot!(
            [dat.coords[i, 1], dat.coords[j, 1]], 
            [dat.coords[i, 2], dat.coords[j, 2]],
            lc=color, lw=2; 
            legend = false)
    end
    return plt
end
# Overload function
plot_tour(solution::TSPSolution) = plot_tour(solution.dat, solution.edges)
