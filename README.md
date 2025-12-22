# Flood_Threat_CSCP
Flood_Threat_CSCP implements an actively coupled sensing and planning (CSCP) framework for flood-threat navigation. The framework models spatiotemporal flood threat dynamics using a Koopman operator–based linear representation, enabling data-driven prediction of evolving flood risk. Sensor placement is optimized by maximizing a novel context relevant mutual information (CRMI) measure that ensures information-rich observations, while path planning and sensor reconfiguration are performed simultaneously. The approach supports uncertainty-aware navigation in large-scale flood environments.

#Description of each folder#
**@ACEGridWorld**

Defines the grid world with uniform spacing and 8-adjacency connectivity.

Implements Dijkstra’s algorithm to compute minimum-cost paths.

Provides visualizations of the workspace, including true and estimated threat fields, planned paths.

Interacts with: FloodThreat class to obtain threat-related costs, SensorNetworkV01 class to determine optimal sensor placements

**@FloodThreat**

Defines the flood threat field using the Koopam method. The flood data is obtained from real flooding scenario (2017 Hurricane Harvey Flood).

Implements an Unscented Kalman Filter (UKF) to estimate the evolving threat.

Provides plotting tools for true and estimated threats.

Interacts with: ACEGridWorld to define threat cost at grid locations.

**@SensorNetworkV01**

Defines the sensor network model.

Implements sensor placement strategies, including greedy selection based on Mutual Information (MI).

Interacts with: FloodThreat to receive threat estimate, ACEGridWorld to account for path-dependent sensing.

**@Platform**

Base class defining motion primitives for mobile agents.

Encapsulates shared properties such as position, velocity, heading, and trajectory history.

Provides a common interface for both actors and sensors.

**@Sensor**

Implements mobile sensor behavior derived from Platform.

Executes active sensing, collecting measurements along its path.

Triggers UKF-based threat updates upon reaching grid vertices.

Coordinates with:

SensorNetworkV01 for adaptive sensor placement.

ACEGridWorld for updated threat-aware path planning.

**@Actor**

Represents the primary navigating agent (e.g., vehicle).

Plans paths using minimum expected threat exposure.

Moves simultaneously with sensors, adapting to updated threat estimates.

Interacts with:

ACEGridWorld for path planning

FloodThreat for threat-aware cost evaluation

**cscp_v03**

Main driver script to run the ACSCP algorithm.

Initializes: Grid world, Threat field, Sensor network, Sensor and Actor classes.

Performs iterative updates of: Threat variables (via UKF), Sensor locations (via MI-based greedy algorithm).

Executes path planning using updated threat estimates.

Allows user customization of: Sensor configuration schemes and number of sensors.
