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
Reconfiguration function in class definition of sensor network:
	* Grid locations
	* Placement with basis ID matching
	* Works with a threat model defined by ParametricThreat class
%}

function obj = configure_greedy_cost(obj,threat_,list, grid_, optimalPath)
    sensorCombination1   = list;
    numberCombination1       = length(list);
    currentMIList_array1          = zeros(numberCombination1,2);                 %[index, MI] 
    distance_array               = zeros(numberCombination1,2);             %[index, distance] 
    distance_array1 = distance_array;
    distance_array2 = distance_array;

    pathLength = length(optimalPath);
    ds         = zeros(1, pathLength); 
    for k = 2:pathLength
        p_prev = grid_.coordinates(:, optimalPath(k-1));
        p_k    = grid_.coordinates(:, optimalPath(k));
        ds(k)  = norm(p_k - p_prev);    % this is 1 for 4-way, sqrt(2) for diagonals
    end
    totalLength = sum(ds);              % total geometric length of the path
    
    for i = 1:numberCombination1
        possibleConfigurations1	= sensorCombination1(i);
        H = threat_.calc_observation_matrix(possibleConfigurations1);

        H_prime = H(:, 1:length(threat_.originalState));
        pNext = threat_.pNext;
        pNextHist = threat_.pNextHist;
        pReducedNext = threat_.pReducedNext;
        pReducedNextHist = threat_.pReducedNextHist;
        size(pNext);
        size(pNextHist);
        sumVec              = zeros(1, length(threat_.originalState));  
        sum1                = 0;                                        
        sum2                = 0;                                        
        obj.truepathCost    = 0;
        obj.estimatedpathCost = 0;
        x = threat_.threatCoordinates(1,:);
        y = threat_.threatCoordinates(2,:);

        % Single-index loop (per vertex)
        for k = 1:pathLength
            psi  = threat_.compute_psi( x, y, grid_.coordinates(1, optimalPath(:,k)),  grid_.coordinates(2, optimalPath(:,k)));
            Pk   = pReducedNextHist(:,:,k);
            sumVec  = sumVec  + ds(k) * psi * Pk;          % 1×n
            sum1    = sum1    + (ds(k)^2) * psi * Pk * psi';
            obj.truepathCost      = obj.truepathCost      + ds(k) * (psi * threat_.originalState);
            obj.estimatedpathCost = obj.estimatedpathCost + ds(k) * (psi * threat_.originalStateEstimate);
        end

        for ii = 1:pathLength-1
            for jj = 2:pathLength
                psi1 = threat_.compute_psi( x, y, grid_.coordinates(1, optimalPath(:,ii)), grid_.coordinates(2, optimalPath(:,ii)));
                psi2 = threat_.compute_psi( x, y, grid_.coordinates(1, optimalPath(:,jj)), grid_.coordinates(2, optimalPath(:,jj)));
                Pii = pReducedNextHist(:,:,ii);
                Pjj = pReducedNextHist(:,:,jj);
                sum2 = sum2 + ds(ii)*ds(jj) * psi1 * (Pii + Pjj) * psi2';
            end
        end

        tau             = sumVec * H_prime';           
        obj.varpathCost = (sum1 + 2*sum2);              
        Xi = H * pNext * H' + obj.noiseVariance;        
		
        obj.truepathCost      =  obj.truepathCost;
        obj.estimatedpathCost =  obj.estimatedpathCost;
        obj.pathRisk          =  obj.estimatedpathCost + sqrt(obj.varpathCost);

        %------------------------------------------------------------------
        % Mutual information between path cost and measurement
        %------------------------------------------------------------------
        currentmutualInformation = abs(real( ...
            0.5 * log( obj.varpathCost / ...
                      (obj.varpathCost - tau * pinv(Xi) * tau') )));

        % Store [sensor index, MI value]
        currentMIList_array1(i,1) = possibleConfigurations1;
        currentMIList_array1(i,2) = currentmutualInformation;

        %------------------------------------------------------------------
        % Distances for reconfiguration cost
        %------------------------------------------------------------------
        % (1) Distance from current sensor location to candidate location
        distance = norm( ...
            threat_.threatCoordinates(:, sensorCombination1(i)) - ...
            threat_.threatCoordinates(:, obj.configuration));
        distance_array1(i,1) = possibleConfigurations1;
        distance_array1(i,2) = distance;

        % (2) Distance from candidate sensor location to path start
        distance = norm( ...
            threat_.threatCoordinates(:, sensorCombination1(i)) - ...
            grid_.coordinates(:, grid_.optimalPath.loc(1)));
        distance_array2(i,1) = possibleConfigurations1;
        distance_array2(i,2) = distance;

        % Weighted combination of both distances
        distance_array = distance_array1;
        gamma = 1;               % same as before
        beta  = 1 - gamma;
        distance_array(:,2) = gamma*distance_array1(:,2) + beta*distance_array2(:,2);
    end

    %----------------------------------------------------------------------
    % Reconfiguration weighting 
    %----------------------------------------------------------------------
    alpha = max(currentMIList_array1(:, 2)) / ...
           (max(distance_array(:, 2)) - min(distance_array(:, 2)));
  %   alpha = 0;

    mod_MI      = currentMIList_array1;
    mod_MI(:,2) = mod_MI(:,2) + alpha * (min(distance_array(:, 2)) - distance_array(:, 2));

    [~, IND_]   = max(mod_MI(:,2));
    obj.configuration = mod_MI(IND_,1);

end
