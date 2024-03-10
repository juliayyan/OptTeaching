using JuMP, Gurobi

env = Gurobi.Env()
EPSILON = 0.5

#============================================
Baseline: No decomposition
============================================#

# Full, basic implementation of facility location problem (no decomposition)
struct FacilityModel
	dat::FacilityInstance
	model::JuMP.Model
	y::Vector{JuMP.VariableRef}
	x::Matrix{JuMP.VariableRef}
end
Base.show(io::IO, mp::FacilityModel) = print(io, "Full Problem for $(mp.dat)")

# Constructor for FacilityModel
function FacilityModel(dat::FacilityInstance)
	model = JuMP.Model(() -> Gurobi.Optimizer(env))
	@variable(model, y[f = 1:dat.n_facilities], Bin)
	@variable(model, x[c = 1:dat.n_customers, f = 1:dat.n_facilities] >= 0)
	@constraint(model, 
		assign[c = 1:dat.n_customers],
		sum(x[c, f] for f = 1:dat.n_facilities) >= 1)
	@constraint(model,
		link[c = 1:dat.n_customers, f = 1:dat.n_facilities],
		x[c, f] <= y[f])
	@objective(model, 
		Min,
		dat.fixed_cost*sum(y) +
		sum(dat.dist[c, f] * x[c, f] for c = 1:dat.n_customers, f = 1:dat.n_facilities))
	return FacilityModel(dat, model, y, x)
end

#============================================
Benders Decomposition
============================================#

# Master problem for facility location problem, using Benders Decomposition
struct MasterProblem
	dat::FacilityInstance
	model::JuMP.Model
	y::Vector{JuMP.VariableRef}
	obj::JuMP.VariableRef
	aux::Dict{Any, Any}
end
Base.show(io::IO, mp::MasterProblem) = print(io, "Master Problem for $(mp.dat)")

# Constructor for facility location MasterProblem 
function MasterProblem(dat::FacilityInstance)
	model = JuMP.Model(() -> Gurobi.Optimizer(env))
	set_silent(model)
	@variable(model, y[f = 1:dat.n_facilities], Bin)
	@constraint(model, sum(y) >= 1) # So that we start with a solution with some facility open
	@variable(model, obj >= 0)	# We can apply >= 0 because we know that the objective for this problem is positive
	@objective(model, Min, dat.fixed_cost*sum(y) + obj)
	return MasterProblem(dat, model, y, obj, Dict())
end

# Returns the LHS and RHS of a cut of the form LHS >= RHS
function cut_expr(
	mp::MasterProblem,
	this_y::Vector{Float64}, 
	this_obj::Float64;
	tolerance = 1e-5
)
	dat = mp.dat

	open_facilities = findall(this_y .> EPSILON)
	best_dist = [
		minimum(dat.dist[c, open_facilities])
		for c in 1:dat.n_customers
	]
	rhs(y) = sum(
		best_dist[c] - 
		sum(
			max(0, best_dist[c] - dat.dist[c, f])*y[f] 
			for f in 1:dat.n_facilities
		)
		for c in 1:dat.n_customers
	)

	# Return LHS >= RHS optimality or feasibility cut
	if this_obj >= rhs(this_y) - tolerance
		return (Nothing, Nothing)
	else
		return (mp.obj, rhs(mp.y))
	end

end

# Performs one iteration of Benders Decomposition, not lazily
# Returns the number of cuts added
function generate_cut!(
	mp::MasterProblem;
	tolerance::Float64 = 1e-5
)
	# Solve master problem
	optimize!(mp.model)
	this_y = JuMP.value.(mp.y)
	this_obj = JuMP.value(mp.obj)

	# Generate Benders cut
	lhs, rhs = cut_expr(mp, this_y, this_obj, tolerance = tolerance)	
	if lhs == rhs == Nothing
		return 0
	end
	@constraint(mp.model, lhs >= rhs)
	return 1
end

# Adds the callback needed to implement Benders Decomposition lazily
function add_benders_callback!(mp::MasterProblem; tolerance::Float64 = 1e-5)

	dat = mp.dat

	# See Benders progress
	unset_silent(mp.model)

	function benders_callback(cb_data)
			
		# Only run at integer solutions
		status = callback_node_status(cb_data, mp.model)
		if status != MOI.CALLBACK_NODE_STATUS_INTEGER
			return  
		end

		# Generate cut and add lazily
		this_y = callback_value.(cb_data, mp.y)
		this_obj = callback_value(cb_data, mp.obj)
		lhs, rhs = cut_expr(mp, this_y, this_obj, tolerance = tolerance)
		if lhs == rhs == Nothing
			return
		end
		new_cut = @build_constraint(lhs >= rhs)
		MOI.submit(mp.model, MOI.LazyConstraint(cb_data), new_cut)

	end

	set_attribute(
		mp.model,
		MOI.LazyConstraintCallback(),
		benders_callback
	)

end
