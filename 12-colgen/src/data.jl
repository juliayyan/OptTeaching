# There is demand for pieces of certain lengths
struct Piece
	id::Int
	length::Int
end
Base.show(io::IO, piece::Piece) = print(io, "Piece of length $(piece.length)")

# Rolls can be cut into patterns comprised of different quantities of pieces
struct Pattern
	id::Int
	pieces::Vector{Piece}
	quantities::Vector{Int}
end
function Base.show(io::IO, pat::Pattern)
	print(io, "Pattern $(pat.id): ")
	for pc in findall(pat.quantities .> 0)
		print(io, pat.quantities[pc], "*", pat.pieces[pc].length, " ")
	end
end

# An instance of a Cutting Stock Problem includes the pieces, demand for pieces, and
# the max length of a roll.
# The patterns vector is initially empty
struct StockInstance
	pieces::Vector{Piece}
	demands::Vector{Int}
	max_length::Int
	patterns::Vector{Pattern}
	n_pieces::Int
end
Base.show(io::IO, dat::StockInstance) = print(io, "Cutting Stock Instance with $(dat.n_pieces) pieces")

# Constructor for the StockInstance
function StockInstance(
	piece_lengths::Vector{Int}, 
	piece_demands::Vector{Int},
	max_length::Int
)
	# Error checking
	@assert length(piece_lengths) == length(piece_demands)
	@assert minimum(piece_lengths) > 0
	@assert minimum(piece_demands) > 0

	# Data processing
	pieces = Piece[]
	demands = Int[]
	for pc in 1:length(piece_lengths)
		push!(pieces, Piece(pc, piece_lengths[pc]))
		push!(demands, piece_demands[pc])
	end
	patterns = Pattern[]
	return StockInstance(pieces, demands, max_length, patterns, length(pieces))

end

# Adds a pattern with the given pieces to dat
function add_pattern!(
	dat::StockInstance,
	piece_quantities::Vector{Int}
)
	# Error checking
	@assert length(piece_quantities) == dat.n_pieces
	@assert sum(piece_quantities) > 0
	pattern_length = sum(dat.pieces[pc].length*piece_quantities[pc] for pc in 1:dat.n_pieces)
	@assert pattern_length <= dat.max_length

	# Add pattern to dat
	pat = Pattern(length(dat.patterns)+1, dat.pieces, piece_quantities)
	println("Adding ", pat)
	push!(dat.patterns, pat)
	return
end

# Adds simple possible patterns to dat: 
# For a given piece, as many pieces as can be cut from a roll
function add_elementary_patterns!(dat::StockInstance)
	for pc=1:dat.n_pieces
		q = zeros(Int, dat.n_pieces)
		q[pc] = floor(Int, dat.max_length/dat.pieces[pc].length)
		add_pattern!(dat, q)
	end
end
