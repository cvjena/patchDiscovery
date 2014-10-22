function visualizeColorNamesFromImage ( varargin )
% function visualizeColorNamesFromImage ( varargin )
% 
% author: Alexander Freytag
% date  : 17-03-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   computes colorNamesFeature for a given image and paints those values into a
%   second image of same size
%   Both images are visualized until user gives keyboard feedback.
% 
% INPUT :
%    img           --  uint8 gray or color image
%    i_numCells    --  (optional), number of blocks in x and y direction, default: 8
%    b_closeImages --  (optional), if true, shown images are closed before
%                      ending the script, default: true


    %% (1) check input
    
    myInput = parseInputs(varargin{:});
    img     = myInput.img;
    
    
    %% (2) compute features
    
    featureColorNames      = computeColorNames ( img, myInput );
    
        
    %% (3) show input image
    figOrig = figure;
    s_titleOrig = sprintf('Original image' );            
    set ( figOrig, 'name', s_titleOrig);        
    imshow ( img );
   
    %% (4) visualize results
    imgPatches = zeros ( size ( img )  );
   
    [ height, width, ~ ] = size ( img ) ;
    heightOfCell = floor( double(height) / myInput.i_numCells(1) );
    widthOfCell  = floor( double(width)  / myInput.i_numCells(2) ); 
    
    % from im2c.m
    % order of color names: black ,   blue   , brown       , grey       , green   , orange   , pink     , purple  , red     , white    , yellow
    color_values =     {  [0 0 0] ; [0 0 1] ; [.5 .4 .25] ; [.5 .5 .5] ; [0 1 0] ; [1 .8 0] ; [1 .5 1] ; [1 0 1] ; [1 0 0] ; [1 1 1 ] ; [ 1 1 0 ] };        
   
    if ( myInput.b_hardAssignment ) 
        
        [~,w2cM]=max( featureColorNames,[],3);  
        for  j = 1:myInput.i_numCells(1)
            for  i = 1:myInput.i_numCells(2)
                    imgPatches ( heightOfCell*(j-1) + 1:heightOfCell*(j), ...
                                 widthOfCell*(i-1)  + 1:widthOfCell*(i), :) ...
                                 = repmat( reshape(color_values { w2cM(j,i)}', [1,1,3]) , [heightOfCell, widthOfCell,1]);
            end
        end   
    else
        for  j = 1:myInput.i_numCells(1)
            for  i = 1:myInput.i_numCells(2)
                rgbResult = sum ( cell2mat ( color_values ) .* repmat ( reshape( featureColorNames(j,i,:), [11,1]), [1,3]), 1);

                imgPatches ( heightOfCell*(j-1) + 1:heightOfCell*(j), ...
                             widthOfCell*(i-1)  + 1:widthOfCell*(i), :) ...                
                             = repmat( reshape(rgbResult, [1,1,3]) , [heightOfCell, widthOfCell,1]);
            end
        end
        
    end   
    
    % draw kachel-optik
    
    %# Change every yth row to black
    imgPatches(heightOfCell:heightOfCell:end,:,:)   = 0;      
    %# Change every xth column to black
    imgPatches(:,widthOfCell:widthOfCell:end,:) = 0;    
    
    % change class to uint8 and scale appropriately! imgPatches...
       
    % create new figure
    figPatches = figure;
    
    % nice title
    s_titlePatches = sprintf('ColorName Patch Means' );            
    set ( figPatches, 'name', s_titlePatches);        
    
    imshow ( imgPatches );
   
    %% (5) wait for user input
    pause
   
    % close corresponding images
    if ( myInput.b_closeImages )    
        close ( figOrig );   
        close ( figPatches );
    end

end

function myInput = parseInputs(varargin)


    % default: compute features with efficient reshape+mean operations
    myDefaults.b_convolution       =  false;
    
    % default: average rgb values in 8 x 8 patches the image is divided
    % into
    myDefaults.i_numCells          =  [ 8, 8 ];    

    % default: close images after user input
    myDefaults.b_closeImages       =  true;
    
    % default: wait for user input
    myDefaults.b_waitForInput      =  true;
    
    % default: close images after user input
    myDefaults.b_createNewFigure   =  true;
    
    % default: no pre-normalization to l1-norm 1
    myDefaults.b_normalizeCells    =  false;
    
    % default: use only most plausible color for visualization
    myDefaults.b_hardAssignment    =  true;
    
    % default: no LUT available, has to be loaded lateron
    myDefaults.w2c    =  [];
    

    if ( nargin < 1 )
        disp('visualizeColorNamesFromImage --No input image given!')
    elseif ( nargin < 2 )
        myInput                    = myDefaults;
        myInput.img                =  varargin{1};
    else
        if isstruct( varargin{2} )
            
            myInput.b_closeImages     = getFieldWithDefault ( varargin{2}, 'b_closeImages', myDefaults.b_closeImages);
            
            myInput.b_waitForInput    = getFieldWithDefault ( varargin{2}, 'b_waitForInput', myDefaults.b_waitForInput );
            
            myInput.b_createNewFigure = getFieldWithDefault ( varargin{2}, 'b_createNewFigure', myDefaults.b_createNewFigure);            
            
            myInput.b_normalizeCells  = getFieldWithDefault ( varargin{2}, 'b_normalizeCells', myDefaults.b_normalizeCells);
            
            myInput.b_hardAssignment  = getFieldWithDefault ( varargin{2}, 'b_hardAssignment', myDefaults.b_hardAssignment );
            
            myInput.w2c               = getFieldWithDefault ( varargin{2}, 'b_hardAssignment', myDefaults.w2c );
            
        else
            if ( mod( nargin-1, 2 ) ~= 0 )
                disp('visualizeColorNamesFromImage -- No varnames specified. Ignoring further specifications, use default values...')
            else
                % set defaults
                myInput                           = myDefaults;
                % now check for explicitely specified settings
                for i=2:2:nargin
                    
                    if ( strcmp ( varargin{i}, 'b_convolution' ) )
                        myInput.b_convolution     = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'i_numCells' ) )
                        myInput.i_numCells        = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'b_closeImages' ) )
                        myInput.b_closeImages     = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'b_waitForInput' ) )
                        myInput.b_waitForInput    = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'b_createNewFigure' ) )
                        myInput.b_createNewFigure = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'b_normalizeCells' ) )
                        myInput.b_normalizeCells  = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'b_hardAssignment' ) )
                        myInput.b_hardAssignment  = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'w2c' ) )
                        myInput.w2c  = varargin{i+1};                        
                    end                    
                end     
            end
        end
        myInput.img                =  varargin{1};
    end
end