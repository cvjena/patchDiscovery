function visualizedImg = visualizeColorNames ( varargin )
% function visualizedImg = visualizeColorNames ( varargin )
% 
% author: Alexander Freytag
% date  : 17-03-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   Visualizes a colorNamesFeature by creating an image, drawing meanValues
%   in every block, and overlaying a grid.
% 
% INPUT :
%    feature       --  double array of colorNamesFeature
%    2nd argument  --  (optional), either struct array with optional fields 'widthOfCell',
%                      'heightOfCell', b_showImage, 'b_closeImages', 'b_waitForInput', 
%                      'b_createNewFigure', 'b_normalizeCells',
%                      'b_hardAssignment'
%                      or
%         the following optional arguments are given instead (specified by string):
%
%    widthOfCell   --  (optional), number of px a block in y direction
%                      shall be painted, default: 50
%    heightOfCell  --  (optional), number of px a block in x direction
%                      shall be painted, default: 50
%    b_showImage    --  (optional), show the results on a figure or simply return the
%                      constructed image, default: true
%    b_closeImages --  (optional), if true, shown images are closed before
%                      ending the script, default: true
%    b_waitForInput --  (optional), if true, script is paused until user gives
%                      keyboard feedback, default: true
%    b_createNewFigure --  (optional), if false, the visualization will be 
%                      drawn into the current figure, if possible,
%                      default: true
%    b_normalizeCells --  (optional), if true, cells will be normalized to
%                      l1, being interpretable als probabilities
%                      default: false
%    b_hardAssignment --  (optional), if true, only nearest of 11 color
%                      names will be used for plotting
%                      default: true






    %% (1) check input
    
    myInput = parseInputs(varargin{:});
        
    %% (2) pre-process input
    
    % only accept positive entries here
    myInput.feature (myInput.feature < 0) = 0;
    
    % scale everything to useful range
    % TODO decide about whether to do this or not...
