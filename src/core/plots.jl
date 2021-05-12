using Distributions: quantile, pdf
using NamedDims: unname
using PlotlyJS: AbstractTrace, Layout, Plot, attr, scatter, surface

const RED = "#FF595E"
const GREEN = "#8AC926"
const BLUE = "#1982C4"
const YELLOW = "#FFB238"

const OPACITY = 0.1

"""
    sir_plot(data)

Plots an epidemic trajectory from the provided simulation data.

**Arguments**
- `data::SimulationData`: Stores the epidemic data generated by `simulate`.

**Keyword Arguments
- `show_susceptible::Bool=true`: Indicates whether the number of susceptible individuals is
    displayed.
- `show_exposed::Bool=true`: Indicates whether the number of exposed individuals is
    displayed.
- `show_infected::Bool=true`: Indicates whether the number of infected individuals is
    displayed.
- `show_recovered::Bool=true`: Indicates whether the number of recovered individuals is
    displayed.
- `show_trials::Bool=true`: Indicates whether the trajectories from individual trials are
    displayed.
"""
function sir_plot(
    data::SimulationData;
    show_susceptible::Bool=true,
    show_exposed::Bool=true,
    show_infected::Bool=true,
    show_recovered::Bool=true,
    show_trials::Bool=true
)
    traces::Vector{AbstractTrace} = []

    # Add the susceptible traces.
    times = (0:(size(data.susceptible, :time) - 1)) / HOURS_IN_DAY
    trials = size(data.susceptible, :trial)
    if show_susceptible && show_trials
        append!(traces, (scatter(
            x=times, y=data.susceptible[trial=trial], hoverinfo="skip", line_color=BLUE,
            mode="lines", name="Susceptible", opacity=OPACITY, showlegend=false
        ) for trial in 1:trials))
    end
    if show_susceptible
        push!(traces, scatter(
            x=times, y=vec(sum(data.susceptible, dims=:trial)) / trials, line_color=BLUE,
            mode="lines", name="Susceptible"
        ))
    end

    # Add the exposed traces.
    times = (0:(size(data.exposed, :time) - 1)) / HOURS_IN_DAY
    trials = size(data.exposed, :trial)
    if show_exposed && show_trials
        append!(traces, (scatter(
            x=times, y=data.exposed[trial=trial], hoverinfo="skip", line_color=YELLOW,
            mode="lines", name="Exposed", opacity=OPACITY, showlegend=false
        ) for trial in 1:trials))
    end
    if show_exposed
        push!(traces, scatter(
            x=times, y=vec(sum(data.exposed, dims=:trial)) / trials, line_color=YELLOW,
            mode="lines", name="Exposed"
        ))
    end

    # Add the infected traces.
    if show_infected && show_trials
        append!(traces, (scatter(
            x=times, y=data.infected[trial=trial], hoverinfo="skip", line_color=RED,
            mode="lines", opacity=OPACITY, showlegend=false
        ) for trial in 1:trials))
    end
    if show_infected
        push!(traces, scatter(
            x=times, y=vec(sum(data.infected, dims=:trial)) / trials, line_color=RED,
            mode="lines", name="Infected"
        ))
    end

    # Add the recovered traces.
    times = (0:(size(data.recovered, :time) - 1)) / HOURS_IN_DAY
    trials = size(data.recovered, :trial)
    if show_recovered && show_trials
        append!(traces, (scatter(
            x=times, y=data.recovered[trial=trial], hoverinfo="skip", line_color=GREEN,
            mode="lines", opacity=OPACITY, showlegend=false
        ) for trial in 1:trials))
    end
    if show_recovered
        push!(traces, scatter(
            x=times, y=vec(sum(data.recovered, dims=:trial)) / trials, line_color=GREEN,
            mode="lines", name="Recovered"
        ))
    end

    layout = Layout(
        title="Simulated Epidemic Trajectories",
        xaxis_title="Time (days)", yaxis_range=(0, data.population),
        yaxis_title="Population",
        legend=attr(x=1.0, y=1.0, xanchor="right", yanchor="top")
    )

    return Plot(traces, layout)
end

"""
    infection_probability_plot(strain)

Draws the infection probability function for the virus strain.

**Arguments**
- `strain::Strain`: The strain whose infection probability function is to be plotted.
"""
function infection_probability_plot(strain::Strain)
    x = range(0, stop=strain.radius, length=100)
    y = (x -> infection_probability(strain.strength, strain.radius, x)).(x)

    traces = [
        scatter(x=x, y=y, line_color=RED, mode="lines", name="Infection Probability")
    ]

    layout = Layout(
        title="Strand Transmission Probability",
        showlegend=false,
        xaxis_title="Distance (metres)",
        yaxis_title="Probability Density"
    )

    return Plot(traces, layout)
end

