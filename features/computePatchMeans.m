function patchMeans = computePatchMeans ( img, settings ) 
% function meanPatches = computePatchMeans ( img, settings ) 
% 
% author: Alexander Freytag
% date  : 11-02-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   computes patchMeans for a given image by averaging color or gray scale
%   values over blocks of specified size (squared regions always).
% 
% INPUT :
%    img           --  gray or color image, if not uint8, it will be
%                      converted
%    settings      --  struct specifying the following settings
%        sbin          -- (optional),size of each block in x and y dimension,
%                         default: 8
%        b_convolution -- (optional), if true, averaging per block is done by
%                         convoling image with averaging filters, whereas for
%                         false, explicite averaging of reshaped blocks is
%                         done, default: true if sbin < 10, false elsewise
%        b_normalizeCells -- (optional), if true, every cell is normalize
%                            to length 1 (L1 norm)
% 
% OUTPUT : 
%    meanPatches   --  uint8 gray or color image (depending on input), with
%                      size floor(height/sbin) x floor(width/sbin)


    %% (1) check input
    
    % into how many cells do we split up the support area per dimension?
    % default: 8
    
    if ( nargin < 2 ) 
        settings = [];
    end
    
    [height,width,~]=size(img);
    
    %has the number of cell be specified?
    if ( ( ~isempty (settings) ) && ...
         ( isstruct ( settings ) ) && ...
         ( isfield(settings, 'i_numCells')  )...
       )
        i_numCells = settings.i_numCells;
        blockHeight = floor( height / i_numCells );
        blockWidth  = floor( width  / i_numCells ); 
    %was the number of pixels per cell specified instead?
    elseif ( ( ~isempty (settings) ) && ...
             ( isstruct ( settings ) ) && ...
             ( isfield(settings, 'i_binSize')  )...
           )
        %TODO currently only squared images are supported properly
        i_numCells = min ( floor( width  / settings.i_binSize ),  floor( height  / settings.i_binSize ) );
        blockHeight = settings.i_binSize;
        blockWidth  = settings.i_binSize;         
    % neither number of blocks nor cell size was specified, use default
    % values instead        
    else
        i_numCells  = 8;
        blockHeight = floor( height / i_numCells );
        blockWidth  = floor( width  / i_numCells );         
    end
       
    
    % set default for b_convolution
    % from my experiments, the convolution is useful for block sizes
    % smaller than 10, whereas for larger sizes, the grid technique should
    % be preferred
    if ( ( nargin < 2 ) || ...
         ( isempty (settings) ) || ...
         ( ~isstruct ( settings ) ) || ...
         ( ~isfield(settings, 'b_convolution')  )...
       )
   
        if ( i_numCells < 64 )
            b_convolution = false;
        else
            b_convolution = true;
        end
    else
        b_convolution = settings.b_convolution;
    end
    
    if  ( ~isa( img, 'double') )
        img = double(img);
    end
    
    

    %% (2) compute features
    
    if ( ndims(img) == 3 )
        %% (2.1) work on color images
        
        if ( b_convolution )            
            % Make a box filter to average all the values within a 
            % blockWidth by blockHeight window.
            boxFilter = ones( blockWidth,blockHeight);
            boxFilter = boxFilter ./ ( blockWidth*blockHeight );
            
            % now filter every channel seperately            
        
            % red channel
            rgbPatchMeansR = uint8(conv2( double(img(:,:,1)), boxFilter, 'same'));
            patchMeans(:,:,1) = rgbPatchMeansR( ...
                          ceil(blockHeight/2):blockHeight : (end-ceil(blockHeight/2)), ...
                          ceil(blockWidth/2):blockWidth   : (end-ceil(blockWidth/2)) ...
                                                );

            % green channel
            rgbPatchMeansG = uint8(conv2( double(img(:,:,2)), boxFilter, 'same'));
            patchMeans(:,:,2) = rgbPatchMeansG( ...
                          ceil(blockHeight/2):blockHeight : (end-ceil(blockHeight/2)), ...
                          ceil(blockWidth/2):blockWidth   : (end-ceil(blockWidth/2)) ...
                                                );

            % blue channel
            rgbPatchMeansB = uint8(conv2( double(img(:,:,3)), boxFilter, 'same'));
            patchMeans(:,:,3) = rgbPatchMeansB( ...
                          ceil(blockHeight/2):blockHeight : (end-ceil(blockHeight/2)), ...
                          ceil(blockWidth/2):blockWidth   : (end-ceil(blockWidth/2)) ...
                                                );        
        else
             %If array A consists of p x q blocks, each of size m x n, 
             %(and therefore A is of size m*p x n*q,) 
             %then the array M gives the corresponding p x q array 
             %of the blocks' mean values.
             %[I,J,K,L] = ndgrid(1:m,0:n-1,0:p-1,0:q-1);
             %M = reshape(mean(reshape(A(I+m*p*J+m*K+m*p*n*L),m*n,p*q),1),p,q);             
             
             p = i_numCells;
             q = i_numCells;
             m = blockHeight;
             n = blockWidth;
             
             % check that image is of size m*p x n*q
             % if not, reshaping results in undesired behaviour.
             img = img(1:m*p,1:n*q,:);
             
             [I,J,K,L] = ndgrid( 1:m, 0:n-1, 0:p-1, 0:q-1 );             
             
             imgChannel = img(:,:,1);
             patchMeans(:,:,1) = uint8( ...
                                    reshape(  mean(reshape(...
                                            imgChannel(I + m*p*J + m*K + m*p*n*L), ...
                                            m*n, p*q ), ...
                                            1),...
                                            p,q ...
                                           ) ...
                                       );   
                                     
             imgChannel = img(:,:,2);
             patchMeans(:,:,2) = uint8( ...
                                    reshape(  mean(reshape(...
                                            imgChannel(I + m*p*J + m*K + m*p*n*L), ...
                                            m*n, p*q ), ...
                                            1),...
                                            p,q ...
                                           ) ...
                                       );    
                                     
             imgChannel = img(:,:,3);
             patchMeans(:,:,3) = uint8( ...
                                    reshape(  mean(reshape(...
                                            imgChannel(I + m*p*J + m*K + m*p*n*L), ...
                                            m*n, p*q ), ...
                                            1),...
                                            p,q ...
                                           ) ...
                                       );                                       
        end
        
    else
        %% (2.2) work on grayscale images
        if ( b_convolution )
            % Make a box filter to average all the values within a 
            % boxFilterWidth by boxFilterHeight window.
            boxFilter = ones( blockWidth,blockHeight);
            boxFilter = boxFilter ./ ( blockWidth*blockHeight );

            % gray channel
            patchMeansGray = uint8(conv2( double(img(:,:)), boxFilter, 'same'));
            patchMeans(:,:) = patchMeansGray( ...
                          ceil(blockHeight/2):blockHeight : (end-ceil(blockHeight/2)), ...
                          ceil(blockWidth/2):blockWidth   : (end-ceil(blockWidth/2)) ...
                                                );
        else
             %If array A consists of p x q blocks, each of size m x n, 
             %(and therefore A is of size m*p x n*q,) 
             %then the array M gives the corresponding p x q array 
             %of the blocks' mean values.
             %[I,J,K,L] = ndgrid(1:m,0:n-1,0:p-1,0:q-1);
             %M = reshape(mean(reshape(A(I+m*p*J+m*K+m*p*n*L),m*n,p*q),1),p,q);             
             
             p = i_numCells;
             q = i_numCells;
             m = blockHeight;
             n = blockWidth;
             
             % check that image is of size m*p x n*q
             % if not, reshaping results in undesired behaviour.
             img = img(1:m*p,1:n*q,:);
             
             [I,J,K,L] = ndgrid( 1:m, 0:n-1, 0:p-1, 0:q-1 );             
             
             patchMeans(:,:) = uint8( ...
                                    reshape(  mean(reshape(...
                                            img(I + m*p*J + m*K + m*p*n*L), ...
                                            m*n, p*q ), ...
                                            1),...
                                            p,q ...
                                           ) ...
                                       );                
        end
    end
    
    %TODO DIRTY HACKY
    patchMeans = double ( patchMeans )./255 ;
    
    b_normalizeCells = getFieldWithDefault ( settings, 'b_normalizeCells', true );
    
    if ( b_normalizeCells )
        % compute L1 norm of every cell
        normPatchMeans = sum(patchMeans, 3);
        % avoid division by zero
        normPatchMeans(normPatchMeans < eps) = 1;
        % L1-normalize
        patchMeans = bsxfun(@rdivide, patchMeans, normPatchMeans);    
    end
            
end