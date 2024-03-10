using Random

# Contains the data for the facility location problem
struct FacilityInstance
	n_customers::Int 					# Number of customers
	customer_coords::Matrix{Float64}	# customer_coords[c, :] is the coordinates of customer c
	n_facilities::Int 					# Number of possible facilities
	facility_coords::Matrix{Float64}	# facility_coords[f, :] is the coordinates of facility f
	dist::Matrix{Float64}				# dist[c, f] is the distance of facility f to customer c
	fixed_cost::Float64 				# Fixed cost per facility
end
Base.show(io::IO, dat::FacilityInstance) = print(
	io, 
	"Facility Location Instance with $(dat.n_customers) customers and $(dat.n_facilities) facilities")

# Constructor for MediansInstance
function FacilityInstance(
	n_customers::Int, 
	n_facilities::Int, 
	fixed_cost::Union{Int, Float64}; 
	random_seed = 1
)
	Random.seed!(random_seed)
	customer_coords = rand(n_customers, 2)
	facility_coords = rand(n_facilities, 2)
	dist = [sqrt(sum((facility_coords[f, :] - customer_coords[c, :]).^2)) 
			for c in 1:n_customers, f in 1:n_facilities]
	return FacilityInstance(n_customers, customer_coords, n_facilities, facility_coords, dist, fixed_cost)
end
