function features = computeHOGandPatchMeans ( img, settings ) 
% function features = computeHOGandPatchMeans ( img, settings ) 
% 
% author: Alexander Freytag
% date  : 11-03-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   computes ...
% 
% INPUT :
%    img           --  gray or color image, if not uint8, it will be
%                      converted
%    settings      --  optional struct specifying following settings ( see
%                      computeHOGs_WHO and computePatchMeans for details)
% 
% OUTPUT : 
%    features      --  double array with number of cells in x and y dimension
%                      depending on input, 35 feature dimensions per cell 
%                      ( 31+1 HOG, 3 patch means)

    %TODO check that i_binSize is given or set it otherwise accordingly...
    
    if ( nargin < 2 )
        settings = [];
        settings.i_binSize = 8;
    end

    %extract HOG features
    hogFeature       = computeHOGs_WHO ( img, settings );
    
    %extract patch means features
    patchMeanFeature = computePatchMeans ( img, settings );
    
    % combine both features
    features         = cat ( 3, hogFeature, patchMeanFeature );
            
end