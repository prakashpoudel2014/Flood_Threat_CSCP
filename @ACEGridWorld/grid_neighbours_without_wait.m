%{
SOFTWARE LICENSE
----------------
Copyright (c) 2023 by 
	Raghvendra V Cowlagi

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
4-adjacency grid neighbours on a uniform grid. Time is updated but there
are no "waiting" neighbours.
%}

% function [nhbrIDs, nhbrCosts] = grid_neighbours_without_wait(obj, currentID, threat_, grid_)
% 
% 
% nhbrIDs		= [];
% nhbrCosts	= [];
% x = threat_.threatCoordinates(1,:);
% y = threat_.threatCoordinates(2,:);
% 
% % ID = number of spatial grid points * time samples elapsed + current grid
% % point number
% 
% pointInGrid = mod(currentID, obj.nPoints);
% if pointInGrid == 0, pointInGrid = obj.nPoints; end
% pointinTime = floor( (currentID - pointInGrid) / obj.nPoints );
% 
% if mod( pointInGrid, obj.nGridRow )
% 	% pointInGrid + 1 is a neighbour
% 	newNeighbour= (pointInGrid + 1) + obj.nPoints * (pointinTime + 1);
%     newCost		= 1 + threat_.compute_psi(x, y, grid_.coordinates(1, pointInGrid + 1), grid_.coordinates(2, pointInGrid + 1))* obj.threatModel.originalStateEstimate;
% 	nhbrIDs		= [nhbrIDs; newNeighbour];
% 	nhbrCosts	= [nhbrCosts; newCost];
%   
% end
% if mod( pointInGrid - 1, obj.nGridRow )
%     % pointInGrid - 1 is a neighbour
%  	newNeighbour= (pointInGrid - 1) + obj.nPoints * (pointinTime + 1);
%     newCost		= 1 + threat_.compute_psi(x, y, grid_.coordinates(1, pointInGrid - 1), grid_.coordinates(2, pointInGrid - 1))* obj.threatModel.originalStateEstimate;
% 	nhbrIDs		= [nhbrIDs; newNeighbour];
% 	nhbrCosts	= [nhbrCosts; newCost];
% end
% 
% if pointInGrid + obj.nGridRow <= obj.nPoints
% 	% pointInGrid + obj.nGridRow is a neighbour
%  	newNeighbour= (pointInGrid + obj.nGridRow) + obj.nPoints * (pointinTime + 1);
%     newCost		= 1 +threat_.compute_psi(x, y, grid_.coordinates(1, pointInGrid + obj.nGridRow), grid_.coordinates(2, pointInGrid + obj.nGridRow))* obj.threatModel.originalStateEstimate;
% 	nhbrIDs		= [nhbrIDs; newNeighbour];
% 	nhbrCosts	= [nhbrCosts; newCost];
% end
% 
% if pointInGrid - obj.nGridRow >= 1
% 	% pointInGrid - obj.nGridRow is a neighbour
%  	newNeighbour= (pointInGrid - obj.nGridRow) + obj.nPoints * (pointinTime + 1);
%     newCost		= 1 + threat_.compute_psi(x, y, grid_.coordinates(1, pointInGrid - obj.nGridRow), grid_.coordinates(2, pointInGrid - obj.nGridRow))* obj.threatModel.originalStateEstimate;
% 	nhbrIDs		= [nhbrIDs; newNeighbour];
% 	nhbrCosts	= [nhbrCosts; newCost];
% end
% 
% if pointInGrid == obj.searchSetup.locationGoal
% 	newNeighbour= obj.searchSetup.virtualGoalID;
% 	newCost		= 0;
% 	nhbrIDs		= [nhbrIDs; newNeighbour];
% 	nhbrCosts	= [nhbrCosts; newCost];
% end
% 
% 
% end

function [nhbrIDs, nhbrCosts] = grid_neighbours_without_wait(obj, currentID, threat_, grid_)

nhbrIDs     = [];
nhbrCosts   = [];

x = threat_.threatCoordinates(1,:);
y = threat_.threatCoordinates(2,:);

% Extract spatial index and time index
pointInGrid = mod(currentID, obj.nPoints);
if pointInGrid == 0
    pointInGrid = obj.nPoints;
end
pointinTime = floor((currentID - pointInGrid) / obj.nPoints);

% neighbors = indices m such that adjacency(pointInGrid, m) ≠ 0
spatialNbrs = find(obj.adjacency(pointInGrid, :) ~= 0);

for idx = 1:length(spatialNbrs)
    newPoint = spatialNbrs(idx);

    % Convert to time-expanded neighbor ID
    newNeighbour = newPoint + obj.nPoints * (pointinTime + 1);

    % ---------------------------------------------------
    % MOVEMENT COST automatically derived from adjacency
    % ---------------------------------------------------
    % 4-way neighbors have distance 1
    % 8-way neighbors have distance sqrt(2)
    p1 = grid_.coordinates(:, pointInGrid);
    p2 = grid_.coordinates(:, newPoint);

    moveCost = norm(p2 - p1);

    threatCost = threat_.compute_psi( x, y, grid_.coordinates(1,newPoint), grid_.coordinates(2,newPoint)) * obj.threatModel.originalState;

    % Total neighbor cost
    newCost =   0.2 * moveCost + 0.8 * threatCost;

    nhbrIDs   = [nhbrIDs;  newNeighbour];
    nhbrCosts = [nhbrCosts; newCost];
end

if pointInGrid == obj.searchSetup.locationGoal
    nhbrIDs   = [nhbrIDs;  obj.searchSetup.virtualGoalID];
    nhbrCosts = [nhbrCosts; 0];
end

end
