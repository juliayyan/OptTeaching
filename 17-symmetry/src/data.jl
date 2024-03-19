using Random

# Contains the problem data for an instance of the OpRoom
struct OpRoomInstance
	m::Int 						# Number of patients
    d::Int 						# Number of rooms
	time::Vector{Float64}		# time[p] is the time needed for patient p
    T::Int                      # The time horizon
end
Base.show(io::IO, dat::OpRoomInstance) = print(io, "Operating Room Instance with $(dat.m) patients and $(dat.d) operating rooms")

# Constructor for OpRoomInstance
function OpRoomInstance(m::Int,
        d::Int,
        T::Int;
        random_seed = 1)
	Random.seed!(random_seed)

    upper_bound = round.(Int, T*0.85)
	time = rand(1:upper_bound, m)

    return OpRoomInstance(m,d,time,T)
end
