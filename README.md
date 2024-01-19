# OptTeaching

Notebooks and code in [Julia](https://julialang.org/) for COMM 612.

## Setup

1. Download Gurobi with a [free academic license](https://www.gurobi.com/features/academic-named-user-license/).
2. Download [Julia](https://julialang.org/downloads/).
3. Open Julia. You will need [IJulia](https://github.com/JuliaLang/IJulia.jl) to open and run my notebooks. To install the IJulia package, run `Pkg.add("IJulia")`.
4. You will first need to set the `GUROBI_HOME` environment variable in Julia, as described in this [README](https://github.com/jump-dev/Gurobi.jl)). Then, install the [Gurobi](https://github.com/jump-dev/Gurobi.jl)) package by running `Pkg.add("Gurobi")`. If you have switched the order of these instructions, you may additionally need to run `Pkg.build("Gurobi")`. See this [thread](https://discourse.julialang.org/t/gurobi-failed-to-precompile/44606/10) for discussion. If you mess up your installation, try running `Pkg.rm("Gurobi")`, closing Julia, and starting over.
5. The other packages, including [JuMP](https://github.com/jump-dev/JuMP.jl), are installed similarly. Each notebook also includes package dependences in the header, which you should install before running the notebook.
6. Clone this repository and navigate to the directory containing the notebook that you want to run. Start Julia and run `using IJulia` and `notebook(dir = ".")`.

## Resources

* [Julia Documentation](https://docs.julialang.org/en/v1/)
* [Learn X in Y Minutes](https://learnxinyminutes.com/docs/julia/)
* [JuMP's Julia Tutorial](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/getting_started_with_julia/)

## Troubleshooting

Please report any issues so that I can expand this list.

- After you add the Gurobi package with `Pkg.add("Gurobi")`, IJulia may not be able to find your license at first (even after setting `ENV["GUROBI_HOME"]` as instructed [here](https://github.com/jump-dev/Gurobi.jl)). You may need to run `Pkg.build("Gurobi")`. You can also try restarting Julia and IJulia.
