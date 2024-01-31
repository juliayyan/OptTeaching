using Random

# Contains the problem data for an instance of the (deterministic) production planning problem
struct ProductionInstance
	T::Int 						# Number of time periods
	unit_cost::Float64			# Cost per unit of production
	holding_cost::Float64		# Cost per unit held in inventory
	fixed_cost::Float64			# Cost for producing anything in a period
	demand::Vector{Float64}		# (Deterministic) demand per period
end
Base.show(io::IO, dat::ProductionInstance) = print(io, "Production Planning Instance with $(dat.T) periods")

# Constructor for ProductionInstance
function ProductionInstance(T::Int, unit_cost::Float64, holding_cost::Float64, fixed_cost::Float64; 
	random_seed::Int = 1, max_demand::Int = 50)
	Random.seed!(random_seed)
	demand = round.(Int, rand(T)*max_demand)
	return ProductionInstance(T, unit_cost, holding_cost, fixed_cost, demand)
end
