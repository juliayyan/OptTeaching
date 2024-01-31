using JuMP
using Gurobi

# Contains the data, model and variables
struct ProductionModel
	dat::ProductionInstance					# Problem data
	model::JuMP.Model 						# Model data structure
	production::Vector{JuMP.VariableRef}	# How many units are produced per period
	do_produce::Vector{JuMP.VariableRef}	# Whether any units are produced in the period period
	inventory::Vector{JuMP.VariableRef}		# How many units are left at the end of the period
end
Base.show(io::IO, mdl::ProductionModel) = print(io, "Production Planning Model with $(mdl.dat.T) periods")

# Constructor for core model
function ProductionModel(dat::ProductionInstance; 
	optimizer = Gurobi.Optimizer, 
	silent = false)
	T = dat.T
	model = Model(optimizer)
	if silent
		JuMP.set_silent(model)
	end
	@variable(model, production[t=1:T] >= 0)
	@variable(model, do_produce[t=1:T], Bin)
	@variable(model, inventory[t=1:T] >= 0)
	@constraint(model, 
		[t=1:T], 
		production[t] <= sum(dat.demand)*do_produce[t])
	@constraint(model, 
		[t=1:T],
		inventory[t] == (t == 1 ? 0 : inventory[t-1]) + production[t] - dat.demand[t])
	@objective(model, Min, 
		dat.unit_cost*sum(production) + 
		dat.fixed_cost*sum(do_produce) + 
		dat.holding_cost*sum(inventory))
	return ProductionModel(dat, model, production, do_produce, inventory)
end

# Adds auxiliary variables and constraints for extended formulation
function extend_formulation!(mdl::ProductionModel)
	model = mdl.model
	T = mdl.dat.T
	@variable(model, production_for_future[t=1:T, t2=t:T] >= 0)
	@constraint(model, 
		[t=1:T],
		mdl.production[t] == sum(production_for_future[t, t2] for t2 in t:T))
	@constraint(model, 
		[t=1:T, t2=t:T],
		production_for_future[t, t2] <= mdl.dat.demand[t2]*mdl.do_produce[t])
	@constraint(model, 
		[t2=1:T],
		sum(production_for_future[t, t2] for t=1:t2) >= mdl.dat.demand[t2])
	return
end
