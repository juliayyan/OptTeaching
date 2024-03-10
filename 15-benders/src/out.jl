using Plots

# Stores facility location solution and computational results
struct FacilitySolution
	dat::FacilityInstance
	open_facilities::Vector{Int}
	customer_assignments::Vector{Int}
	objective_value::Float64
	solve_time::Float64
end
Base.show(io::IO, solution::FacilitySolution) = print(
	io, "Facility Solution with cost $(round(solution.objective_value, digits=2))")

# Optimizes the model and returns the solution
function solve!(mdl::Union{FacilityModel, MasterProblem})
	JuMP.optimize!(mdl.model)
	if termination_status(mdl.model) == TIME_LIMIT && !has_values(mdl.model)
		return Nothing
	end
	open_facilities = findall(JuMP.value.(mdl.y) .> EPSILON)
	if typeof(mdl) == FacilityModel
		customer_assignments = [
			findfirst(JuMP.value.(mdl.x[c, :]) .> EPSILON) 
			for c in 1:mdl.dat.n_customers
		]
	else # closest facility fo customer
		customer_assignments = [
			open_facilities[sortperm(mdl.dat.dist[c, open_facilities])[1]]
			for c in 1:mdl.dat.n_customers
		]
	end
	return FacilitySolution(
		mdl.dat, 
		open_facilities,
		customer_assignments,
		JuMP.objective_value(mdl.model),
		JuMP.solve_time(mdl.model))
end

# Plots a facility location instance
function plot_instance(dat::FacilityInstance)
	plt = Plots.plot()
	Plots.scatter!(
	    dat.customer_coords[:,1], dat.customer_coords[:,2],
	    label = "Customers"
	)
	Plots.scatter!(
	    dat.facility_coords[:,1], dat.facility_coords[:,2],
	    label = "Facilities",
	    markersize = 6, alpha = 0.5, markercolor = :orange,
	)
	Plots.title!("Facility Location Instance")
	return plt
end

# Plots a facility location solution
function plot_solution(solution::FacilitySolution)
	dat = solution.dat
	plt = plot_instance(dat)
	Plots.title!("Facility Location Solution\n(Cost = $(round(solution.objective_value, digits=2)))")
	for c in 1:dat.n_customers
		Plots.plot!(
			[dat.customer_coords[c, 1], dat.facility_coords[solution.customer_assignments[c], 1]], 
			[dat.customer_coords[c, 2], dat.facility_coords[solution.customer_assignments[c], 2]],
			color = :black, label = nothing, alpha = 0.2)
	end
	Plots.scatter!(
	    dat.facility_coords[solution.open_facilities,1], 
	    dat.facility_coords[solution.open_facilities,2],
	    label = nothing,
	    markersize = 6, markercolor = :orange,
	)
	return plt
end
