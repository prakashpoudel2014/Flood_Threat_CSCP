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

function obj = configure_SMI_greedy_cost(obj, threat_, list, grid_)

    sensorCombination1 = list;
    numberCombination1 = length(list);

    currentMIList_array1 = zeros(numberCombination1,2);  %[index, MI] 
    distance_array       = zeros(numberCombination1,2);
    distance_array1      = distance_array;
    distance_array2      = distance_array;

    % ---- helper: log(det(M)) for symmetric PD matrix ----
    function ld = logdet_pd(M)
        M = (M + M')/2;     % ensure symmetry
        [R,p] = chol(M);

        if p > 0
            % fallback eigen-based
            lam = eig(M);
            lam = max(lam, eps);
            ld = sum(log(lam));
        else
            ld = 2 * sum(log(diag(R)));
        end
    end
    % -----------------------------------------------------

    for i = 1:numberCombination1

        possibleConfigurations1 = sensorCombination1(i);

        H    = threat_.calc_observation_matrix(possibleConfigurations1);
        pNext = threat_.priorCovariance;

        tau  = pNext * H';
        Xi   = H * pNext * H' + obj.noiseVariance;   % scalar or 1x1 matrix

        % ---- old (unstable) ----
        % MI = abs(real(0.5 * log(det(pNext)/(det(pNext - tau * pinv(Xi) * tau')))));

        % ---- new (stable) ----
        M_post = pNext - tau * (1./Xi) * tau';    % posterior covariance
        logdet_prior = logdet_pd(pNext);
        logdet_post  = logdet_pd(M_post);

        currentmutualInformation = abs(real(0.5 * (logdet_prior - logdet_post)));

        % Store MI
        currentMIList_array1(i,1) = possibleConfigurations1;
        currentMIList_array1(i,2) = currentmutualInformation;
        
        % ---- distance to current sensor location ----
        distance = norm( ...
            threat_.threatCoordinates(:, sensorCombination1(i)) - ...
            threat_.threatCoordinates(:, obj.configuration) );

        distance_array1(i,1) = possibleConfigurations1;
        distance_array1(i,2) = distance;

        % ---- distance to next actor location ----
        distance = norm( ...
            threat_.threatCoordinates(:, sensorCombination1(i)) - ...
            grid_.coordinates(:, grid_.optimalPath.loc(1)) );

        distance_array2(i,1) = possibleConfigurations1;
        distance_array2(i,2) = distance;

        % ---- Weighted distance ----
        gamma = 1;
        beta  = 1 - gamma;

        distance_array(i,1) = possibleConfigurations1;
        distance_array(:,2) = gamma*distance_array1(:,2) + beta*distance_array2(:,2);

    end
	
    alpha = max(currentMIList_array1(:,2)) / ...
            (max(distance_array(:,2)) - min(distance_array(:,2)));
    %   alpha = 0;
    mod_MI = currentMIList_array1;
    mod_MI(:,2) = mod_MI(:,2) + alpha * (min(distance_array(:,2)) - distance_array(:,2));

    [~, IND_] = max(mod_MI(:,2));

    obj.configuration = mod_MI(IND_,1);

end

