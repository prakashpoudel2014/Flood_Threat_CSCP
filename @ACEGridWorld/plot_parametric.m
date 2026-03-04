function plot_parametric(obj, threat_, sensor_, actor_, flags_)

if flags_.DUAL_SCREEN
	figXOffset = 0.6;
else
	figXOffset = 0;
end

if flags_.SHOW_TRUE && flags_.SHOW_ESTIMATE
	if flags_.JUXTAPOSE
		figure('Name', 'True', 'Units','normalized', ...
			'Position', [figXOffset + 0.3 0.1 0.3*[1.8 1.6]]);
		axisTrue= subplot(1,2,1);
		axisEst	= subplot(1,2,2);
	else
		figure('Name', 'True', 'Units','normalized', ...
			'Position', [figXOffset + 0.7 0.1 0.25*[0.9 1.6]]);
		axisTrue= gca;
		figure('Name', 'Estimate', 'Units','normalized', ...
			'Position', [figXOffset + 0.7 0.4 0.25*[0.9 1.6]]);
		axisEst	= gca;
	end
else
	figure('Name', 'True', 'Units','normalized', ...
		'Position', [figXOffset + 0.6 0.1 0.25*[0.9 1.6]]);
	if flags_.SHOW_TRUE
		axisTrue= gca;
	elseif flags_.SHOW_ESTIMATE
		axisEst	= gca;
	end
end

nPlotPts		= 500;
xGridPlot		= linspace(-obj.halfWorkspaceSize, obj.halfWorkspaceSize, nPlotPts);
yGridPlot		= linspace(-obj.halfWorkspaceSize, obj.halfWorkspaceSize, nPlotPts);
[xMesh, yMesh]	= meshgrid(xGridPlot, yGridPlot);

if flags_.SHOW_TRUE
    x_sc = threat_.threatCoordinates(1, :)';   % 58×1
    y_sc = threat_.threatCoordinates(2, :)';   % 58×1
    z_sc_t = threat_.stateHistory(1:length(threat_.originalState), end);  % 58×1
    z_sc_e = threat_.stateEstimateHistory(1:length(threat_.originalState), end);  % 58×1
    threatMesh = griddata( x_sc, y_sc, z_sc_t, xMesh, yMesh, 'v4');  
	imageMax	= max(threatMesh(:));
	imageMin	= min(threatMesh(:));
 	imageClims	= [0.8*imageMin 1.5*imageMax];
  
    grHdlSurf	= surfc(axisTrue, xMesh, yMesh, threatMesh,'LineStyle','none');
	clim(imageClims); colorbar; view(2); colormap(turbo);
	axis equal; axis tight; hold on;
	set(gca, 'Color', '#D0D0D0')

	xlim(1.1*[-obj.halfWorkspaceSize, obj.halfWorkspaceSize]); 
	ylim(1.1*[-obj.halfWorkspaceSize, 1*obj.halfWorkspaceSize]);
    
	zlim(imageClims);
	

	%----- Plot grid
	plot3(...
		obj.coordinates(1, :), obj.coordinates(2, :), ...
		imageMax*ones(1, size(obj.coordinates, 2)), ...
		'.', 'Color', 'w', 'MarkerSize', 15);

	%----- Plot threat locations(gauges)
	plot3(...
		threat_.threatCoordinates(1, :), threat_.threatCoordinates(2, :), ...
		imageMax*ones(1, size(threat_.threatCoordinates, 2)), ...
		'.', 'Color', 'k', 'MarkerSize', 20);
	for m2 = 1:length(threat_.originalState)
		text(axisTrue, ...
			threat_.threatCoordinates(1, m2), (threat_.threatCoordinates(2, m2) + 0.05), ...
			2*imageMax, num2str(m2), 'Color', 'k', 'FontName', 'Times New Roman', ...
			'FontSize', 8, 'Interpreter','latex')
	end


	%----- Plot path if desired
	if flags_.SHOW_PATH
			  plot3(...
				   obj.coordinates(1, actor_.actualPath), ...
				   obj.coordinates(2, actor_.actualPath), ...
				    imageMax*ones(1, length(actor_.actualPath)), ...
				    'o', 'Color', 'r', 'MarkerSize', 10, 'LineWidth', 1.3); hold on
                    plot3(...
				    obj.coordinates(1, actor_.expectedPath(2:end)), ...
				    obj.coordinates(2, actor_.expectedPath(2:end)), ...
				    imageMax*ones(1, length(actor_.expectedPath(2:end))), ...
				    'hexagram', 'Color', 'r', 'MarkerSize', 10, 'LineWidth', 1.3);
                    text(obj.coordinates(1, 494)+0.02, obj.coordinates(2,494)+0.08,2*imageMax, 'S', 'FontName', 'Times New Roman', ...
	                    'FontSize', 24, 'Color', 'r');
                    text(obj.coordinates(1, 44)-.12, obj.coordinates(2, 44)-.12, 2*imageMax, 'G', 'FontName', 'Times New Roman', ...
	                    'FontSize', 24, 'Color', 'r');
    end


%----- Plot sensor location if desired
	if flags_.SHOW_SENSOR_LOCATION
          for id =1:2
			  plot3(...
		      threat_.threatCoordinates(1, sensor_(id).actualPath(:,end)), ...
			  threat_.threatCoordinates(2, sensor_(id).actualPath(:,end)), ...
			  imageMax*ones(1), ...
				'o', 'Color', 'k', 'MarkerSize', 15, 'LineWidth', 1.5);
          end
    end

    % Add title to colorbar
        cbar = colorbar;
%          cbar.Label.String = '$\widehat{c}(\textrm{m})$';  
         cbar.Label.String = '$c(\textrm{m})$';  
        cbar.Label.Interpreter = 'latex';
%         cbar.Label.FontName = 'Times New Roman';
        cbar.Label.FontSize = 18;
        xlabel('$x_1$', 'Interpreter','latex', 'FontName','Times New Roman', 'FontSize',18);
        ylabel('$x_2$', 'Interpreter','latex', 'FontName','Times New Roman', 'FontSize',18);

end
