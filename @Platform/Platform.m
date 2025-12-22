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
Class definition of platform (for actor and sensor motion).
%}

classdef Platform
	properties
        Position
        Speed
        Velocity
        Heading
        actualPath
        expectedPath
        currentEdge
        travelDistance

		% Link to a grid world, threat, and sensor network
		ACEGridWorld_
        threatModel_
        sensorNetwork_
       
	end

	methods
		%==================================================================
        function obj = movePlatform(obj, coordinates_, time_step_)
            obj.Heading          = [obj.Heading, findHeading(obj, coordinates_)];
            obj.Velocity		 = [obj.Velocity, [cos(obj.Heading);sin(obj.Heading)]*obj.Speed];
            obj.Position		 = [obj.Position, obj.Position(:,end) + obj.Velocity(:,end)*time_step_];
            obj.travelDistance   = obj.travelDistance + obj.Speed*time_step_;
              
        end

        function heading_     = findHeading(obj, coordinates_)
        
        heading_              = atan2(coordinates_(2, obj.currentEdge(2)) - coordinates_(2, obj.currentEdge(1)),...
                                coordinates_(1, obj.currentEdge(2)) - coordinates_(1, obj.currentEdge(1)));
		end
           

    end
 end