function stateAxes = plot_(obj,  grid_, flags_)
figure('Name', 'States', 'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);
nPlotRow	= round(sqrt(obj.nStates));
nPlotCol	= ceil(obj.nStates / nPlotRow);

yMin		= min(obj.stateHistory(:));
yMax		= max(obj.stateHistory(:));
yMin		= yMin - 0.1*abs(yMin);
yMax		= yMax + 0.1*abs(yMax);

stateAxes		= cell(obj.nStates, 1);

% offset_fig = [6, 6, 6, 0, 0, 0, -6, -6, -6];
%  offset_fig = [12, 12, 12, 12, 4, 4, 4, 4, -4, -4, -4, -4, -12, -12, -12, -12];
% offset_fig = [6, 6, 6, 0, 0, 0, -6, -6, -6];
for m1 = 1:obj.nStates
	subplot(nPlotRow, nPlotCol, m1)

	if flags_.SHOW_TRUE
		plot(obj.timeStampState, obj.stateHistory(m1, :), 'LineWidth', 2);
		ylim([yMin yMax])
		hold on;
	end

	if flags_.SHOW_ESTIMATE
		plot(obj.timeStampEstimate, obj.stateEstimateHistory(m1, :),'--', 'LineWidth', 2);
	end

	if flags_.SHOW_TRUE && flags_.SHOW_ESTIMATE
		legend('True', 'Estimate')
%     yTitle = ['$\theta_{' num2str(m1 + offset_fig(m1)) '}$'];
%     yTitle = ['$\theta_{' num2str(m1) '}$'];
% 	ylabel(yTitle, 'Interpreter', 'latex'); 
	xlabel('Time $t$', 'Interpreter', 'latex')

	end

	stateAxes{m1} = gca;

end


if ~flags_.SHOW_ESTIMATE, return, end
figure('Name', 'Estimation Error Covariance (Diagonal)', ...
	'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);
yMin		= 0;
yMax		= 1.1*max(obj.estimateCovarPxxHistory(:));
for m1 = 1:obj.nStates
	subplot(nPlotRow, nPlotCol, m1)
	plot(obj.timeStampEstimate, ...
		obj.estimateCovarPxxHistory((m1 - 1)*obj.nStates + m1, :), ...
		'LineWidth', 2);
	ylim([yMin yMax])
    yTitle = ['$P_{' num2str(m1) num2str(m1) '}$'];
	ylabel(yTitle, 'Interpreter', 'latex'); 
	xlabel('Time $t$', 'Interpreter', 'latex');
end

if ~flags_.SHOW_ESTIMATE, return, end
figure('Name', 'Estimation Error Covariance Image (Diagonal)', ...
	'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);
colorImageArray = reshape(log(diag(obj.estimateCovarPxx)),[sqrt(obj.nStates), sqrt(obj.nStates)]);
imagesc(flip(colorImageArray));
colormap(gray);
colorbar;

% if ~flags_.SHOW_ESTIMATE, return, end
% figure('Name', 'Estimation Error Covariance (Diagonal)', ...
% 	'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);
% yMin		= 0;
% yMax		= 1.1*max(obj.estimateCovarPxxHistory(:));
% for m1 = 1:obj.nStates
% 	subplot(nPlotRow, nPlotCol, m1)
% 
% 	plot(obj.timeStampEstimate(end-2:end-1), ...
% 		obj.estimateCovarPxxHistory((m1 - 1)*obj.nStates + m1, end-2:end-1), ...
% 		'LineWidth', 2);
% 	ylim([yMin yMax])
%     yTitle = ['$P_{' num2str(m1) num2str(m1) '}$'];
% 	ylabel(yTitle, 'Interpreter', 'latex'); 
% 	xlabel('Time $t$', 'Interpreter', 'latex')
%     title('Error covariance for k-1 iteration')
% end
% 
% if ~flags_.SHOW_ESTIMATE, return, end
% figure('Name', 'Estimation Error Covariance (Diagonal)', ...
% 	'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);
% yMin		= 0;
% yMax		= 1.1*max(obj.estimateCovarPxxHistory(:));
% for m1 = 1:obj.nStates
% 	subplot(nPlotRow, nPlotCol, m1)
% 	plot(obj.timeStampEstimate(end-1:end), ...
% 		obj.estimateCovarPxxHistory((m1 - 1)*obj.nStates + m1, end-1:end), ...
% 		'LineWidth', 2);
% 	ylim([yMin yMax])
%     yTitle = ['$P_{' num2str(m1) num2str(m1) '}$'];
% 	ylabel(yTitle, 'Interpreter', 'latex'); 
% 	xlabel('Time $t$', 'Interpreter', 'latex')
%     title('Error covariance for k iteration');
% end



if ~flags_.SHOW_ESTIMATE, return, end
figure('Name', 'Trace of Error Covariance', ...
	'Units','normalized', 'Position', [0.35 0.05 [0.6 0.6]]);
yMin		= 0;
yMax		= 1.1*max(obj.traceCovarPxxHistory(:));
plot(obj.timeStampEstimate(:,2:end), ...
		obj.traceCovarPxxHistory(:,2:end), 'LineWidth', 2);
ylim([yMin yMax])
yTitle = 'Trace $P$';
	ylabel(yTitle, 'Interpreter', 'latex'); 
	xlabel('Time $t$', 'Interpreter', 'latex');

end
