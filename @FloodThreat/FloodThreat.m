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
Class definition of parametric threat.
%}

classdef FloodThreat
	properties
		nStates				% Number of parameters (states)
        originalState
		% For a time-varying threat, the threatState property should be updated
		% at every time step by the "dynamics_discrete" method 
		state               % X
        input               % u
        floodHeight
        normalizedState
        zRange
        zMin
        threatCoordinates  =[];    % (x,y) in catersian coordinates normalized between [-1,1]
        originalStateEstimate
		stateEstimate		% mean state estimate
        estimateError
        estimateErrorHistory
        normalizedStateEstimate
		estimateCovarPxx	% estimation error covariance
        traceCovarPxx       % trace of error covariance
        pNext                % covariance prediction for next step
        pNextHist            % covariance prediction for all path_length iterations
        pReducedNext        % reduced covariance prediction for next step
        pReducedNextHist    % reduced covariance prediction for all path_length iterations
        pathLength
        priorCovariance
		
		% Maintain histories of state and stateEstimate evolution
		stateHistory
		stateEstimateHistory		% mean state estimate
		estimateCovarPxxHistory		% estimation error covariance
        traceCovarPxxHistory        % trace of error covariance
        
  
		% Maintain time stamps of state and estimate
		timeStampState
		timeStampEstimate

		% Process noise
		noiseCovarQ

		% Link to a grid world
		ACEGridWorld_

        % State transition matrix and input matrix
        A
        B
       
	end

	methods
		%==================================================================
        function obj = FloodThreat(grid_,data_,input_data_)		
