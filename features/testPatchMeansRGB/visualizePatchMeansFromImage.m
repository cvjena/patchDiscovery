function visualizePatchMeansFromImage ( img, i_numCells, b_convolution, b_closeImages )
% function visualizePatchMeansFromImage ( img, i_numCells, b_convolution, b_closeImages )
% 
% author: Alexander Freytag
% date  : 11-02-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   computes patchMeans for a given image and paints those values into a
%   second image of same size
%   Both images are visualized until user gives keyboard feedback.
% 
% INPUT :
%    img           --  uint8 gray or color image
%    i_numCells    --  (optional), number of blocks in x and y direction, default: 8
%    b_closeImages --  (optional), if true, shown images are closed before
%                      ending the script, default: true


    %% (1) check input
    
    % default: average rgb values in 8 x 8 patches the image is divided
    % into
    if ( nargin < 2 )
        i_numCells = 8;
    end
    
    % default: compute features with efficient reshape+mean operations
    if ( nargin < 3 )
        b_convolution = false;
    end
    
    % default: close images after user input
    if ( nargin < 4 ) 
        b_closeImages = true;
    end      
    
    %% (2) compute features
    
    settings.i_numCells = i_numCells;
    settings.b_convolution = b_convolution;
    rgbPatchMeans = computePatchMeans ( img, settings );
    
    % computeMeanPatches outputs features normalized to [0,1] per dimension
    rgbPatchMeans = uint8(round(255*rgbPatchMeans));
    
    %% (3) show input image
    figOrig = figure;
    s_titleOrig = sprintf('Original image' );            
    set ( figOrig, 'name', s_titleOrig);        
    imshow ( img );
   
    %% (4) visualize results
    imgPatches = zeros ( size ( img ), 'uint8' );
   
    [ height, width, depth ] = size ( img ) ;
    patchHeight = floor( height / i_numCells );
    patchWidth  = floor( width  / i_numCells );    
   
    %TODO less for loops please, proper indexing instead
    for  j = 1:i_numCells
        for  i = 1:i_numCells
            for depthIt =1:depth
            imgPatches ( patchHeight*(j-1)+1:patchHeight*(j), ...
                         patchWidth*(i-1)+1:patchWidth*(i), depthIt) ...
                         = rgbPatchMeans(j,i,depthIt);
            end                     
        end
    end   
    
    % draw kachel-optik
    
    %# Change every yth row to black
    imgPatches(patchWidth:patchWidth:end,:,:)   = 0;      
    %# Change every xth column to black
    imgPatches(:,patchHeight:patchHeight:end,:) = 0;    
   
    % create new figure
    figPatches = figure;
    
    % nice title
    s_titlePatches = sprintf('Patch Means' );            
    set ( figPatches, 'name', s_titlePatches);        
    
    imshow ( imgPatches );
   
    %% (5) wait for user input
    pause
   
    % close corresponding images
    if ( b_closeImages )    
        close ( figOrig );   
        close ( figPatches );
    end

end
