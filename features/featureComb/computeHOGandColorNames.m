function features = computeHOGandColorNames ( img, settings ) 
% function features = computeHOGandColorNames ( img, settings ) 
% 
% author: Alexander Freytag
% date  : 17-03-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   computes ...
% 
% INPUT :
%    img           --  gray or color image, if not uint8, it will be
%                      converted
%    settings      --  optional struct specifying following settings ( see
%                      computeHOGs_WHO.m and computeColorNames.m for details)
% 
% OUTPUT : 
%    features      --  double array with number of cells in x and y dimension
%                      depending on input, 43 feature dimensions per cell 
%                      ( 31+1 HOG, 11 color names)

    %TODO check that i_binSize is given or set it otherwise accordingly...
    
    if ( nargin < 2 )
        settings = [];
        settings.i_binSize = 8;
    end

    %extract HOG features
    hogFeature       = computeHOGs_WHO ( img, settings );
    
    %extract patch means features
    colorNamesFeature = computeColorNames ( img, settings );
    
    % combine both features
    features         = cat ( 3, hogFeature, colorNamesFeature );
            
end