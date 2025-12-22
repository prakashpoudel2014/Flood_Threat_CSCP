%{
SOFTWARE LICENSE
----------------
Copyright (c) 2023 by
	Prakash Poudel
	Raghvendra V. Cowlagi

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
An implementation of the Unscented Kalman Filter to estimate threat.
%}

function obj = estimate_state_UKF1(obj, time_step_, measurementz_k, sensors_, optimalPath)
% 	estimate_state(stateEstimatex_km1, covarPxx_km1, measurementz_k, ...
% 	stateModel, measurementModel, ESTIMATOR_PARAMETERS)

%{
INPUTS
------

The "_km1" subscript indicates (k-1). This file uses the convention of
(k-1) for current and k for next.

OUTPUTS
-------
* stateEstimatex_k: new state estimate (updaated in the threat object)
* covarPxx_k: new estimtion error covariance (updaated in the threat object)

%}

obj.pathLength = length(optimalPath);

t_	= obj.timeStampEstimate(end);
controlu_k = obj.input(:,length(obj.timeStampEstimate));
stateEstimatex_km1	= obj.stateEstimate;
covarPxx_km1		= obj.estimateCovarPxx;

%----- UKF scaling and weight parameters
ESTIMATOR_PARAMETERS.alpha	= 1E-3;						% default, tunable
ESTIMATOR_PARAMETERS.beta	= 2;						% default, tunable
ESTIMATOR_PARAMETERS.kappa	= 0;						% default, tunable
%----- For readability
alpha_ = ESTIMATOR_PARAMETERS.alpha;
beta_  = ESTIMATOR_PARAMETERS.beta;
kappa_ = ESTIMATOR_PARAMETERS.kappa;

%----- Dimensions
nState		= obj.nStates;									% Number of states
nProcNoise	= size(obj.noiseCovarQ, 1);						% Number of noise states
if isempty(sensors_)
    activeSensor = [];
    nMeasNoise = 0;
else
    activeSensor = 1;   % choose sensor (replace with greedy selection logic if needed)
    nMeasNoise = 1;
end

nAugState	= nState + nProcNoise + nMeasNoise;				% Dimension of augmented state
nSigmaPoints= 2 * nAugState + 1;							% Number of sigma points

%----- Noise statistics
processCovarQ	= obj.noiseCovarQ;
if ~isempty(activeSensor)
    measNoiseCovarR	= sensors_.noiseVariance(activeSensor);
else
    measNoiseCovarR = [];
end

%----- UKF sigma point weights
lambda_		= alpha_ ^2 * (nAugState + kappa_) - nAugState;
gamma_		= sqrt(nAugState + lambda_);
weightW_m0	= lambda_ / (nAugState + lambda_);
weightW_c0	= weightW_m0 + 1 - alpha_^2 + beta_;
weightW_i	= 1/(2*(nAugState + lambda_));

%----- Create augmented system (states, process noise, measurement noise)
augState_km1= [stateEstimatex_km1; zeros(nProcNoise, 1); zeros(nMeasNoise, 1)];
augCovarP	= blkdiag(covarPxx_km1, processCovarQ, measNoiseCovarR);

%----- Generate sigma points
sigmaPointsVec_km1 = sigma_points(augState_km1, augCovarP);

%----- Intermediate calculations
Z_kkm1	= zeros(nMeasNoise, nSigmaPoints);

Xx_kkm1	= zeros(nState, nSigmaPoints);
for sp = 1:nSigmaPoints
    Xx_kkm1(:, sp) = obj.process_model( ...
		sigmaPointsVec_km1(1:nState, sp), controlu_k,...
        sigmaPointsVec_km1(nState+1:nState+nProcNoise, sp));

	 if ~isempty(activeSensor)
        Z_kkm1(:, sp) =  obj.measurement_model( ...
            Xx_kkm1(:, sp), sigmaPointsVec_km1(nState + nProcNoise + activeSensor, sp), sensors_(activeSensor) );  
     else
        Z_kkm1(:, sp) = 0;
     end     
end

%----- Predict
% Expected prediction and measurement
predx_kkm1	= weightW_m0 * Xx_kkm1(:, 1) + ...
	weightW_i * sum(Xx_kkm1(:, 2:end), 2);
measz_kkm1	= weightW_m0 * Z_kkm1(:, 1) + ...
	weightW_i * sum(Z_kkm1(:, 2:end), 2);

% Remove expectations from X_x_kkm1 and Z_kkm1.
Xx_kkm1 = bsxfun(@minus, Xx_kkm1, predx_kkm1);
Z_kkm1	= bsxfun(@minus, Z_kkm1, measz_kkm1);
    
% Calculate covariance of the prediction.
P_kkm1	= (weightW_c0 * Xx_kkm1(:, 1)) * Xx_kkm1(:, 1).' + ...
	weightW_i * (Xx_kkm1(:, 2:end) * Xx_kkm1(:, 2:end).');
obj.priorCovariance = P_kkm1;  
% Covariance of predicted observation and predicted state
if ~isempty(activeSensor)
    Pzz	= (weightW_c0 * Z_kkm1(:, 1)) * Z_kkm1(:, 1).' + weightW_i * (Z_kkm1(:, 2:end) * Z_kkm1(:, 2:end).');
    Pxz	= (weightW_c0 * Xx_kkm1(:, 1)) * Z_kkm1(:, 1).' + weightW_i * (Xx_kkm1(:, 2:end) * Z_kkm1(:, 2:end).');
