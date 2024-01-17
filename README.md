# OptTeaching

Notebooks and code in [Julia](https://julialang.org/) for COMM 612.

## Setup

1. Install [Julia](https://julialang.org/downloads/).
2. Install Gurobi with a [free academic license](https://www.gurobi.com/features/academic-named-user-license/).
3. You will need [IJulia](https://github.com/JuliaLang/IJulia.jl) to open and run my notebooks. Each notebook also includes package dependences in the header (e.g., [JuMP](https://github.com/jump-dev/JuMP.jl) and [Gurobi](https://github.com/jump-dev/Gurobi.jl)), which you should install before running the notebook. Check out the READMEs in each link if you have any issues.

## Troubleshooting

Please report any issues so that I can expand this list.

- After you add the Gurobi package with `Pkg.add("Gurobi")`, IJulia may not be able to find your license at first (even after setting `ENV["GUROBI_HOME"]` as instructed [here](https://github.com/jump-dev/Gurobi.jl)). Whenever IJulia can't find the Gurobi license, I just shut down IJulia, close Julia, and try again, and that has worked for me.
  