%             Convert to numeric if data_ is a cell array
            if iscell(data_)
                data_ = cell2mat(data_);
            elseif istable(data_)
                data_ = table2array(data_);
            end

            x_or       = data_(1,:);
            y_or       = data_(2,:);
            z_all_raw  = data_(600:1400,:);

            % Normalize spatial coordinates to [-1, 1]
            x_ = 2 * (x_or - min(x_or)) / (max(x_or) - min(x_or)) - 1;
            y_ = 2 * (y_or - min(y_or)) / (max(y_or) - min(y_or)) - 1;
            x_ = x_(:); 
            y_ = y_(:);
            obj.threatCoordinates = [x_,y_]';
            
            n_points = numel(x_);
            n_times  = size(z_all_raw,1);
            z_   = z_all_raw;
            obj.floodHeight = z_;
			
            % Input rainfall            
            if iscell(input_data_)
                input_data_ = cell2mat(input_data_);
            elseif istable(input_data_)
                input_data_ = table2array(input_data_);
            end
            u_      = input_data_(600:1400,:)';   % [n_inputs x n_times]
            % Match time steps
            n_times = min(n_times, size(u_,2));
            z_   = z_(1:n_times,:);
            u_  = u_(:,1:n_times);
            
            obj.input = u_;
            %  Construct Observables (no control here; control enters DMDc)
            n_features   = 7;
            observables  = zeros(n_points, n_features, n_times);
            t_norm_vec   = (1:n_times)' / n_times;
                for t = 1:n_times
                    z_t = z_(t,:)'; % snapshot
                    observables(:,:,t) = [ ...
                        z_t, ...
                        z_t.^2, ...
                        x_ .* z_t, ...
                        y_ .* z_t, ...
                        sin(x_), ...
                        cos(y_), ...
                        t_norm_vec(t) * ones(n_points,1) ...
                    ];
                end
				
            %  Snapshot Matrices
            X       = reshape(observables(:,:,1:end-1), [], n_times-1);   % [n_obs x (T-1)]
            Y       = reshape(observables(:,:,2:end),   [], n_times-1);   % [n_obs x (T-1)]
            Upsilon = u_(:,1:end-1);                                   % [n_inputs x (T-1)]
            n_obs = size(X,1);
        
            %  Extended DMD
            Omega = [X; Upsilon];
        
            % SVD of Ω
            [U_t, S_t, V_t] = svd(Omega,'econ');
            r_t = min([20, rank(Omega), size(U_t,2)]);
            U_t = U_t(:,1:r_t);
            S_t = S_t(1:r_t,1:r_t);
            V_t = V_t(:,1:r_t);
        
            % Partition U_t
            U1 = U_t(1:n_obs,     :);   % state part
            U2 = U_t(n_obs+1:end, :);   % input part
        
            % SVD of Y
            [U_hat, S_hat, V_hat] = svd(Y,'econ');
            r_hat = min([20, rank(Y), size(U_hat,2)]);
            U_hat = U_hat(:,1:r_hat);
            S_hat = S_hat(1:r_hat,1:r_hat);
            V_hat = V_hat(:,1:r_hat);
        
            % Reduced A~, B~
            A_tilde = U_hat' * Y * V_t / S_t * (U1') * U_hat;
            B_tilde = U_hat' * Y * V_t / S_t * (U2');
        
            % Full Koopman operators
            A = U_hat * A_tilde * U_hat';   % [n_obs x n_obs]
            B = U_hat * B_tilde;            % [n_obs x n_inputs]
            obj.A = A;
            obj.B = B;
            obj.state       =  X(:,1);
            obj.nStates = length(obj.state);
            obj.originalState  = obj.state(1:n_points);
			obj.noiseCovarQ = 0.001*diag( ones(obj.nStates	, 1) );
			obj.ACEGridWorld_  = grid_;
			obj.stateEstimate	 = zeros(obj.nStates, 1);
            obj.originalStateEstimate	 = obj.stateEstimate(1:n_points);
 			obj.estimateCovarPxx = 1 * eye(obj.nStates);
            obj.traceCovarPxx    = zeros(1,1);

			obj.stateHistory			 = obj.state;
			obj.stateEstimateHistory	 = obj.stateEstimate;
            obj.estimateErrorHistory	 = (norm(obj.originalState) - norm(obj.originalStateEstimate))/norm(obj.originalState);
			obj.estimateCovarPxxHistory  = reshape(obj.estimateCovarPxx, obj.nStates	^2, 1);
            obj.traceCovarPxxHistory     = obj.traceCovarPxx;

			obj.timeStampState			= 0;
			obj.timeStampEstimate		= 0;
            obj.pNext                   = 1 * eye(obj.nStates	,obj.nStates);
            obj.pReducedNext            = obj.pNext(1:length(obj.originalState), 1:length(obj.originalState));
            obj.pNextHist               = repmat(1 * eye(obj.nStates),1,1,obj.ACEGridWorld_.nGridRow^2-1);
            obj.pReducedNextHist        = repmat(1 * eye(length(obj.originalState)),1,1,obj.ACEGridWorld_.nGridRow^2-1);

		end
		%---------------------------------------
        
        %==================================================================
        function c_grid_ = calculate_at_grid_location(obj, locations_, thisState)
            % "locations_" is either:
            %   2 x Nq matrix (each column = [x; y])
            %   OR
            %   n x n x 2 array (meshgrid locations)
        
            %------------------------------------------------------------------
            % Retrieve threat grid coordinates
            x = obj.threatCoordinates(1,:);
            y = obj.threatCoordinates(2,:);
        
            % Default state if not provided
            if nargin < 3 || isempty(thisState)
                thisState = obj.originalState;
            end
        
            %------------------------------------------------------------------
            % Handle 3D meshgrid case by flattening
            if size(locations_, 3) > 1
                % Extract meshgrid components
                tmpX = locations_(:,:,1);
                tmpY = locations_(:,:,2);
                % Flatten into 2×Nq matrix
                locationsFlatnd = [tmpX(:) tmpY(:)]';
            else
                % Already in 2×Nq form
                locationsFlatnd = locations_;
            end
        
            %------------------------------------------------------------------
            % Number of query points
            Nq = size(locationsFlatnd, 2);
            c_grid_ = zeros(1, Nq);
        
            %------------------------------------------------------------------
            % Evaluate threat field at each location
            for i = 1:Nq
                xq = locationsFlatnd(1, i);
                yq = locationsFlatnd(2, i);
                Psi = obj.compute_psi(x, y, xq, yq);
                c_grid_(i) = Psi * thisState(:);
            end
        
            %------------------------------------------------------------------
            % Reshape back into grid form if meshgrid input
            if size(locations_, 3) > 1
                nGrid = size(locations_, 1);
                c_grid_ = reshape(c_grid_, nGrid, nGrid);
            end
        end
        %------------------------------------------------------------------

        %==================================================================
        function c_ = calculate_at_sensor_locations(obj, locations_, thisState)
             if ~exist("thisState", "var")
				thisState = obj.state;
             end
             observationH = obj.calc_observation_matrix(locations_);
             c_    =  observationH * thisState;
             
        end
        %------------------------------------------------------------------

		%==================================================================
        function obj = dynamics_discrete(obj, time_step_)

			% This will update the internal state and history. If you just
			% need a prediction for the next time step without changing the
			% state stored in this object, use "process_model" instead.

			t_	= obj.timeStampState(end);
            k_ =  length(obj.timeStampState);
            u_ = obj.input(:, k_);		
            obj.state = obj.A* obj.state + obj.B*u_;
            obj.originalState = obj.state(1:length(obj.originalState));
			obj.stateHistory	= [obj.stateHistory		obj.state];
			obj.timeStampState	= [obj.timeStampState	t_ + time_step_];
		end
		%------------------------------------------------------------------
        
        %==================================================================
        function [A, B, observables] = koopman_method(obj, x_, y_, z_, u_)
         %   Constructs observables and computes Koopman operators with control.
            % Inputs:
            %   x_, y_       - Spatial coordinates (normalized to [-1,1]) [n_points x 1]
            %   z_      - Flood data (normalized per spatial point) [n_times x n_points]
            %   u_      - Control inputs (e.g., rainfall) [n_inputs x n_times]
            %   n_features - Number of lifted features
            
            % Outputs:
            %   A, B        - Koopman operators with control
            %   observables - Lifted state tensor [n_points x n_features x n_times]

            n_points = numel(x_);
            n_times  = size(z_,1);
            n_features = 7;
            % Normalize time
            t_norm_vec = (1:n_times)' / n_times;
            observables = zeros(n_points, n_features, n_times);
        
            for t = 1:n_times
                z_t = z_(t,:)'; % snapshot
                observables(:,:,t) = [ ...
                    z_t, ...
                    z_t.^2, ...
                    x_ .* z_t, ...
                    y_ .* z_t, ...
                    sin(x_), ...
                    cos(y_), ...
                    t_norm_vec(t) * ones(n_points,1) ...
                ];
            end
        
            %  Snapshot Matrices
            X       = reshape(observables(:,:,1:end-1), [], n_times-1);   % [n_obs x (T-1)]
            Y       = reshape(observables(:,:,2:end),   [], n_times-1);   % [n_obs x (T-1)]
            Upsilon = u_(:,1:end-1);                                   % [n_inputs x (T-1)]
        
            n_obs = size(X,1);
        
            %  Extended DMD
            Omega = [X; Upsilon];
        
            % SVD of Ω
            [U_t, S_t, V_t] = svd(Omega,'econ');
            r_t = min([20, rank(Omega), size(U_t,2)]);
            U_t = U_t(:,1:r_t);
            S_t = S_t(1:r_t,1:r_t);
            V_t = V_t(:,1:r_t);
        
            % Partition U_t
            U1 = U_t(1:n_obs,     :);   % state part
            U2 = U_t(n_obs+1:end, :);   % input part
        
            % SVD of Y
            [U_hat, S_hat, V_hat] = svd(Y,'econ');
            r_hat = min([20, rank(Y), size(U_hat,2)]);
            U_hat = U_hat(:,1:r_hat);
            S_hat = S_hat(1:r_hat,1:r_hat);
            V_hat = V_hat(:,1:r_hat);
        
            % Reduced A~, B~
            A_tilde = U_hat' * Y * V_t / S_t * (U1') * U_hat;
            B_tilde = U_hat' * Y * V_t / S_t * (U2');
        
            % Full Koopman operators
            A = U_hat * A_tilde * U_hat';   % [n_obs x n_obs]
            B = U_hat * B_tilde;            % [n_obs x n_inputs]
        
        end
 
		%==================================================================
		function nextState_ = process_model(obj, ...
				threatStatex_, input_, processNoise_)	
    	nextState_	= obj.A*threatStatex_ + obj.B*input_ + processNoise_;					% Then add noise
		end
		%-----------------------------------------------------------------


		%==================================================================
		function c_ = measurement_model(obj, threatStatex_, measNoise_, sensors_)
			% Calculate at sensor locations, then add noise
			locations_	 = sensors_.configuration;
			% Observation matrix
			observationH = obj.calc_observation_matrix(locations_);
			c_			 =  observationH * threatStatex_ + measNoise_;
             c_   = c_(1);
		end
		%------------------------------------------------------------------
        
		%==================================================================
        function observationH_ = calc_observation_matrix(obj, locations_)
			nSensors = length(locations_);
            observationH_ = zeros(nSensors, obj.nStates);
            sensorIdx = locations_;
            for i = 1:nSensors
                observationH_(i, sensorIdx(i)) = 1;
            end
        end
        
		%------------------------------------------------------------------

        %==================================================================
        % Function to compute psi_i at a query point
        function Psi = compute_psi(obj, x, y, Xq, Yq)
            x = x(:);
            y = y(:);
            n = length(x);   % number of nodes
            m = length(Xq);  % number of query points
            Psi = zeros(m, n);   % <--- swapped dimensions (m × n)
        
            % Build Delaunay triangulation
            DT = delaunayTriangulation(x, y);
            triangles = DT.ConnectivityList;
        
            % Loop through all query points
            for j = 1:m
                p = pointLocation(DT, Xq(j), Yq(j));
                if ~isnan(p)
                    verts = triangles(p,:);          % indices of triangle vertices
                    V = DT.Points(verts,:);          % vertex coordinates
                    Tmat = [V'; ones(1,3)];          % 3x3 matrix for barycentric coords
                    lambda = Tmat \ [Xq(j); Yq(j); 1]; % barycentric coordinates
                    Psi(j, verts) = lambda;          % <--- swapped assignment order
                else
                    % If query point outside convex hull, use nearest neighbor
                    d = sum(([x y] - [Xq(j), Yq(j)]).^2, 2);
                    [~, idx] = min(d);
                    Psi(j, idx) = 1;                % <--- swapped assignment order
                end
            end
        end


		%==================================================================
		obj = estimate_state_UKF(obj, time_step_, measurementz_k, sensors_)
		% Estimator in a separate file
		%------------------------------------------------------------------      

        %==================================================================
		obj = estimate_state_UKF1(obj, time_step_, measurementz_k, sensors_, optimalPath, controlu_k)
		% Estimator in a separate file
		%------------------------------------------------------------------

        %==================================================================
		obj = estimate_state_UKF2(obj, time_step_, measurementz_k, sensors_, optimalPath)
		% Estimator in a separate file
		%------------------------------------------------------------------

		%==================================================================
		obj = plot_(obj,grid_, flags_)
		% State and estimate plots in a different file
		%------------------------------------------------------------------
	end

end