else
    Pzz = 1;
    Pxz = zeros(nState,1);
end

%----- Return if no measurement available

if isempty(measurementz_k)
	obj.stateEstimate	 = predx_kkm1;
	obj.estimateCovarPxx = P_kkm1;
	return
end

%----- Kalman gain (if measurement available)
KalmanGain =  Pxz * pinv(Pzz);

%----- Correct (if measurement available)
obj.stateEstimate	 = predx_kkm1 + KalmanGain * (measurementz_k - measz_kkm1);
obj.stateEstimate(obj.stateEstimate < 0) = 0;
% obj.stateEstimate = obj.normalizedStateEstimate;
% n_points = length(obj.zMin);
% obj.stateEstimate(1:n_points) = obj.normalizedStateEstimate(1:n_points) .* obj.zRange' + obj.zMin';
obj.estimateCovarPxx = P_kkm1 - KalmanGain * Pzz * KalmanGain.';
obj.originalStateEstimate = obj.stateEstimate(1:length(obj.originalState));
obj.estimateError = (norm(obj.originalState) - norm(obj.originalStateEstimate))/norm(obj.originalState);

%----- Trace of error covariance
obj.traceCovarPxx = trace(obj.estimateCovarPxx);

%----- Calculate mutual information between the state and measurement
% obj.mutualinformation = 0.5 * log(det(P_kkm1)/(det(P_kkm1 - Pxz * pinv(Pzz) * Pxz')));

%----- Update object histories
obj.stateEstimateHistory	 = [obj.stateEstimateHistory		obj.stateEstimate];
obj.estimateCovarPxxHistory	 = [obj.estimateCovarPxxHistory 	reshape(obj.estimateCovarPxx, obj.nStates^2, 1)];
obj.traceCovarPxxHistory	 = [obj.traceCovarPxxHistory	obj.traceCovarPxx];
obj.estimateErrorHistory	 = [obj.estimateErrorHistory		obj.estimateError];
obj.timeStampEstimate		 = [obj.timeStampEstimate		t_ + time_step_];

% =================================================================
% Propagate prediction for one more step

stateEstimatex_k  = obj.stateEstimate;
covarPxx_k        = obj.estimateCovarPxx;

for pathNode = 1:obj.pathLength

%----- Create augmented system for next iteration(states, process noise, measurement noise)
    augState_k= [stateEstimatex_k; zeros(nProcNoise, 1); zeros(nMeasNoise, 1)];
    augCovarP_k	= blkdiag(covarPxx_k, processCovarQ, measNoiseCovarR);

%----- Generate sigma points
    sigmaPointsVec_k = sigma_points(augState_k, augCovarP_k);


    Xx_kk	= zeros(nState, nSigmaPoints);
    for sp_next = 1:nSigmaPoints
        Xx_kk(:, sp_next) = obj.process_model( ...
		    sigmaPointsVec_k(1:nState, sp_next), controlu_k,...
            sigmaPointsVec_k(nState+1:nState+nProcNoise, sp_next));    
    end
    
    
    %----- Predict
    % Expected prediction and measurement
    predx_kk	= weightW_m0 * Xx_kk(:, 1) + ...
	    weightW_i * sum(Xx_kk(:, 2:end), 2);
    
    % Remove expectations from X_x_kkm1.
    Xx_kkm1_next = bsxfun(@minus, Xx_kk, predx_kk);
        
    % Calculate covariance of the prediction.
    Pkk	= (weightW_c0 * Xx_kkm1_next(:, 1)) * Xx_kkm1_next(:, 1).' + ...
	    weightW_i * (Xx_kkm1_next(:, 2:end) * Xx_kkm1_next(:, 2:end).');
    
%     obj.pNext = Pkk;  
    obj.pNextHist(:, :, pathNode) = Pkk;
    obj.pNext =  obj.pNextHist(:, :, pathNode);
    obj.pReducedNext = obj.pNext(1:length(obj.originalState), 1:length(obj.originalState));
    obj.pReducedNextHist(:, :, pathNode) = Pkk(1:length(obj.originalState), 1:length(obj.originalState));
    stateEstimatex_k  =  predx_kk;
    covarPxx_k        =  Pkk;
end

	%========= SIGMA POINT CALCULATOR =====================================
	function X_a_km1 = sigma_points(x_a_km1, P_a)
		[u, s] = svd(P_a);

		gamma_sqrt_P_a = gamma_ * u * sqrt(s);
		X_a_km1 = [x_a_km1, ...
			repmat(x_a_km1, 1, nAugState) + gamma_sqrt_P_a, ...
			repmat(x_a_km1, 1, nAugState) - gamma_sqrt_P_a];
	end
	%----------------------------------------------------------------------

end