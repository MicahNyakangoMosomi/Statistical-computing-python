using Random, Statistics
using Agents, Plots
using DataFrames # Added for robust handling of the run! output

# Set a random seed for reproducible simulations
Random.seed!(42)

# -----------------------------------------------------------------------------
# 2. AGENT DEFINITION
# -----------------------------------------------------------------------------

# Define the Agent type for the simulation.
# Note: Since we use GridSpace, the AbstractAgent is correct, but the model setup is crucial.
mutable struct Community <: AbstractAgent
    id::Int           # Unique identifier
    pos::Tuple{Int, Int} # Position on the 2D grid (our "geographic" space)
    intensity::Float64 # Current conflict intensity (0.0 to 1.0)
    vulnerability::Float64 # Inherent vulnerability to conflict (0.0 to 1.0)
end

# -----------------------------------------------------------------------------
# 4. AGENT AND MODEL STEP FUNCTIONS (Defined first for use in constructor)
# -----------------------------------------------------------------------------

"""
Logic for a single agent (community) in one time step (e.g., one month).
"""
function agent_step!(agent, model)
    # 1. Decay: Conflict intensity naturally fades over time
    agent.intensity -= DECAY_RATE * agent.intensity

    # 2. Diffusion: An agent's intensity is influenced by its neighbors
    neighbor_intensities = [n.intensity for n in nearby_agents(agent, model, 1)] # radius 1
    
    if !isempty(neighbor_intensities)
        # The agent's intensity increases based on the average intensity of its neighbors,
        # weighted by the agent's inherent vulnerability.
        avg_neighbor_intensity = mean(neighbor_intensities)
        
        # Conflict spreads only if the neighbor intensity is high enough AND the agent is vulnerable
        spread_amount = 0.1 * agent.vulnerability * (avg_neighbor_intensity - agent.intensity)
        agent.intensity += max(0.0, spread_amount) # Spread cannot be negative
    end

    # 3. Cap Intensity
    agent.intensity = clamp(agent.intensity, 0.0, 1.0)
    return
end

"""
Logic for the overall model in one time step.
(No global changes needed in this simple example)
"""
function model_step!(model)
    return
end


# -----------------------------------------------------------------------------
# 3. MODEL SETUP
# -----------------------------------------------------------------------------

# Define the parameters for the simulation
const N_AGENTS = 500  # Number of communities
const GRID_SIZE = 50  # 50x50 grid representing a region
const DECAY_RATE = 0.05 # How quickly conflict intensity fades per step
const INITIAL_SHOCK_RADIUS = 3 # Radius around the "election flashpoint"

"""
Initialize the ABM grid and agents.
"""
function initialize_model(; N=N_AGENTS, dims=(GRID_SIZE, GRID_SIZE), seed=42)
    space = GridSpace(dims, periodic = false)

    # CORRECTION 1 & 3: Define step functions and scheduler here, not in run!
    model = AgentBasedModel(
        Community, 
        space, 
        agent_step! = agent_step!, 
        model_step! = model_step!, 
        scheduler = :random # Modern, idiomatic way to use Schedulers.Randomly()
    )

    # 1. Add Communities (Agents)
    for i in 1:N
        # Agents start with random, low vulnerability
        vulnerability = rand() * 0.3
        # Use add_agent_single! to ensure agents are placed in unique, random positions
        add_agent_single!(Community(i, (1, 1), 0.0, vulnerability), model) 
    end

    # 2. Introduce the "Election Shock" (Initial condition)
    shock_center = (GRID_SIZE ÷ 2, GRID_SIZE ÷ 2)

    for agent in allagents(model)
        # Calculate distance from the shock center
        dist = sqrt((agent.pos[1] - shock_center[1])^2 + (agent.pos[2] - shock_center[2])^2)

        if dist < INITIAL_SHOCK_RADIUS
            # Communities near the flashpoint start with high conflict intensity
            agent.intensity = 0.8
        end
    end

    return model
end

# -----------------------------------------------------------------------------
# 5. SIMULATION EXECUTION AND VISUALIZATION
# -----------------------------------------------------------------------------

# Initialize the model
model = initialize_model()

# Define the data to collect at each step (the average conflict intensity across the region)
# CORRECTION 2: This is AGGREGATED AGENT DATA (adata), not model data (mdata).
data_to_collect = [(:intensity, mean)] 
n_steps = 50 # Simulate 50 time steps

println("Running Julia ABM Simulation for $n_steps steps...")

# Execute the simulation
# CORRECTION 3: Removed agent_step! and model_step! arguments
# CORRECTION 2: Changed mdata to adata
data, _ = run!(
    model, 
    n_steps; 
    adata=data_to_collect, 
    when = 1:n_steps
)

# -----------------------------------------------------------------------------
# 6. RESULTS AND BENCHMARKING (Julia's Speed Advantage)
# -----------------------------------------------------------------------------

# When using aggregation, the column name is generated automatically, e.g., "mean(intensity)"
mean_intensity = data[:, Symbol("mean(intensity)")] 
time_steps = data.step

plot_result = Plots.plot(
    time_steps, 
    mean_intensity, 
    xlabel="Time Step (e.g., Week/Month)", 
    ylabel="Average Conflict Intensity (0-1)",
    title="Conflict Diffusion Post-Election (Agent-Based Simulation)",
    label="Mean Intensity", 
    linewidth=3, 
    color=:red
)

Plots.display(plot_result)

println("\n--- Simulation Complete ---")
println("Final Average Conflict Intensity after $n_steps steps: $(round(mean_intensity[end], digits=4))")
println("This simulation demonstrates Julia's capability for high-performance agent-based modeling.")
println("The simulation time for this $N_AGENTS agent model is minimal due to Julia's speed.")

# You can save the figure using:
# Plots.savefig(plot_result, "conflict_diffusion_julia.png")