#=================================================
https://chat.openai.com/share/ebb73a5a-db00-4f11-b2dc-71a0e6a112ce
=================================================#

using JuMP
using Gurobi

function solve_tsp(distances)
    num_cities = size(distances, 1)

    # Create a model
    model = Model(Gurobi.Optimizer)

    # Binary variable x[i, j] is 1 if the salesman goes from city i to city j
    @variable(model, x[1:num_cities, 1:num_cities], Bin)

    # Objective: minimize the total distance
    @objective(model, Min, sum(distances[i, j] * x[i, j] for i in 1:num_cities, j in 1:num_cities))

    # Constraints: each city must be visited exactly once
    @constraint(model, outgoing[i in 1:num_cities], sum(x[i, j] for j in 1:num_cities) == 1)
    @constraint(model, incoming[j in 1:num_cities], sum(x[i, j] for i in 1:num_cities) == 1)

    # Subtour elimination constraints
    @constraint(model, subtour[i in 2:num_cities, j in 2:num_cities], sum(x[k, j] for k in 1:i-1) + sum(x[i, k] for k in i+1:num_cities) >= 1)

    # Solve the TSP
    optimize!(model)

    # Extract the solution
    solution = value.(x)

    # Find the tour
    tour = find_tour(solution)

    return tour
end

function find_tour(solution)
    num_cities = size(solution, 1)

    # Find the starting city (where the tour begins)
    start_city = findfirst(x -> x == 1, sum(solution, dims=2))

    tour = [start_city]

    current_city = start_city
    while true
        # Find the next city in the tour
        next_city = findfirst(x -> x == 1, solution[current_city, :])

        # Break the loop if we return to the starting city
        if next_city == start_city
            break
        end

        push!(tour, next_city)
        current_city = next_city
    end

    return tour
end

# Example distances matrix
distances = [
    0  10 15 20;
    10  0 35 25;
    15 35  0 30;
    20 25 30  0;
]

tour = solve_tsp(distances)

println("Optimal TSP Tour: ", tour)

#=================================================

Gurobi Optimizer version 10.0.0 build v10.0.0rc2 (mac64[arm])

CPU model: Apple M1 Pro
Thread count: 10 physical cores, 10 logical processors, using up to 10 threads

Optimize a model with 17 rows, 16 columns and 59 nonzeros
Model fingerprint: 0x275419cc
Variable types: 0 continuous, 16 integer (16 binary)
Coefficient statistics:
  Matrix range     [1e+00, 1e+00]
  Objective range  [1e+01, 4e+01]
  Bounds range     [0e+00, 0e+00]
  RHS range        [1e+00, 1e+00]
Found heuristic solution: objective 95.0000000
Presolve removed 17 rows and 16 columns
Presolve time: 0.00s
Presolve: All rows and columns removed

Explored 0 nodes (0 simplex iterations) in 0.01 seconds (0.00 work units)
Thread count was 1 (of 10 available processors)

Solution count 1: 95 

Optimal solution found (tolerance 1.00e-04)
Best objective 9.500000000000e+01, best bound 9.500000000000e+01, gap 0.0000%

User-callback calls 336, time in user-callback 0.00 sec
ERROR: LoadError: MethodError: Cannot `convert` an object of type Nothing to an object of type CartesianIndex{2}
Closest candidates are:
  convert(::Type{T}, ::T) where T at Base.jl:61
Stacktrace:
 [1] push!(a::Vector{CartesianIndex{2}}, item::Nothing)
   @ Base ./array.jl:1057
 [2] find_tour(solution::Matrix{Float64})
   @ Main ~/Library/CloudStorage/Dropbox/UBC/Teaching/COMM 612/Demos/Lecture 1 - Intro/01a-tsp-genai.jl:53
 [3] solve_tsp(distances::Matrix{Int64})
   @ Main ~/Library/CloudStorage/Dropbox/UBC/Teaching/COMM 612/Demos/Lecture 1 - Intro/01a-tsp-genai.jl:30
 [4] top-level scope
   @ ~/Library/CloudStorage/Dropbox/UBC/Teaching/COMM 612/Demos/Lecture 1 - Intro/01a-tsp-genai.jl:68
 [5] include(fname::String)
   @ Base.MainInclude ./client.jl:476
 [6] top-level scope
   @ REPL[1]:1
in expression starting at /Users/juliayan/Library/CloudStorage/Dropbox/UBC/Teaching/COMM 612/Demos/Lecture 1 - Intro/01a-tsp-genai.jl:68

=================================================#

#=================================================
Issues:
- This code doesn't even run! There's a bug in find_tour().
- Was the model implemented correctly? From the Gurobi log, the optimal solution has objective value 95.
  Inspecting `value.(x)`, we have the tour 1-2-3-4-1, which has cost 10 + 35 + 30 + 20 = 95.
- But the optimal tour is actually 3-1-2-4-3, which has cost 15 + 10 + 25 + 30 = 80
- What happened? The subtour elimination constraints are nonsensical: they enforce that the tour visits nodes
  in lexicographical order.
- Don't trust generative AI to write research code for you.
=================================================#
