using JuMP, Gurobi
using Random

env = Gurobi.Env()
optimizer = optimizer_with_attributes(() -> Gurobi.Optimizer(env), 
	"Presolve" => 0, 
	"Method" => 0, # 0 = primal simplex, 1 = dual simplex. Comment out this line for concurrent.
	"DisplayInterval" => 1,
	"TimeLimit" => 30)

# A matching problem

n = 2000
costs = rand(n, n)

model = Model(optimizer)
@variable(model, x[i=1:n, j=1:n] >= 0)
@constraint(model, [i=1:n], sum(x[i, :]) == 1)
@constraint(model, [j=1:n], sum(x[:, j]) == 1)
@objective(model, Min, sum(costs[i, j]*x[i, j] for i in 1:n, j in 1:n))
optimize!(model)
