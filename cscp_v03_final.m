%{
SOFTWARE LICENSE
----------------
Copyright (c) 2023 by Raghvendra V. Cowlagi

Permission is hereby granted to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in
the Software, including the rights to use, copy, modify, merge, copies of
the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:  

* The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
* The Software, and its copies or modifications, may not be distributed,
published, or sold for profit. 
* The Software, and any substantial portion thereof, may not be copied or
modified for commercial or for-profit use.

The software is provided "as is", without warranty of any kind, express or
implied, including but not limited to the warranties of merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising
from, out of or in connection with the software or the use or other
dealings in the software.      


PROGRAM DESCRIPTION
-------------------
A modular implementation of active coupled sensor configuration and 
planning (ACSCP).
%}


%% Tabula Rasa
clear variables; close all; clc

rng(42);

% addpath(genpath('CSCP-Classes'))

%% Initialize

%----- Time and iteration counters
% Time counter: there can be multiple and possibly variable time steps per
% iteration
time_k	= 0;	
k		= 0;	% Iteration counter
time_step_		= 0.5; % time step interval for main loop (10 Hz)

%----- Problem dimensions			
N_SENSORS		= 2;

N_GRID_ROW		= 25;
% SENSOR_INIT_CONFIG = [2*N_GRID_ROW+1, 3]; % start sensors next to actor
 SENSOR_INIT_CONFIG = [40, 6];
%  SENSOR_INIT_CONFIG = 40;
%----- Other
SENSOR_NOISE_VAR = 0.001;	% Variance of (i.i.d.) measurement noise in each sensor, assuming homogeneous sensors
SENSOR_SPEED = 0.02; % distance/timestep
ACTOR_SPEED = 0.01; % distance/timestep

% Data
data       = readtable('Flood_Height_Data_meters.xlsx');
input_data = readtable('normalized_rainfall_data.xlsx');


%----- Instantiate sensor, sensornetwork, actor, grid and threat classes
grid_			= ACEGridWorld(1, N_GRID_ROW);
threat_			= FloodThreat( grid_, data, input_data);

sensorNetwork_  = SensorNetworkV01(N_SENSORS, ...
	             SENSOR_NOISE_VAR, threat_, grid_, SENSOR_INIT_CONFIG);

grid_.threatModel = threat_;
grid_.sensorNetwork = sensorNetwork_;
grid_ = grid_.min_cost_path(threat_, grid_);

sensor_ = Sensor.empty;
for i = 1:N_SENSORS
    ID_ = i;
    [sensor_(i), grid_, threat_]= Sensor(ID_, SENSOR_SPEED, grid_, sensorNetwork_, threat_, sensor_, time_step_);
end

[actor_, grid_] = Actor(ACTOR_SPEED, grid_, threat_);



%% Active CSCP Loop
tic
index = [2 8 15 21];
%  index = [15 16 17 18 19 20 21];
previousPathLength = 0;  % Initialize a variable to track previous path length
plotTriggered = false(size(index));  % Logical array to track which indices have been plotted
while not(actor_.actualPath(end) == (grid_.nGridRow *2 ) - 6)
    %----- Increment time counter
    k      = k + 1;
    time_k = time_k + time_step_;
    threat_			  = threat_.dynamics_discrete(time_step_);
    %----- Move sensors and update the threat estimate when appropriate
    for i = 1:N_SENSORS
        sensor_(i) = sensor_(i).movePlatform(threat_.threatCoordinates, time_step_);
        [sensor_(i), grid_, threat_] = sensor_(i).checkreachedVertex(threat_, grid_, sensor_, SENSOR_NOISE_VAR, sensorNetwork_, time_step_); % threat_.timeStampState(end)
    end
    %----- Move actor and update the total exposure
    actor_ = actor_.movePlatform(grid_.coordinates, time_step_);
    actor_ = actor_.threatPath(threat_);
    [actor_, grid_] = actor_.checkreachedVertex(grid_, threat_);

    %----- Get the current path length
    currentPathLength = length(actor_.actualPath);

    %----- Check if the path length matches an index and hasn't been plotted yet
    idxMatch = find(index == currentPathLength, 1);  % Check if the current path length is in the index

    if ~isempty(idxMatch) && ~plotTriggered(idxMatch)
        flags_.SHOW_TRUE    = true;
        flags_.SHOW_ESTIMATE = false;
        flags_.DUAL_SCREEN  = false;
        flags_.JUXTAPOSE    = true;
        flags_.SHOW_PATH     = true;
        flags_.SHOW_SENSOR_LOCATION  = true;
        % Plot when the condition is met
        grid_.plot_parametric(threat_, sensor_, actor_, flags_);
        % Mark the index as plotted
        plotTriggered(idxMatch) = true;
    end

    % Update previous path length
    previousPathLength = currentPathLength;
