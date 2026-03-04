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

classdef Actor < Platform
	properties
	
      edgeDistance
      totalExposure
      actorstateEstimate
      actorstateEstimateHistory
       
	end

	methods
		%==================================================================
        function [obj, grid_] = Actor(speed, grid_,threat_)
            x1 = grid_.coordinates(1, grid_.optimalPath.loc(1));
            x2 = grid_.coordinates(1, grid_.optimalPath.loc(2));
            y1 = grid_.coordinates(2, grid_.optimalPath.loc(1));
            y2 = grid_.coordinates(2, grid_.optimalPath.loc(2));
            obj.edgeDistance = sqrt((x2 -x1)^2 + (y2 -y1)^2);
            obj.actualPath = grid_.optimalPath.loc(1);
            obj.currentEdge = [grid_.optimalPath.loc(1), grid_.optimalPath.loc(2)];
            grid_.searchSetup.start	= grid_.optimalPath.loc(2);
            obj.Speed = speed;
            
            obj.totalExposure    = 0;
            
            obj.Position = [x1,y1]';
            obj.Heading     = findHeading(obj, grid_.coordinates);
            obj.Velocity    = [cos(obj.Heading);sin(obj.Heading)]*obj.Speed;
            obj.travelDistance = 0;
            obj.actorstateEstimate	 = zeros(threat_.nStates, 1);
            obj.actorstateEstimateHistory	 = obj.actorstateEstimate;
        end
            
             
           function obj = threatPath(obj, threat_)
			% Initialization
            priorLocation           = obj.Position(:,end-1);
            nextLocation            = obj.Position(:,end);
            intermediatePath_x      = linspace( priorLocation(1), nextLocation(1), 5);
            intermediatePath_y      = linspace( priorLocation(2), nextLocation(2), 5);
            intermediatePath        = [intermediatePath_x; intermediatePath_y];
            threat_intermediatePath = threat_.calculate_at_grid_location(intermediatePath);
            tempPath                = linspace( 0, 1 , 5);
            threatfit               = polyfit(tempPath, threat_intermediatePath, 4);
            integrated_polynomial   = polyint(threatfit);
            dist = sqrt((priorLocation(1)-nextLocation(1))^2+(priorLocation(2)-nextLocation(2))^2);
            c_path_integral         = (polyval(integrated_polynomial, 1) - polyval(integrated_polynomial, 0))/dist;
            
            obj.totalExposure       = obj.totalExposure + c_path_integral;
            end

            function [obj,grid_] = checkreachedVertex(obj, grid_, threat_)

                if obj.travelDistance >= obj.edgeDistance       
                    if length(grid_.optimalPath.loc)==1
                        obj.actualPath     =   [obj.actualPath, grid_.optimalPath.loc];
                        return
                    end
                    obj.travelDistance = 0;
                    x1 = grid_.coordinates(1, grid_.optimalPath.loc(1));
                    x2 = grid_.coordinates(1, grid_.optimalPath.loc(2));
                    y1 = grid_.coordinates(2, grid_.optimalPath.loc(1));
                    y2 = grid_.coordinates(2, grid_.optimalPath.loc(2));
                    obj.edgeDistance = sqrt((x2 -x1)^2 + (y2 -y1)^2);
                    obj.actualPath     =   [obj.actualPath, obj.currentEdge(2)];  
                    
                    if obj.currentEdge(1) == grid_.optimalPath.loc(1)
                        obj.expectedPath   =   grid_.optimalPath.loc(2:end);
                        grid_.searchSetup.start	= grid_.optimalPath.loc(3);
                        grid_.optimalPath.loc = grid_.optimalPath.loc(2:end);
                    else
                        obj.expectedPath   =   grid_.optimalPath.loc;
                        grid_.searchSetup.start	= grid_.optimalPath.loc(2);
                    end
                    obj.currentEdge = [obj.currentEdge(2), grid_.optimalPath.loc(2)];
                    grid_.optimalPath.loc = grid_.optimalPath.loc(2:end);
                    obj.actorstateEstimate = threat_.stateEstimate(:,end);
                    obj.actorstateEstimateHistory = [obj.actorstateEstimateHistory obj.actorstateEstimate];
                end
               
               
            end

      end

 end
