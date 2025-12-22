function plot_grid_elements(obj, threat_, grid_, sensor_, flags_)

if flags_.SHOW_TRUE && flags_.SHOW_ESTIMATE
	if flags_.JUXTAPOSE
		figure('Name', 'True', 'Units','normalized', 'Position', [0.3 0.1 0.3*[1.8 1.6]]);
		axisTrue= subplot(1,2,1);
		axisEst	= subplot(1,2,2);
	else
		figure('Name', 'True', 'Units','normalized', 'Position', [0.7 0.1 0.25*[0.9 1.6]]);
		axisTrue= gca;
		figure('Name', 'Estimate', 'Units','normalized', 'Position', [0.7 0.4 0.25*[0.9 1.6]]);
		axisEst	= gca;
	end
else
	figure('Name', 'True', 'Units','normalized', 'Position', [0.6 0.1 0.25*[0.9 1.6]]);
	if flags_.SHOW_TRUE
		axisTrue= gca;
	elseif flags_.SHOW_ESTIMATE
		axisEst	= gca;
	end
end

nPlotPts		= 200;
xGridPlot		= linspace(-obj.halfWorkspaceSize, obj.halfWorkspaceSize, nPlotPts);
yGridPlot		= linspace(-obj.halfWorkspaceSize, obj.halfWorkspaceSize, nPlotPts);
[xMesh, yMesh]	= meshgrid(xGridPlot, yGridPlot);
locationsMesh(:, :, 1) = xMesh;
locationsMesh(:, :, 2) = yMesh;

%---- Plot sensor configuration for CRMI and Greedy Placement (Comparison)
 CRMI_sensor_location = [89, 121, 1, 23];
 Modifiedmetric_sensor_location = [89, 86, 121, 6];

if flags_.SHOW_TRUE
	threatMesh	= threat_.calculate_at_locations(...
		locationsMesh, threat_.stateHistory(:, 1));
	imageMax	= max(threatMesh(:));
	imageMin	= min(threatMesh(:));
	imageClims	= [0.8*imageMin 1.5*imageMax];
	
	grHdlSurf	= surfc(axisTrue, xMesh, yMesh, threatMesh,'LineStyle','none');
	clim(imageClims); colorbar('eastoutside'); view(2);
	axis equal; axis tight; hold on;
	xlim(1*[-obj.halfWorkspaceSize, obj.halfWorkspaceSize]); 
	ylim(1*[-obj.halfWorkspaceSize, 1*obj.halfWorkspaceSize]);
	zlim(imageClims);
    
	
% 	timeText = ['$t = $ ' num2str(0) ' units'];
% 	grHdlTimeText	= text(axisTrue, ...
% 		-0.98*obj.halfWorkspaceSize, 1.1*obj.halfWorkspaceSize, 2*imageMax, timeText, ...
% 		'Color', 'k', 'FontName', 'Times New Roman', ...
% 		'FontSize', 12, 'Interpreter','latex');

%----- Plot grid
	plot3(...
		obj.coordinates(1, :), obj.coordinates(2, :), ...
		imageMax*ones(1, size(obj.coordinates, 2)), ...
		'.', 'Color', 'w', 'MarkerSize', 10);
    for m2 = 1:grid_.nGridRow^2
		text(axisTrue, ...
			(grid_.coordinates(1, m2)- 0.05), (grid_.coordinates(2, m2) + 0.05), ...
			2*imageMax, num2str(m2), 'Color', 'k', 'FontName', 'Times New Roman', ...
			'FontSize', 8, 'Interpreter','latex')
    end

  %----- Plot sensor location (Only for Comparison)
    plot3(...
			obj.coordinates(1, CRMI_sensor_location), ...
			obj.coordinates(2, CRMI_sensor_location), ...
			imageMax*ones(1,4), ...
			'o', 'Color', 'r', 'MarkerSize', 10, 'LineWidth', 1.5);
    plot3(...
			obj.coordinates(1, Modifiedmetric_sensor_location), ...
			obj.coordinates(2, Modifiedmetric_sensor_location), ...
			imageMax*ones(1,4), ...
			'o', 'Color', 'k', 'MarkerSize', 15, 'LineWidth', 1.5);


	%----- Plot centers of basis functions
	plot3(...
		threat_.basisCenter(1, :), threat_.basisCenter(2, :), ...
		imageMax*ones(1, size(threat_.basisCenter, 2)), ...
		'.', 'Color', 'k', 'MarkerSize', 15);
