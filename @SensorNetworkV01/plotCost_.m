function obj = plotCost_(obj, flags_)

figure('Name', 'Cost', 'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);

yMin		= 0;
yMax		= 1.5*max(obj.truepathCostHistory);

% offset_fig = [6, 6, 6, 0, 0, 0, -6, -6, -6];


if flags_.SHOW_TRUECOST
   plot(obj.threatModel.timeStampState, obj.truepathCostHistory, 'LineWidth', 2);
   ylim([yMin yMax])
   hold on;
end

if flags_.SHOW_ESTIMATECOST 
   plot(obj.threatModel.timeStampEstimate, obj.estimatedpathCostHistory,'--', 'LineWidth', 2);
end

if flags_.SHOW_TRUECOST && flags_.SHOW_ESTIMATECOST 
   legend('True Path Cost', 'Estimated Path Cost')
   ylabel('$J$', 'Interpreter', 'latex'); 
   xlabel('Time $t$', 'Interpreter', 'latex')

end

figure('Name', 'Variance of Path Cost', 'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);

yMin		= 0;
yMax		= 1.5*max(obj.varpathCostHistory);

% offset_fig = [6, 6, 6, 0, 0, 0, -6, -6, -6];


if flags_.SHOW_TRUECOST && flags_.SHOW_ESTIMATECOST 
   semilogy(obj.threatModel.timeStampState, obj.varpathCostHistory, 'LineWidth', 2);
   ylabel('$Var(J)$', 'Interpreter', 'latex'); 
   xlabel('Time $t$', 'Interpreter', 'latex')
   ylim([yMin yMax])
end


figure('Name', 'Risk of Path Cost', 'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);

yMin		= 0;
yMax		= 1.5*max(obj.varpathCostHistory);

% offset_fig = [6, 6, 6, 0, 0, 0, -6, -6, -6];


if flags_.SHOW_TRUECOST && flags_.SHOW_ESTIMATECOST 
   plot(obj.threatModel.timeStampState, obj.pathRiskHistory, 'LineWidth', 2);
   ylabel('$Var(J)$', 'Interpreter', 'latex'); 
   xlabel('Time $t$', 'Interpreter', 'latex')
  
end

