# Stores OpRoom solution and computational results
struct OpRoomSolution
	dat::OpRoomInstance
	objective_value::Float64
	solve_time::Float64
end
Base.show(io::IO, solution::OpRoomSolution) = print(io, "OR Solution with $(dat.m) patients and $(dat.d) operating rooms")

# Optimizes the model and returns the OpRoomSolution
function solve!(mod::OpRoomModel)
	JuMP.optimize!(mod.model)
	if termination_status(mod.model) == TIME_LIMIT && !has_values(mod.model)
		return Nothing
	end
	return OpRoomSolution(
		mod.dat, 
		JuMP.objective_value(mod.model),
		JuMP.solve_time(mod.model))
end