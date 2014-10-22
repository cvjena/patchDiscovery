function patchProbMeans = computeColorNames ( img, settings )
%%TODO docu

    %% (1) check input
    
     
    height = size ( img, 1 );
    width  = size ( img, 2 );
    
    % check input image
    if ( ~isa(img, 'double') )
        img = double( img );
    end
    
    if ( ndims(img) == 3 )
    else
        img = repmat ( img, [1,1,3] );
    end    
    
    if ( nargin < 2 ) 
        settings = [];
    end
    
    
    %has the number of cell be specified?
    if ( ( ~isempty (settings) ) && ...
         ( isstruct ( settings ) ) && ...
         ( isfield(settings, 'i_numCells')  )...
       )
        i_numCells = settings.i_numCells;
        blockHeight = floor( height / i_numCells(1) );
        blockWidth  = floor( width  / i_numCells(2) );
    %was the number of pixels per cell specified instead?
    elseif ( ( ~isempty (settings) ) && ...
             ( isstruct ( settings ) ) && ...
             ( isfield(settings, 'i_binSize')  )...
           )
        i_numCells =  [ floor( height  / settings.i_binSize ),  floor( width  / settings.i_binSize ) ];
        blockHeight = settings.i_binSize;
        blockWidth  = settings.i_binSize;         
    % neither number of blocks nor cell size was specified, use default
    % values instead        
    else
        i_numCells  = [ 8, 8 ];
        blockHeight = floor( height / i_numCells(1) );
        blockWidth  = floor( width  / i_numCells(2) );
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
   
        %if ( max(i_numCells) < 64 )
        if ( max(blockHeight,blockWidth) < 10 )
            b_convolution = false;
        else
            b_convolution = true;
        end
    else
        b_convolution = settings.b_convolution;
    end
    
    %% (2) compute features
    % Color Naming
    persistent w2c;    
    if ( isempty ( w2c ) )
        w2c = getFieldWithDefault ( settings, 'w2c', []);
        load ( getColorNameLUTdestination, 'w2c' ); 
    end
    % Discriminant Color Descriptor
    % load 'w2c/DD11_w2c.mat';

    % ---------------------------------------------------------------------

    
    numC = 11;
    
    % prepare variable settings, depending on the strategy
    
    % do computations
    RR=img(:,:,1);GG=img(:,:,2);BB=img(:,:,3);
    index_im = 1+floor(RR(:)/8)+32*floor(GG(:)/8)+32*32*floor(BB(:)/8);

    %init output memory
    patchProbMeans = zeros (i_numCells(1),i_numCells(2),11);
        


        
    if ( b_convolution )    
        
        % Make a box filter to average all the values within a 
        % blockWidth by blockHeight window.
        boxFilter = ones( blockWidth,blockHeight);
        boxFilter = boxFilter ./ ( blockWidth*blockHeight );           

        for i=1:numC                            
            %colorProbs(:,:) = im2c(img,w2c,i);
            % use the code of ColorNames
            %colorProbs = im2c(img,w2c,i);

            % directly use the code here..
            colorProbs=reshape(w2c(index_im(:),i),size(img,1),size(img,2)); 

            colorProbMeans = conv2( double(colorProbs), boxFilter, 'same');

            patchProbMeans(:,:,i) = colorProbMeans( ...
                      ceil(blockHeight/2):blockHeight : (end-ceil(blockHeight/2)), ...
                      ceil(blockWidth/2):blockWidth   : (end-ceil(blockWidth/2)) ...
                                            );            
        end
    else

        p = i_numCells(1);
        q = i_numCells(2);
        m = blockHeight;
        n = blockWidth;
        
        %this can be used for all colors
        [I,J,K,L] = ndgrid( 1:m, 0:n-1, 0:p-1, 0:q-1 );            

        for i=1:numC

            %colorProbs(:,:) = im2c(img,w2c,i);
            % use the code of ColorNames
            %colorProbs = im2c(img,w2c,i);

            % directly use the code here..
            colorProbs=reshape(w2c(index_im(:),i),size(img,1),size(img,2)); 
           


            %If array A consists of p x q blocks, each of size m x n, 
            %(and therefore A is of size m*p x n*q,) 
            %then the array M gives the corresponding p x q array 
            %of the blocks' mean values.
            %[I,J,K,L] = ndgrid(1:m,0:n-1,0:p-1,0:q-1);
            %M = reshape(mean(reshape(A(I+m*p*J+m*K+m*p*n*L),m*n,p*q),1),p,q);             



            % check that image is of size m*p x n*q
            % if not, reshaping results in undesired behaviour.
            colorProbs = colorProbs(1:m*p,1:n*q,:);


            patchProbMeans(:,:,i) = reshape(  mean(reshape(...
                                            colorProbs(I + m*p*J + m*K + m*p*n*L), ...
                                            m*n, p*q ), ...
                                            1),...
                                            p,q ...
                                           ) ;       
        end                                       
    end
    
    
    
    b_normalizeCells = getFieldWithDefault ( settings, 'b_normalizeCells', true );
    
    if ( b_normalizeCells )
        % compute L1 norm of every cell
        normPatchProbMeans = sum(patchProbMeans, 3);
        % avoid division by zero
        normPatchProbMeans(normPatchProbMeans < eps) = 1;
        % L1-normalize
        patchProbMeans = bsxfun(@rdivide, patchProbMeans, normPatchProbMeans);    
    end    
    
end