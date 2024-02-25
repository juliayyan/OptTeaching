using Random

#This is the same as Julia's Code, but everything is integer-valued. 
#We use the l_1 distance instead of l_2, and we use integer coordinates.
# Integer coordinates are used in the LKH code, so we adjust things here.

# Contains the problem data for an instance of the TSP
struct TSPInstanceInt
    n::Int                      # Number of cities in the tour
    coords::Matrix{Float64}     # coords[i, :] is the coordinates of city i
    d::Matrix{Int64}            # d[i, j] is the distance from city i to city j
end
Base.show(io::IO, dat::TSPInstanceInt) = print(io, "TSP Instance with $(dat.n) cities")

# Constructor for TSPInstance with l_1 distances and integer coordinates

function TSPInstanceInt(n::Int, max_dist::Int; random_seed = 1)
    Random.seed!(random_seed)
    coords = rand(0:max_dist,n, 2)
    d = [sum(abs.((coords[i, :] - coords[j, :]))) for i in 1:n, j in 1:n]
    
    return TSPInstanceInt(n, coords, d)
end
