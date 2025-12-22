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
Class definition of platform (actor and sensor motion).
%}

classdef Sensor < Platform
	properties
%         Position
%         Velocity
%         Heading
%         actualPath
%         expectedPath
%         currentEdge
%         totalExposure
%         isSensor	

		% Link to a grid world, threat, and sensor network
% 		ACEGridWorld_
%         threatModel_
%         sensorNetwork_

      edgeDistance
      c_path_integral
%       travelDiatance
       
	end

	methods
		%==================================================================
        function [obj, grid_, threat_] = Sensor(ID, speed, grid_, sensorNetwork_, threat_, sensor, time_step_)
            obj.actualPath = sensorNetwork_.configuration(ID);
            obj.Speed = speed;
%             threat_			   = threat_.dynamics_discrete(time_step_);
 
%             measurementz_k      = threat_.calculate_at_sensor_locations( ...
%                                   threat_.threatCoordinates(:, sensorNetwork_.configuration(ID))) ...                              
%                                   + sqrt(sensorNetwork_.noiseVariance) * (randn(sensorNetwork_.nSensors, 1) - 0.5);
            measurementz_k      = threat_.calculate_at_sensor_locations( ...
                                  sensorNetwork_.configuration(ID), threat_.state) ...                              
                                  + sqrt(sensorNetwork_.noiseVariance) * (randn(sensorNetwork_.nSensors, 1) - 0.5);
             measurementz_k      = [0 0];

%             measurementz_k       =  threat_.calculate_at_locations( ...
%                                           grid_.coordinates(:, sensorNetwork_.configuration(ID)) ) ...
%                                           + sqrt(sensorNetwork_.noiseVariance) * (randn( sensorNetwork_.nSensors, 1)-0.5);
    
            if ID==1
                sensorNetwork_.configuration = 40;
            else
                sensorNetwork_.configuration = 6;
            end
%              sensorNetwork_.configuration = 40;
            threat_              = threat_.estimate_state_UKF1(0, measurementz_k(ID), sensorNetwork_, grid_.optimalPath.loc);
            % threat_.stateEstimateHistory(:,1) = threat_.stateEstimateHistory(:,2);

             sensorNetwork_.configuration = [40,6];
%              sensorNetwork_.configuration = 40;

            grid_.threatModel    = threat_;
            grid_.sensorNetwork  = sensorNetwork_;
            grid_                = grid_.min_cost_path(threat_, grid_);
            optimalPath_         = grid_.optimalPath.loc;
            sensorNetwork_.threatModel  = threat_;
            sensorNetwork_.gridWorld    = grid_;
            
            sensorlocationslist = 1:length(sensorNetwork_.sensorConfigurationList(1,:));
            
            config = zeros(1,length(sensor));
            for i = 1:length(sensor)
                config(i) = sensor(i).currentEdge(2);
            end

            if isempty(sensor)
                sensorlocationslist(sensorNetwork_.configuration) = [];
            else
                sensorlocationslist(ismember(1:grid_.nPoints, [config, sensorNetwork_.configuration])) = [];
            end

%             sensorlocationslist
            sensorNetwork_.configuration = sensorNetwork_.configuration(ID);
%                 network             = sensorNetwork_.configure_SMI_greedy_cost(threat_, sensorlocationslist, grid_);
               network		         = sensorNetwork_.configure_greedy_cost(threat_, sensorlocationslist, grid_,optimalPath_);
%              network             = sensorNetwork_.configure_random( sensorlocationslist);
            x1 = threat_.threatCoordinates(1, obj.actualPath(end));
            x2 = threat_.threatCoordinates(1, sensorNetwork_.configuration);
            y1 = threat_.threatCoordinates(2, obj.actualPath(end));
            y2 = threat_.threatCoordinates(2, sensorNetwork_.configuration);
            obj.edgeDistance = sqrt((x2 -x1)^2 + (y2 -y1)^2);
            
            obj.currentEdge = [obj.actualPath, network.configuration];

            obj.Position = [x1,y1]';
            obj.Heading     = findHeading(obj, threat_.threatCoordinates);
            obj.Velocity    = [cos(obj.Heading);sin(obj.Heading)]*obj.Speed;
            obj.travelDistance = 0;
        end
 
        function [obj,grid_, threat_] = checkreachedVertex(obj, threat_, grid_, sensor, SENSOR_NOISE_VAR, sensorNetwork_,time_step_)

                if obj.travelDistance >= obj.edgeDistance       

                    obj.travelDistance = 0;
                    obj.actualPath       = [obj.actualPath, obj.currentEdge(2)];
%                     threat_			   = threat_.dynamics_discrete(time_step_);
%                     measurementz_k       =  threat_.calculate_at_locations( ...
%                                           grid_.coordinates(:, obj.currentEdge(2) )) ...
%                                           + sqrt(SENSOR_NOISE_VAR) * (randn(1)-0.5);
                    measurementz_k =     threat_.calculate_at_sensor_locations( ...
                                           obj.currentEdge(2)) ...
                                          + sqrt(SENSOR_NOISE_VAR) * (randn(1) - 0.5);
                    measurementz_k      = 0;
                    sensorNetwork_.configuration = obj.currentEdge(2);
                    
                    threat_              = threat_.estimate_state_UKF1(time_step_, measurementz_k, sensorNetwork_, grid_.optimalPath.loc);
        
                    grid_.threatModel    = threat_;
                    grid_.sensorNetwork  = sensorNetwork_;
                    grid_                = grid_.min_cost_path(threat_, grid_);
                    optimalPath_         = grid_.optimalPath.loc;
                    sensorNetwork_.threatModel  = threat_;
                    sensorNetwork_.gridWorld    = grid_;
                    
                    sensorlocationslist = 1:length(sensorNetwork_.sensorConfigurationList(1,:));
                    config = zeros(1,length(sensor));
                    for i = 1:length(sensor)
                        config(i) = sensor(i).currentEdge(2);
                    end
                    sensorlocationslist(ismember(1:grid_.nPoints, config)) = [];
                    
%                     sensorNetwork_.configuration = obj.actualPath(end);
%                           sensorNetwork_ = sensorNetwork_.configure_SMI_greedy_cost(threat_, sensorlocationslist, grid_);
                        sensorNetwork_ = sensorNetwork_.configure_greedy_cost(threat_, sensorlocationslist, grid_,optimalPath_);   
%                        sensorNetwork_            = sensorNetwork_.configure_random( sensorlocationslist);
                    x1 = threat_.threatCoordinates(1, obj.actualPath(end));
                    x2 = threat_.threatCoordinates(1, sensorNetwork_.configuration);
                    y1 = threat_.threatCoordinates(2, obj.actualPath(end));
                    y2 = threat_.threatCoordinates(2, sensorNetwork_.configuration);
                    obj.edgeDistance = sqrt((x2 -x1)^2 + (y2 -y1)^2);
                    
                    obj.currentEdge = [obj.actualPath(end), sensorNetwork_.configuration];

                else
                    threat_ = threat_.estimate_state_UKF1(time_step_, [], sensorNetwork_, grid_.optimalPath.loc);

                end
               
               
            end

      end
 end