end
toc




%% Plot results
actor_.totalExposure 
relError = threat_.estimateErrorHistory;
figure
plot(grid_.coordinates(1, :), grid_.coordinates(2, :),'.', 'Color', 'k', 'MarkerSize', 12); hold on
plot(actor_.Position(1,:), actor_.Position(2,:), 'r--','LineWidth',1.5) % Red dashed line for actor's position
hold on
plot(threat_.threatCoordinates(1, sensor_(1).actualPath), threat_.threatCoordinates(2, sensor_(1).actualPath), 'bo', 'MarkerSize', 12) 
plot(threat_.threatCoordinates(1, sensor_(2).actualPath), threat_.threatCoordinates(2, sensor_(2).actualPath), 'mv', 'MarkerSize', 12) 
legend({'Grid Points', 'Actor Path', 'Sensor 1', 'Sensor 2'}, ...
    'FontName', 'Times New Roman', 'FontSize', 15, 'Location', 'best');
text(grid_.coordinates(1, 494)+0.02, grid_.coordinates(2, 494)+0.08, 'S', 'FontName', 'Times New Roman', ...
	'FontSize', 20, 'Color', 'r');
text(grid_.coordinates(1, 44)-.12, grid_.coordinates(2, 44)-.08, 'G', 'FontName', 'Times New Roman', ...
	'FontSize', 20, 'Color', 'r');
plot(0.4, -0.70, 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');  % Blue circle for Sensor 1
text(0.5, -0.70, 'Sensor 1', 'FontSize', 18, 'FontName', 'Times New Roman', 'Color', 'k');

plot(0.4, -0.85, 'mv', 'MarkerSize', 10, 'MarkerFaceColor', 'm');  % Magenta circle for Sensor 2
text(0.5, -0.85, 'Sensor 2', 'FontSize', 18, 'FontName', 'Times New Roman', 'Color', 'k');
xlim([-1,1]);
ylim([-1,1]);
axis equal tight;
ax = gca;
ax.FontName = 'Times New Roman';
ax.FontSize = 16;
% Export the figure with 300 dpi
filename = 'sensorPath_alpha1_gamma1.png';
exportgraphics(ax, filename, 'Resolution', 300);   
figure
plot(1:length(relError), relError, '-o', 'LineWidth', 1.5);
xlabel('Sensor iterations');
ylabel('Estimation error');
title('Relative error over sensor iterations');


% flags_.SHOW_TRUE	 = true;
% flags_.SHOW_ESTIMATE = true;
% threatStatePlotAxes  = threat_.plot_(grid_, flags_);
% flags_.SHOW_TRUE	 = true;
% flags_.SHOW_ESTIMATE = false;
% flags_.DUAL_SCREEN	 = false;
% flags_.JUXTAPOSE	 = true;
% flags_.SHOW_PATH     = true;
% flags_.SHOW_SENSOR_LOCATION  = true;
% grid_.plot_parametric(threat_, sensorNetwork_, flags_)
% grid_.plot_grid_elements(threat_,grid_, sensorNetwork_, flags_)
% 
% flags_.SHOW_TRUECOST	 = true;
% flags_.SHOW_ESTIMATECOST = true;
% pathCostPlotAxes  = sensorNetwork_.plotCost_(flags_);

