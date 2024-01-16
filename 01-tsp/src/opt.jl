using JuMP
using Gurobi
using Combinatorics

# Auxiliary data keys
SOLN_KEY = "solution"
SUBTOUR_KEY = "subtour"

# Contains the data, model and edge variables
struct TSPModel
	dat::TSPInstance		# Problem data
	model::JuMP.Model 		# Model data structure
	x::Matrix{VariableRef}	# Edge variables
	aux::Dict{Any, Any}		# Optional; Stores auxiliary model data (used for DFJ subtours)
end
Base.show(io::IO, mdl::TSPModel) = print(io, "TSP Model with $(mdl.dat.n) cities")

# Constructor for core TSP model with degree constraints
function TSPModel(dat::TSPInstance;
	OutputFlag = 0,
	TimeLimit = 60)
	n = dat.n
	d = dat.d
	model = Model(optimizer_with_attributes(
		Gurobi.Optimizer, 
		"OutputFlag" => OutputFlag,
		"TimeLimit" => TimeLimit)
	)
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

# Adds the Miller-Tucker-Zemlin constraints to a TSPModel
function add_mtz_constraints!(mdl::TSPModel)
	n = mdl.dat.n
	x = mdl.x
	@variable(mdl.model, u[1:n] >= 1)
	@constraint(mdl.model, u[1] == 1)
	@constraint(mdl.model, [i=2:n], u[i] <= n)
	@constraint(mdl.model, [i=2:n], u[i] >= 2)
	@constraint(mdl.model,
		[i in 2:n, j in 2:n; i != j],
		u[i] - u[j] + 1 <= (n - 1) * (1 - x[i, j])
	)
	return
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
