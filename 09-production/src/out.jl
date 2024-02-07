using Plots

TOL = 1e-5

# Stores Production Planning solution and computational results
struct ProductionSolution
	dat::ProductionInstance
	production_periods::Vector{Int}
	production_units::Vector{Float64}
	objective_value::Float64
	solve_time::Float64
end
Base.show(io::IO, solution::ProductionSolution) = print(io, 
	"Production Planning Solution with $(length(solution.production_periods))/$(solution.dat.T) periods")

# Optimizes the model and returns the ProductionSolution
function solve!(mdl::ProductionModel)
	JuMP.optimize!(mdl.model)
	if termination_status(mdl.model) == TIME_LIMIT && !has_values(mdl.model)
		return Nothing
	end
	return ProductionSolution(
		mdl.dat, 
		findall(JuMP.value.(mdl.do_produce) .> TOL), 
		JuMP.value.(mdl.production[findall(JuMP.value.(mdl.do_produce) .> TOL)]),
		JuMP.objective_value(mdl.model),
		JuMP.solve_time(mdl.model))
end

# Plots the production plan
function plot_plan(solution::ProductionSolution)
	plt = Plots.plot()
	Plots.bar!(
		solution.production_periods, solution.production_units,
		label = "Production")
	Plots.plot!(solution.dat.demand, label="Demand", linewidth=3, marker=:circle)
	xlabel!("Period")
    ylabel!("Units")
    title!("Production Planning Solution (Cost = $(round(solution.objective_value, digits=2)))")
	return plt
end
