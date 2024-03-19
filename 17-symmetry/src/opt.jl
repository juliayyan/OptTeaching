using JuMP
using Gurobi
using Combinatorics

# Auxiliary data keys
SOLN_KEY = "solution"
SUBTOUR_KEY = "subtour"

# Contains the data, model and edge variables
struct OpRoomModel
	dat::OpRoomInstance		# Problem data
	model::JuMP.Model 		# Model data structure
	x::Matrix{VariableRef}	# Patient variables
	aux::Dict{Any, Any}		# Optional; Stores auxiliary model data (used for DFJ subtours)
end
Base.show(io::IO, mdl::OpRoomModel) = print(io, "Operating Room Instance with $(dat.m) patients and $(dat.d) operating rooms")

# Constructor for core TSP model with degree constraints
function OpRoomModel(dat::OpRoomInstance; 
	optimizer = Gurobi.Optimizer, 
	silent = false)
	m = dat.m
	d = dat.d
    time = dat.time
    T = dat.T
    
	model = Model(optimizer)
	if silent
		JuMP.set_silent(model)
	end
	@variable(model, x[1:m, 1:d], Bin) # x[p, r] = 1 if patient p is assigned to room r
	@objective(model, Max, sum(sum(time .* x[:, r]) for r in 1:d))
	@constraint(model, patient[p in 1:m], sum(x[p, :]) <= 1)
	@constraint(model, ORcapacity[r in 1:d], sum(time .* x[:, r]) <= T)
    
	return OpRoomModel(dat, model, x, Dict())
end


# Adds the Denton et al. constraints to the model
function add_denton_constraints!(mdl::OpRoomModel)
	m = dat.m
	d = dat.d
    x = mdl.x

    @constraint(mdl.model, [r in 1:d,p in 1:(r-1)],  x[p,r] == 0)
    @constraint(mdl.model, [r in 2:d,p in r:m],  x[p,r] <= sum(x[pp,r-1] for pp in 1:(p-1)))
	return
end
