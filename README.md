# OptTeaching

Notebooks and code in [Julia](https://julialang.org/) for COMM 612.

## Setup

1. Download [Gurobi](https://www.gurobi.com/downloads/gurobi-software/). It's best to stick with the default settings and do a "standard installation".
2. To use Gurobi, you will need a [free academic license](https://www.gurobi.com/features/academic-named-user-license/). For this step, you will need to be on an academic network; it's easiest if you are physically at your school and on the university WiFi. Register for a [Gurobi account](https://portal.gurobi.com/iam/register/), log in to the [User Portal](https://portal.gurobi.com/iam/licenses/request/?type=academic), and genearte a *Named-User Academic* license. When you run the `grbgetkey` command, you will be asked "In which directory would you like to store the Gurobi license file?" I use the default, which is `/Users/my-username`.
3. Download [Julia](https://julialang.org/downloads/).
4. [Open Julia](https://docs.julialang.org/en/v1/stdlib/REPL/). In Julia, you will *first* need to set the `GUROBI_HOME` environment variable to wherever Gurobi was installed, as described in this [README](https://github.com/jump-dev/Gurobi.jl):
```julia
# On Windows, this might be
ENV["GUROBI_HOME"] = "C:\\Program Files\\gurobi1100\\win64"
# ... or perhaps ...
ENV["GUROBI_HOME"] = "C:\\gurobi1100\\win64"
# On Mac, this might be
ENV["GUROBI_HOME"] = "/Library/gurobi1100/mac64"
# ... or perhaps ...
ENV["GUROBI_HOME"] = "/Library/gurobi1100/macos_universal2"
```
5. Then, install the [Gurobi](https://github.com/jump-dev/Gurobi.jl) package in Julia by running the following:
```julia
import Pkg
Pkg.add("Gurobi")
```
6. Install the [JuMP](https://github.com/jump-dev/JuMP.jl) package in Julia by running `Pkg.add("JuMP")`.
7. Run the following code in Julia to test whether Gurobi is working properly.
```julia
using JuMP, Gurobi
model = JuMP.Model(Gurobi.Optimizer)
@variable(model, x >= 0)
@objective(model, Min, x)
optimize!(model)
```
7. You will need [IJulia](https://github.com/JuliaLang/IJulia.jl) to open and run my notebooks. To install the IJulia package, run `Pkg.add("IJulia")`. (Each notebook also includes package dependences in the header, which need to be installed before running the notebook.)
9. Either [download](https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives) or [clone](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) this repository and navigate to the directory containing the notebook that you want to run. Run the following in Julia: 
```julia
using IJulia
notebook(dir = ".")
``` 

## Resources

* [Julia Documentation](https://docs.julialang.org/en/v1/)
* [Learn X in Y Minutes](https://learnxinyminutes.com/docs/julia/)
* [JuMP's Julia Tutorial](https://jump.dev/JuMP.jl/stable/tutorials/getting_started/getting_started_with_julia/)

## Troubleshooting

Please report any issues so that I can expand this list.

- If you switched the order of the Gurobi instructions and tried to run `Pkg.add("Gurobi")` before setting `ENV["GUROBI_HOME"]` or before downloading the Gurobi Optimizer...
  - First, remove the `Gurobi.jl` package by running `Pkg.rm("Gurobi")`. Then, close Julia and start over, using the order of instructions as written in this README.
  - Alternatively, you could try to run `Pkg.build("Gurobi")`.
  - See this [thread](https://discourse.julialang.org/t/gurobi-failed-to-precompile/44606/10) for discussion. 
- If you can use Gurobi in the Julia [REPL](https://docs.julialang.org/en/v1/stdlib/REPL/) but not in IJulia, try restarting Julia and IJulia.
