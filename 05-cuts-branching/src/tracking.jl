using Plots

# Adds a callback to TSPModel that tracks the solver's progress
function add_tracking_callback!(mdl::TSPModel)

    mdl.aux[:obj]       = Float64[]
    mdl.aux[:bound]     = Float64[]
    mdl.aux[:time]      = Float64[]

    # Gurobi-specific querying
    function bounds_callback(cb_data, cb_where)
        if cb_where == GRB_CB_MIP
            
            # Get objective and bound info
            obj = Ref{Cdouble}()            
            GRBcbget(cb_data, cb_where, GRB_CB_MIP_OBJBST, obj)
            bound = Ref{Cdouble}()
            GRBcbget(cb_data, cb_where, GRB_CB_MIP_OBJBND, bound)
                
            # If the information has meaningfully changed, save it
            if length(mdl.aux[:time]) == 0 || 
                !isapprox(obj[], mdl.aux[:obj][end]) || 
                !isapprox(bound[], mdl.aux[:bound][end])

                push!(mdl.aux[:obj], obj[])
                push!(mdl.aux[:bound], bound[])
                push!(mdl.aux[:time], time())

            end

        end
    end
    
    MOI.set(mdl.model, 
        Gurobi.CallbackFunction(),
        bounds_callback
    )
    return

end

function plot_progress(mdls::Vector{TSPModel}, labels::Vector{String})

    linestyles = [:solid, :dash, :dashdot]
    @assert length(mdls) <= length(linestyles)

    plt = Plots.plot() 

    for m in 1:length(mdls)

        mdl = mdls[m]
        lab = labels[m]

        # Plot objectives, filtering out junk where there was no incumbent solution
        t0 = mdl.aux[:time][1]
        idx = findall(mdl.aux[:obj] .< 1e100)
        Plots.plot!(
            mdl.aux[:time][idx] .- t0, 
            mdl.aux[:obj][idx], 
            label = "Objective (" * lab * ")",
            marker = :circle,
            markersize = 2,
            color = "forestgreen",
            linestyle = linestyles[m]
        )

        Plots.plot!(
            mdl.aux[:time] .- t0, 
            mdl.aux[:bound],
            label = "Bound (" * lab * ")",
            color = "darkblue",
            linestyle = linestyles[m]
        )
        xlabel!("Time (s)")
        ylabel!("Value")

    end

    return plt
end
