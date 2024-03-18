using LKH

function solve_lkh(dat::TSPInstance)
	t0 = time()
	lkh_tour, lkh_len = LKH.solve_tsp(Matrix{Int}(dat.d))
	dt = time() - t0
	tour_edges = [(lkh_tour[k-1], lkh_tour[k]) for k in 2:length(lkh_tour)];
	push!(tour_edges, (lkh_tour[end], lkh_tour[1]))
	return TSPSolution(dat, tour_edges, lkh_len, dt)
end

function load_solution(mdl::TSPModel, solution::TSPSolution)
	for (i, j) in solution.edges
    	JuMP.set_start_value(mdl.x[i, j], 1)
	end
end
