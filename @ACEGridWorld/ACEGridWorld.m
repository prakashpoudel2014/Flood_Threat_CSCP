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
Class definition of grid world, including optimal (minimum threat) planning.
	* Uniform spacing
	* 4-adjacency
	* Works with ParametricThreat class to get threat costs
%}

classdef ACEGridWorld
	properties
		halfWorkspaceSize	% half of square workspace edge size
		nPoints				% number of grid points in xy space, t is different
        nPointsList         % 1D array of gridpoints
		nGridRow			% number of grid points in each xy row
		spacing				% xy spacing

		coordinates			% xy coordinates, t is different
		adjacency			% xy adjacency matrix

		optimalPath
%         pathLength
		pathCost
		pathRisk
        varpathCost
		searchSetup
		searchOutcome		% label, backpointer, etc
		nTimeSteps
		threatModel
        sensorNetwork
	end

	methods
		%==================================================================
		function obj = ACEGridWorld(halfWorkspaceSize_, nGridRow_)
			% Initialization

			obj.halfWorkspaceSize	= halfWorkspaceSize_;
			obj.nGridRow			= nGridRow_;

			obj.nPoints				= nGridRow_ ^ 2;
            obj.nPointsList         = 1:obj.nPoints;
			obj.spacing				= 2*halfWorkspaceSize_ / (nGridRow_ - 1);

			obj.coordinates	= zeros(2, obj.nPoints);
			for m1 = 0:(obj.nPoints - 1)	
				obj.coordinates(:, m1 + 1) = [...
					-halfWorkspaceSize_ + (mod(m1, nGridRow_)) * obj.spacing; ...
					-halfWorkspaceSize_ + floor(m1 / nGridRow_) * obj.spacing];
			end

% 			% Setup adjacency matrix
% 			nEdges		= 0;
% 			nExpEdges	= obj.nPoints * 4;
% 			edgeList	= zeros(nExpEdges, 3);
% 			for m1 = 1:obj.nPoints
% 				if (m1 + 1 <= obj.nPoints) && (mod(m1, nGridRow_) ~= 0)
% 					nEdges				= nEdges + 1;
% 					edgeList(nEdges, :) = [m1 (m1 + 1) 1];
% 					nEdges				= nEdges + 1;
% 					edgeList(nEdges, :) = [(m1 + 1) m1 1];
% 				end
% 			
% 				if (m1 + nGridRow_) <= obj.nPoints
% 					nEdges				= nEdges + 1;
% 					edgeList(nEdges, :) = [m1 (m1 + nGridRow_) 1];
% 					nEdges				= nEdges + 1;
% 					edgeList(nEdges, :) = [(m1 + nGridRow_) m1 1];
% 				end
% 			end
% 			obj.adjacency = sparse(edgeList(1:nEdges, 1), ...
% 				edgeList(1:nEdges, 2), edgeList(1:nEdges, 3));
            
            % Setup adjacency matrix (8-way connectivity)
            nEdges     = 0;
            nExpEdges  = obj.nPoints * 8;   % enough for 8 neighbors per node
            edgeList   = zeros(nExpEdges, 3);
            
            for m1 = 1:obj.nPoints
                
                row = floor((m1-1)/nGridRow_) + 1;   % row index
                col = mod((m1-1), nGridRow_) + 1;    % column index
            
                % 8 neighbor offsets (dr, dc)
                nbrs = [
                    0  1;    % right
                    0 -1;    % left
                    1  0;    % up
                   -1  0;    % down
                    1  1;    % up-right
                    1 -1;    % up-left
                   -1  1;    % down-right
                   -1 -1     % down-left
                ];
            
                for k = 1:8
                    r2 = row + nbrs(k,1);
                    c2 = col + nbrs(k,2);
            
                    % Check if neighbor is inside map
                    if (r2 >= 1) && (r2 <= nGridRow_) && ...
                       (c2 >= 1) && (c2 <= nGridRow_)
            
                        m2 = (r2-1)*nGridRow_ + c2;   % convert back to linear index
            
                        % Assign weights
                        if abs(nbrs(k,1)) + abs(nbrs(k,2)) == 1
                            w = 1;         % horizontal/vertical neighbor
                        else
                            w = sqrt(2);   % diagonal neighbor
                        end
            
                        % Add edge
                        nEdges = nEdges + 1;
                        edgeList(nEdges,:) = [m1 m2 w];
                    end
                end
            end

            % Build sparse adjacency matrix
            obj.adjacency = sparse(edgeList(1:nEdges,1), ...
                                   edgeList(1:nEdges,2), ...
                                   edgeList(1:nEdges,3));



            obj.optimalPath = [];
% 			obj.optimalPath = [1:nGridRow_,2*nGridRow_:nGridRow_:obj.nPoints];
			obj.pathCost	= Inf;
			obj.pathRisk	= Inf;
% 
% 			obj.searchSetup.start			= obj.nGridRow;
% 			obj.searchSetup.locationGoal	= obj.nPoints -(obj.nGridRow -1);
%             obj.searchSetup.start			= 1;
% 			obj.searchSetup.locationGoal	= obj.nPoints;
            obj.searchSetup.start			= (obj.nGridRow *obj.nGridRow - 5 *obj.nGridRow) - 6 ;
			obj.searchSetup.locationGoal	= (obj.nGridRow *2 ) - 6;
%             obj.searchSetup.start			= (obj.nGridRow *obj.nGridRow - 9 *obj.nGridRow) - 3 ;
% 			obj.searchSetup.locationGoal	= (obj.nGridRow *2 ) - 10;
			obj.searchSetup.virtualGoalID	= 0;
            obj.nTimeSteps = 10;
			obj.threatModel = [];
            obj.sensorNetwork = [];
        end
		%------------------------------------------------------------------
		%==================================================================
        obj = min_cost_path(obj,threat_, grid_);
		% Path optimization function in a separate file
		%------------------------------------------------------------------
        
		%==================================================================
		function [nhbrIDs, nhbrCosts] = find_neighbours(obj, currentID, threat_, grid_)
			   [nhbrIDs, nhbrCosts] = grid_neighbours_without_wait(obj, currentID,threat_, grid_);
		end
		
		%==================================================================
		isGoalClosed = goal_check_locationanytime(obj)
		% Neighbour discovery function in a separate file
		%------------------------------------------------------------------
        
        plot_grid_elements(obj, threat_, grid_, sensor_, flags_)
        % Plot gridspace function in a separate file
		%------------------------------------------------------------------

        plot_parametric(obj, threat_, grid_, sensor_, flags_)
        % Plot grid and path function in a separate file
		%------------------------------------------------------------------

	end
end