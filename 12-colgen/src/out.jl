using Plots

# Stores the solution to the Cutting Stock Problem 
# and computational results
struct StockSolution
	dat::StockInstance
	rolls::Vector{Float64} 		# rolls[pt] of pattern pt were used in solution
	objective_value::Float64
	solve_time::Float64
	aux::Dict{Any, Any}
end 
Base.show(io::IO, solution::StockSolution) = print(io, "Cutting Stock Solution with objective $(solution.objective_value)")

# Solves the weak formulation
function solve!(wf::WeakFormulation)
	JuMP.optimize!(wf.model)
	return StockSolution(
		wf.dat, 
		Float64[],
		objective_value(wf.model),
		solve_time(wf.model),
		Dict())
end

# Solves with column generation
function solve!(mp::MasterProblem)

	# Column generation on LP relaxation
	if mp.relax

		objs = Float64[]
		rcs = Float64[]
		t0 = time()
		while true
			
			# Solve master problem
			JuMP.optimize!(mp.model)
			push!(objs, objective_value(mp.model))

			# Generate a column
			n_added, reduced_cost = generate_pattern!(mp)
			push!(rcs, reduced_cost)
			if n_added == 0
				break
			else
				mp = MasterProblem(dat)
			end

		end
		t = time() - t0

		aux = Dict()
		aux[:objectives] = objs
		aux[:reduced_costs] = rcs
		return StockSolution(
			mp.dat, 
			value.(mp.x),
			objective_value(mp.model),
			t, 
			aux)

	# Directly solve IP
	else
		JuMP.optimize!(mp.model)
		return StockSolution(
			mp.dat, 
			value.(mp.x), 
			objective_value(mp.model),
			solve_time(mp.model),
			Dict())
	end

end

"Plots the patterns used in the StockSolution"
function plot_patterns(solution::StockSolution)
	
	piece_colors = get_color_palette(:auto, solution.dat.n_pieces)

	# Private helper function to plot a rectangle of width x height at (x, y)
	rectangle(width, height, x, y) = Shape(x .+ [0, width, width, 0], y .+ [0, 0, height, height])

	# Plots each piece in each roll as an individual rectangle
	y = 0
	plt = Plots.plot()
	for pt in findall(solution.rolls .> 0)

		# Plot each roll cut in this pattern
		for roll in 1:solution.rolls[pt]

			# Plot the pieces in this pattern
			x = 0
			pat = solution.dat.patterns[pt]
			for pc in findall(pat.quantities .> 0)
				for q in 1:pat.quantities[pc]
					plot!(rectangle(pat.pieces[pc].length, 1, x, y), 
						fill=piece_colors[pc], lw=1; 
						legend = false)
					x += pat.pieces[pc].length
				end
			end

			y += 1

		end

	end
	xlabel!("Roll Width")
    ylabel!("Roll Number")
    title!("Cutting Stock Solution (Cost = $(round(Int, solution.objective_value)))")
	return plt
end
