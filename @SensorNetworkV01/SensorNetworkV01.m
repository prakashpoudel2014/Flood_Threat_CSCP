%{
SOFTWARE LICENSE
----------------
Copyright (c) 2023 by 
	Raghvendra V Cowlagi
	Bejamin Cooper
	Prakash Poudel

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
Class definition of sensor network:
	* Grid locations
	* Placement with basis ID matching
	* Works with a threat model defined by ParametricThreat class

*** AT SOME POINT WE NEED TO FIGURE OUT HOW TO MAKE THIS MORE GENERAL,
E.G., MOST ATTRIBUTES ARE COMMON, ONLY THE SENSOR PLACEMENT/CONFIGURATION
TECHNIQUE WILL DIFFER ***
%}

classdef SensorNetworkV01
	properties
		nSensors
		noiseVariance

		configuration	= [];	% sensor grid locations
		configHistory	= [];	% grid location history
        allConf_MI = []; % stores all possible configurations
        sensorConfigurationList=[];   % list of all states locations in a grid in x,y catersian system
        truepathCost;
        pathLength;
        truepathCostHistory = [];
        estimatedpathCost;
        estimatedpathCostHistory = [];
        varpathCost;
        varpathCostHistory = [];
        sensorCost;
        sensorCostHistory = [];
        pathRisk;
        pathRiskHistory = [];
		identifiedBasis	= [];
        MI;
        MIHistory=[];
		gridWorld		= [];
		threatModel		= [];
        
		% do not use ".threatState" because threatModel is set at
		% initialization and not updated later
	end

	methods
		%==================================================================
		function obj = SensorNetworkV01(nSensors_, noiseVariance_, ...
				threatModel_, gridWorld_, initLocOnGrid)
			% Initialization, including first configuration

            obj.truepathCost = 0;
            obj.truepathCostHistory = [];
            obj.estimatedpathCost = 0;
            obj.estimatedpathCostHistory = [];

			% Set number of sensors
			obj.nSensors		= nSensors_;
			obj.gridWorld		= gridWorld_;
			obj.noiseVariance	= noiseVariance_;
			obj.threatModel		= threatModel_;
            
			
			obj.configuration	= initLocOnGrid;
			obj.configHistory	= initLocOnGrid;
            gaugeNumber         = (1:length(obj.threatModel.threatCoordinates))';
            obj.sensorConfigurationList = [gaugeNumber'; obj.threatModel.threatCoordinates];
		end
		%------------------------------------------------------------------

		%==================================================================
		obj = configure_SMI_greedy_cost(obj,threat_, grid_, optimalPath, timestep)
		% Sensor configuration implemented in a different file
		%------------------------------------------------------------------

        %==================================================================
		obj = configure_CRMI(obj,threat_,grid_, optimalPath_, timestep)
		% Sensor configuration implemented in a different file
		%------------------------------------------------------------------

        %==================================================================
		obj = configure_greedy(obj,threat_, grid_, optimalPath, timestep)
		% Sensor configuration implemented in a different file
		%------------------------------------------------------------------

        %==================================================================
		obj = configure_CRMI_cost(obj,threat_, grid_, optimalPath, timestep)
		% Sensor configuration implemented in a different file
		%------------------------------------------------------------------

%         %==================================================================
% 		obj = configure_greedy_cost(obj,threat_, grid_, optimalPath, timestep)
%         % Sensor configuration implemented in a different file
% 		%------------------------------------------------------------------
        
%         %==================================================================
% 		obj = configure_random(obj,threat_, grid_, optimalPath, timestep)
%         % Sensor configuration implemented in a different file
% 		%------------------------------------------------------------------

        %==================================================================
		obj = MI_optimization(obj,threat_, grid_, optimalPath, timestep)
		% MI optimizataion implemented in a different file
		%------------------------------------------------------------------

        %==================================================================
		obj = plotCost_(obj, flags_)
		% State and estimate plots in a different file
		%------------------------------------------------------------------
	end
end