%     scale = max( myInput.feature ( : ) );
%     myInput.feature = myInput.feature ./ scale;
      
    % if desired, map to l1 norm
    if ( myInput.b_normalizeCells )
        % compute L1 norm of every cell
        normColorNames = sum(myInput.feature, 3);
        % avoid division by zero
        normColorNames(normColorNames < eps) = 1;
        % L1-normalize
        myInput.feature = bsxfun(@rdivide, myInput.feature, normColorNames);
    end
    
 
       
    %% (4) visualize results

    [height, width, ~] = size ( myInput.feature ) ;
        
    imgPatches = zeros ( [myInput.heightOfCell*height, width*myInput.widthOfCell, 3], 'double' );
    
    % from im2c.m
    % order of color names: black ,   blue   , brown       , grey       , green   , orange   , pink     , purple  , red     , white    , yellow
    color_values =     {  [0 0 0] ; [0 0 1] ; [.5 .4 .25] ; [.5 .5 .5] ; [0 1 0] ; [1 .8 0] ; [1 .5 1] ; [1 0 1] ; [1 0 0] ; [1 1 1 ] ; [ 1 1 0 ] };    
    

    
    if ( myInput.b_hardAssignment ) 
        
        [~,w2cM]=max( myInput.feature,[],3);  
        for  j = 1:height
            for  i = 1:width
                    imgPatches ( myInput.heightOfCell*(j-1) + 1:myInput.heightOfCell*(j), ...
                                 myInput.widthOfCell*(i-1)  + 1:myInput.widthOfCell*(i), :) ...
                                 = repmat( reshape(color_values { w2cM(j,i)}', [1,1,3]) , [myInput.heightOfCell, myInput.widthOfCell,1]);
            end
        end   
    else
        for  j = 1:height
            for  i = 1:width
                rgbResult = sum ( cell2mat ( color_values ) .* repmat ( reshape( myInput.feature(j,i,:), [11,1]), [1,3]), 1);

                imgPatches ( myInput.heightOfCell*(j-1) + 1:myInput.heightOfCell*(j), ...
                             myInput.widthOfCell*(i-1)  + 1:myInput.widthOfCell*(i), :) ...                
                             = repmat( reshape(rgbResult, [1,1,3]) , [myInput.heightOfCell, myInput.widthOfCell,1]);
            end
        end
        
    end
    
    % draw kachel-optik
    
    %# Change every yth row to black
    imgPatches( myInput.widthOfCell:myInput.widthOfCell:end,:,:)   = 0;      
    %# Change every xth column to black
    imgPatches( :,myInput.heightOfCell:myInput.heightOfCell:end,:) = 0;    
   
    
    if ( myInput.b_showImage && myInput.b_createNewFigure )
        % create new figure
        figPatches = figure;
    
        % nice title
        s_titlePatches = sprintf('Patch Means' );            
        set ( figPatches, 'name', s_titlePatches);  
    end
    
    % computeMeanPatches outputs features normalized to [0,1] per dimension
    if ( myInput.b_showImage )
        imshow ( uint8(255*imgPatches) );
    end
   
    %% (5) wait for user input
    
    if ( myInput.b_showImage && myInput.b_waitForInput )
        pause
    end
   
    % close corresponding images
    if ( myInput.b_showImage && myInput.b_closeImages && myInput.b_createNewFigure )    
        close ( figPatches );
    end
    
    if ( nargout > 0 )
        visualizedImg = imgPatches;
    end

end

function myInput = parseInputs(varargin)

    % default: plot every cell to be of width 50px
    myDefaults.widthOfCell         =  50;
    
    % default: plot every cell to be of height 50px
    myDefaults.heightOfCell        =  50;
    
    % default: close images after user input
    myDefaults.b_showImage         =  true;
    
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

    if ( nargin < 1 )
        disp('wrong number of input arguments specified!')
    elseif ( nargin < 2 )
        myInput                    = myDefaults;
        myInput.feature            =  varargin{1};
    else
        if isstruct( varargin{2} )
            
            myInput.widthOfCell       = getFieldWithDefault ( varargin{2}, 'widthOfCell', myDefaults.widthOfCell);
            
            myInput.heightOfCell      = getFieldWithDefault ( varargin{2}, 'heightOfCell', myDefaults.heightOfCell);            
            
            myInput.b_showImage       = getFieldWithDefault ( varargin{2}, 'b_showImage', myDefaults.b_showImage);
            
            myInput.b_closeImages     = getFieldWithDefault ( varargin{2}, 'b_closeImages', myDefaults.b_closeImages);
            
            myInput.b_waitForInput    = getFieldWithDefault ( varargin{2}, 'b_waitForInput', myDefaults.b_waitForInput );
            
            myInput.b_createNewFigure = getFieldWithDefault ( varargin{2}, 'b_createNewFigure', myDefaults.b_createNewFigure);            
            
            myInput.b_normalizeCells  = getFieldWithDefault ( varargin{2}, 'b_normalizeCells', myDefaults.b_normalizeCells);
            
            myInput.b_hardAssignment  = getFieldWithDefault ( varargin{2}, 'b_hardAssignment', myDefaults.b_hardAssignment );
            
        else
            if ( mod( nargin-1, 2 ) ~= 0 )
                disp('visualizeColorNames -- No varnames specified. Ignoring further specifications, use default values...')
            else
                % set defaults
                myInput                           = myDefaults;
                % now check for explicitely specified settings
                for i=2:2:nargin
                    if ( strcmp ( varargin{i},     'widthOfCell' ) )
                        myInput.widthOfCell       = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'heightOfCell' ) )
                        myInput.heightOfCell      = varargin{i+1};
                    elseif ( strcmp ( varargin{i}, 'b_showImage' ) )
                        myInput.b_showImage       = varargin{i+1};
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
                    end                    
                end     
            end
        end
        myInput.feature =  varargin{1};
    end
end