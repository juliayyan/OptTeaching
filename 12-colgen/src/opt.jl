using JuMP, Gurobi

env = Gurobi.Env()

# A weak formulation for the cutting stock problem
struct WeakFormulation
	dat::StockInstance
	model::JuMP.Model
	z::Matrix{VariableRef}
	use_roll::Vector{VariableRef}
	relax::Bool
end

# Constructor for WeakFormulation
function WeakFormulation(
	dat::StockInstance;
	relax::Bool = true,
	time_limit::Int = 15,
	strengthen::Bool = false
)

	model = JuMP.Model(() -> Gurobi.Optimizer(env))
	set_time_limit_sec(model, time_limit)

	n_pieces = dat.n_pieces
	n_rolls = sum([piece.length for piece in dat.pieces] .* dat.demands)

	if relax
		@variable(model, z[pc=1:n_pieces, r=1:n_rolls] >= 0)
		@variable(model, 0 <= use_roll[r=1:n_rolls] <= 1)
	else
		@variable(model, z[pc=1:n_pieces, r=1:n_rolls] >= 0, Int)
		@variable(model, use_roll[r=1:n_rolls], Bin)
	end

	@constraint(model, 
		[pc=1:n_pieces],
		sum(z[pc, r] for r in 1:n_rolls) >= dat.demands[pc]
	)
	@constraint(model,
		[r=1:n_rolls],
		sum(dat.pieces[pc].length*z[pc, r] for pc in 1:n_pieces) <= 
		dat.max_length * (strengthen ? use_roll[r] : 1)
	)
	@constraint(model, 
		[pc=1:n_pieces, r=1:n_rolls],
		z[pc, r] <= dat.demands[pc]*use_roll[r]
	)

	@objective(model, Min, sum(use_roll))
	
	return WeakFormulation(dat, model, z, use_roll, relax)
end
Base.show(io::IO, wf::WeakFormulation) = print(io, "Weak Formulation with $(length(dat.pieces)) pieces")

# Master problem for column generation
struct MasterProblem
	dat::StockInstance
	model::JuMP.Model
	x::Vector{JuMP.VariableRef}
	satisfy_demand::Vector{JuMP.ConstraintRef}
	relax::Bool
end
Base.show(io::IO, mp::MasterProblem) = print(io, "Master Problem with $(length(dat.patterns)) patterns")

# Constructor for MasterProblem
function MasterProblem(
	dat::StockInstance;
	relax::Bool = true
)
	model = JuMP.Model(() -> Gurobi.Optimizer(env))
	set_silent(model)
	n_pieces = dat.n_pieces
	n_patterns = length(dat.patterns)
	@assert n_patterns > 0

	# x[pattern] = 1 if pattern is used
	if relax
		@variable(model, x[1:n_patterns] >= 0)
	else
		@variable(model, x[1:n_patterns] >= 0, Int)
	end

	@constraint(model, 
		satisfy_demand[pc=1:n_pieces],
		sum(dat.patterns[pt].quantities[pc]*x[pt] for pt in 1:n_patterns) >= dat.demands[pc]
	)

	@objective(model, Min, sum(x))

	return MasterProblem(dat, model, x, satisfy_demand, relax)
end

# Solves the knapsack subproblem to generate new pattern
# Returns number of columns generated
function generate_pattern!(mp::MasterProblem; tolerance::Float64 = 1e-5)
	
	@assert mp.relax

	dual_values = dual.(mp.satisfy_demand)

	# Create subproblem
	sub_model = JuMP.Model(() -> Gurobi.Optimizer(env))
	set_silent(sub_model)
	n_pieces = mp.dat.n_pieces
	@variable(sub_model, count[1:n_pieces] >= 0, Int) # 
	@constraint(sub_model, 
		sum(mp.dat.pieces[pc].length*count[pc] for pc in 1:n_pieces) <= 
		mp.dat.max_length)
	@objective(sub_model,
		Max,
		sum(dual_values[pc]*count[pc] for pc in 1:n_pieces))

	# Solve subproblem
	optimize!(sub_model)	
	count_solution = round.(Int, value.(count))
	reduced_cost = 1 - objective_value(sub_model)

	# No column found with negative reduced cost
	if (sum(count_solution) == 0) || reduced_cost >= -abs(tolerance)
		return 0, reduced_cost
	end

	# Column found with negative reduced cost
	add_pattern!(dat, count_solution)
	return 1, reduced_cost

end
