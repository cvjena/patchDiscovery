function visualizedImg = visualizeHOGandColorNames ( feature, settings )
% function visualizedImg = visualizeHOGandColorNames ( feature, settings )
% 
% author: Alexander Freytag
% date  : 17-03-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   Visualizes a feature created by concatenating an enhanced HOG 
%   feature and a colorNames feature ( see computeColorNames.m for details).
% 
% INPUT :
%   feature  -- 3 dim double array, created by computeHOGandColorNames.m
%   settings --  (optional), struct with possible fields, e.g., 'b_hardAssignment'
% 
% OUTPUT :
%   visualizedImg -- 3 dim double array
% 


  %% check input
  if ( isempty ( feature) ||  (ndims ( feature) ~= 3) || (  size (feature, 3) ~= 43 ) )
      % wrong input, sry
      return
  end
  
  if ( nargin  < 2 )
      settings = [];
  end  
  
  %% grep single features
  featureHOG = feature ( :, :, 1:32);
  featureCN  = feature ( :, :, 33:size(feature,3) );
  
  %% visualize single features
  
  settings  = addDefaultVariableSetting( settings, 'widthOfCell',  20, settings ); 
  settings  = addDefaultVariableSetting( settings, 'heightOfCell', 20, settings );
  settings  = addDefaultVariableSetting( settings, 'b_showImage',  false, settings );
  settings  = addDefaultVariableSetting( settings, 'b_normalizeCells',  true, settings );
  settings  = addDefaultVariableSetting( settings, 'b_hardAssignment',  true, settings );
  
  
  % visualize hog feature  
  visHOG = myHOGpicture( featureHOG, settings.widthOfCell, settings.heightOfCell );
  
  %visualize patch mean feature

  visCN  = visualizeColorNames ( featureCN, settings );
  
  b_colorBGnotFG = getFieldWithDefault ( settings, 'b_colorBGnotFG', false );

  if ( ~b_colorBGnotFG )
  
    % OPTION 1 -- color code hog visualization
    %   
    % replicate hog image to 3 color planes
    visHOGext = repmat ( visHOG, [1,1,3 ] ) ;

    % and multiply by relative color information
    visualizedImg = visHOGext .* visCN ;  
  
  else 
    % OPTION 2 -- color code background
    %     
    visualizedImg = repmat( (visHOG == 0),[1,1,3]).*visCN + repmat(visHOG,[1,1,3]);
  end  
  
end