% 	for m2 = 1:threat_.nStates
% 		text(axisTrue, ...
% 			(threat_.basisCenter(1, m2)- 0.05), (threat_.basisCenter(2, m2) + 0.10), ...
% 			2*imageMax, num2str(m2), 'Color', 'k', 'FontName', 'Times New Roman', ...
% 			'FontSize', 12, 'Interpreter','latex')
% 	end
	drawnow();

     for m1 = 1:length(threat_.timeStampState)
		delete(grHdlSurf);
% 		delete(grHdlTimeText);

		threatMesh	= threat_.calculate_at_locations(...
			locationsMesh);
		surfc(axisTrue, xMesh, yMesh, threatMesh,'LineStyle','none');

% 		timeText = ['$t = $ ' num2str(threat_.timeStampState(m1)) ' units'];
% 		grHdlTimeText	= text(axisTrue, ...
% 			-0.98*obj.halfWorkspaceSize, 1.1*obj.halfWorkspaceSize, 2*imageMax, timeText, ...
% 			'Color', 'k', 'FontName', 'Times New Roman', ...
% 			'FontSize', 12, 'Interpreter','latex');

	    drawnow();
    end
end
 %% CRMI surface plot

% if flags_.SHOW_TRUE
% xPlot		= linspace(-obj.halfWorkspaceSize, obj.halfWorkspaceSize, 11);
% yPlot		= linspace(-obj.halfWorkspaceSize, obj.halfWorkspaceSize, 11);
% [x_Mesh, y_Mesh]	= meshgrid(xPlot, yPlot);
% x_Mesh = flip((x_Mesh));
% y_Mesh = flip((y_Mesh));
%  CRMI_mesh = flip((reshape(sensor_.allConf_MI1(:,2), [sqrt(obj.nPoints), sqrt(obj.nPoints)]))');
%  shading interp;
%  imageMax	= max(CRMI_mesh(:));
%  imageMin	= min(CRMI_mesh(:));
%  imageClims	= [imageMin imageMax];
% 
%  figure;
% surf(x_Mesh, y_Mesh, CRMI_mesh);
% 
% % Customize the plot
% shading interp;  % Interpolate colors for a smooth appearance
% colorbar;       % Add a color bar to show the values
% % zlabel('CRMI Values');
% % title('Surface Plot of CRMI Values in 2D Grid Space');
% view(2);        % 2D view
% axis equal tight; 
% 
% % Remove numbering in x and y axes
% set(gca, 'xtick', []);
% set(gca, 'ytick', []);
% % Optional: Set axis limits based on your data range
% xlim([min(x_Mesh(:)), max(x_Mesh(:))]);
% ylim([min(y_Mesh(:)), max(y_Mesh(:))]);
% 
% % Optional: Customize colormap
%  colormap('gray');  % You can choose other colormaps
% 
% % Optional: Rotate the view for a different perspective
% % view(3);
% 
% hold on;
% 
% % Plot grid points
% plot3(obj.coordinates(1, :), obj.coordinates(2, :), imageMax * ones(1, size(obj.coordinates, 2)), '.', 'Color', 'w', 'MarkerSize', 20);
% 
% % Plot grid labels
% for m2 = 1:grid_.nGridRow^2
%     text(...
%         (grid_.coordinates(1, m2) - 0.05), (grid_.coordinates(2, m2) + 0.10), ...
%         2 * imageMax, num2str(m2), 'Color', 'r', 'FontName', 'Times New Roman', ...
%         'FontSize', 12, 'Interpreter', 'latex');
% end
% 
% if flags_.SHOW_SENSOR_LOCATION
% 			    plot3(...
% 				obj.coordinates(1, sensor_.configHistory(:,end)), ...
% 				obj.coordinates(2, sensor_.configHistory(:,end)), ...
% 				imageMax*ones(1,sensor_.nSensors), ...
% 				'o', 'Color', 'r', 'MarkerSize', 20, 'LineWidth', 1.5);
% end
% hold off;
% end