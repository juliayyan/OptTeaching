using Random

# Contains the problem data for an instance of the TSP
struct TSPInstance
	n::Int 									# Number of cities in the tour
	coords::Matrix{Union{Int, Float64}}		# coords[i, :] is the coordinates of city i
	d::Matrix{Union{Int, Float64}}			# d[i, j] is the distance from city i to city j
end
Base.show(io::IO, dat::TSPInstance) = print(io, "TSP Instance with $(dat.n) cities")

# Constructor for TSPInstance
function TSPInstance(n::Int; 
	random_seed = 1, 
	int::Bool = false 	# if generating integer data
)
	Random.seed!(random_seed)
	coords = rand(n, 2)
	d = [sqrt(sum((coords[i, :] - coords[j, :]).^2)) for i in 1:n, j in 1:n]
	if int
		d = round.(Int, d*100)
	end

	return TSPInstance(n, coords, d)
end