"""
    duration_plot(strain)

Draws the probability density function of the incubation and infection durations.

**Arguments**
- `strain::Strain`: The strain whose incubaton and infection durations are to be plotted.

**Keyword Arguments**
- `show_incubation::Bool`: Indicates whether to show the probability density function of
    the incubation duration.
- `show_infection::Bool`: Indicates whether to show the probability density function of
    the infection duration.
"""
function duration_plot(strain::Strain; show_incubation=true, show_infection=true)
    incubation = Gamma(
        strain.incubation_shape, strain.incubation_mean / strain.incubation_shape
    )
    infection = Gamma(
        strain.infection_shape, strain.infection_mean / strain.infection_shape
    )

    stop = max(
        quantile(incubation, 0.95) * show_incubation, 
        quantile(infection, 0.95) * show_infection
    )
    x = range(0, stop=stop, length=100)
    traces::Vector{AbstractTrace} = []

    if show_incubation
        push!(traces, scatter(
            x=x, y=pdf(incubation, x), line_color=YELLOW, mode="lines",
            name="Incubation"
        ))
    end

    if show_infection
        push!(traces, scatter(
            x=x, y=pdf(infection, x), line_color=RED, mode="lines",
            name="Infection"
        ))
    end

    layout = Layout(
        title="Strand Duration Probabilities",
        legend=attr(x=1.0, y=1.0, xanchor="right", yanchor="top"),
        showlegend=true,
        xaxis_title="Duration (hours)",
        yaxis_title="Probability Density"
    )

    return Plot(traces, layout)
end

const parameter_labels = Dict(
    :initial => "Initial Infection Chance",
    :strength => "Infection Strength",
    :radius => "Infection Radius (metres)",
    :duration_mean => "Infection Duration Mean (days)",
    :duration_shape => "Infection Duration Shape"
)

"""
    parametric_plot(data, dim)

Plots the total number of infections as a function of a single virus parameter.

**Arguments**
- `data::ParametricData`: Stores the epidemic data generated by `simulate`.
- `dim::Symbol`: The parameter to show on the x-axis.


    parametric_plot(data, dim1, dim2)

Plots the total number of infections as a function of a pair of virus parameters.

**Arguments**
- `data::ParametricData`: Stores the epidemic data generated by `simulate`.
- `dim1::Symbol`: The parameter to show on the x-axis.
- `dim2::Symbol`: The parameter to show on the y-axis.

The dimensions must be one of `:initial`, `:strength`, `:radius`, `:duration_mean`, or
`:duration_scale`. The keyword arguments control the parameters that do not appear on the
x-axis or y-axis.
"""
function parametric_plot(
    data::ParametricData,
    dim::Symbol;
    initial::Integer=1,
    strength::Integer=1,
    radius::Integer=1,
    duration_mean::Integer=1,
    duration_shape::Integer=1
)
    # Get the indices of the relevant data.
    initial = :initial == dim ? (:) : initial
    strength = :strength == dim ? (:) : strength
    radius = :radius == dim ? (:) : radius
    duration_mean = :duration_mean == dim ? (:) : duration_mean
    duration_shape = :duration_shape == dim ? (:) : duration_shape

    total = data.population .- data.susceptible[
        time=end, initial=initial, strength=strength, radius=radius,
        duration_mean=duration_mean, duration_shape=duration_shape
    ]

    trials = size(total, :trial)
    parameters = getfield(data.strains, dim)

    # Add the average trace.
    traces = [scatter(
        x=parameters, y=(sum(total, dims=:trial) / trials)[trial=1],
        line_color=GREEN, mode="lines"
    )]

    layout = Layout(
        xaxis_title=parameter_labels[dim], yaxis_range=(0, data.population),
        yaxis_title="Infected (Cumulative)"
    )

    return Plot(traces, layout)
end

function parametric_plot(
    data::ParametricData,
    dim1::Symbol,
    dim2::Symbol;
    initial::Integer=1,
    strength::Integer=1,
    radius::Integer=1,
    duration_mean::Integer=1,
    duration_shape::Integer=1
)
    # Get the indices of the relevant data.
    initial = :initial == dim1 || :initial == dim2 ? (:) : initial
    strength = :strength == dim1 || :strength == dim2 ? (:) : strength
    radius = :radius == dim1 || :radius == dim2 ? (:) : radius
    duration_mean = :duration_mean == dim1 || :duration_mean == dim2 ? (:) : duration_mean
    duration_shape = :duration_shape == dim1 || :duration_shape == dim2 ? (:) : duration_shape

    total = data.population .- data.susceptible[
        time=end, initial=initial, strength=strength, radius=radius,
        duration_mean=duration_mean, duration_shape=duration_shape
    ]

    trials = size(total, :trial)
    parameters1 = getfield(data.strains, dim1)
    parameters2 = getfield(data.strains, dim2)

    # Add the average trace.
    traces = [surface(
        x=parameters1, y=parameters2, z=(sum(total, dims=:trial) / trials)[trial=1],
        colorscale=[[0.0, BLUE], [1.0, GREEN]]
    )]

    layout = Layout(scene=attr(
        xaxis_title=parameter_labels[dim1], yaxis_title=parameter_labels[dim2],
        zazis_range=(0, data.population), zaxis_title="Infected (Cumulative)"
    ))

    return Plot(traces, layout)
end