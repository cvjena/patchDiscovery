function visualizedImg = visualizeHOGandPatchMeans ( feature, settings )
% function visualizedImg = visualizeHOGandPatchMeans ( feature, settings )
% 
% author: Alexander Freytag
% date  : 12-03-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   Visualizes a feature created by concatenating an enhanced HOG 
%   feature and a patchMean feature ( see computeHOGandPatchMeans.m for details).
% 
% INPUT :
%   feature  -- 3 dim double array, created by computeHOGandPatchMeans.m
%   settings --  (optional), struct with possible fields, e.g., 'b_normalizeCells'
% 
% OUTPUT :
%   visualizedImg -- 2 or 3 dim double array ( 3dim for color images, 2 dim
%                    for gray scale images)
% 


  %% check input
  if ( isempty ( feature) ||  (ndims ( feature) ~= 3) || (  size (feature, 3) ~= 35 ) )
      % wrong input, sry
      return
  end
  
  if ( nargin  < 2 )
      settings = [];
  end   
  
  %% grep single features
  featureHOG = feature ( :, :, 1:32);
  featurePM  = feature ( :, :, 33:size(feature,3) );
  
  %% visualize single features
  
  settings  = addDefaultVariableSetting( settings, 'widthOfCell',  20, settings ); 
  settings  = addDefaultVariableSetting( settings, 'heightOfCell', 20, settings );
  settings  = addDefaultVariableSetting( settings, 'b_showImage',  false, settings );
  settings  = addDefaultVariableSetting( settings, 'b_normalizeCells',  true, settings );
  settings  = addDefaultVariableSetting( settings, 'b_hardAssignment',  true, settings );  
      
  % visualize hog feature  
  visHOG = myHOGpicture( featureHOG, settings.widthOfCell, settings.heightOfCell );
  
  %visualize patch mean feature
  visPM  = visualizePatchMeans ( featurePM, settings );
  
  b_colorBGnotFG = getFieldWithDefault ( settings, 'b_colorBGnotFG', false );

  if ( ~b_colorBGnotFG )
      
    % OPTION 1 -- color code hog visualization
    %   
    % replicate how image to 3 color planes      
    if ( ndims (featurePM) > 2 )
        visHOGext = repmat ( visHOG, [1,1,size(featurePM,3) ] ) ;
    end
    % and multiply by relative color information
    visualizedImg = visHOGext .* visPM ; 
    
  else  
    % OPTION 2 -- color code background
    %     
    visualizedImg = repmat( (visHOG == 0),[1,1,3]).*visPM + repmat(visHOG,[1,1,3]);
  end
  
end