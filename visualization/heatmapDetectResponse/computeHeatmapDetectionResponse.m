function figHandle = computeHeatmapDetectionResponse ( s_filename, bopFeatures, settings, figHandle, i_imgIdx )
% 
% author: Alexander Freytag
% date  : 08-05-2014 ( dd-mm-yyyy )
% 
%  BRIEF:
%     Given detection responses from a set of detectors on an image, i.e., 
%     precomputed bag-of-part features, we color-out those region with low
%     detection responses.
% 
%  INPUT: 
%     s_filename  -- filename to the image
%     bopFeatures -- figure handle
%     settings    -- (optional) struct with fields such as 'b_saveResults', 
%                    's_dirResults', 'b_waitForInput', 'b_closeImage'
%     figHandle   -- (optional) external figure handle
% 
%  OUTPUT: 
%     figHandle   -- (optional) figure handle
% 

    if ( (nargin < 5 )  || isempty ( i_imgIdx ) )
        i_imgIdx = 1;
    end

    if ( (nargin < 4 )  || isempty ( figHandle ) )
        figHandle = figure;
    end
    
    if ( nargin < 3 ) 
        settings = [];
    end   
    
    
    b_saveResults  = getFieldWithDefault ( settings, 'b_saveResults', false );
    s_dirResults   = getFieldWithDefault ( settings, 's_dirResults', './heatmaps/' );    
    b_waitForInput = getFieldWithDefault ( settings, 'b_waitForInput', false );
    b_closeImage   = getFieldWithDefault ( settings, 'b_closeImage', true );
    
    b_adaptRatio   = getFieldWithDefault ( settings, 'b_adaptRatio', false );
    d_desiredRatio = getFieldWithDefault ( settings, 'd_desiredRatio', 1.0 );    
    

    %%
    % show orig image
    figOrig = figure;
    % read current image
    img = imread( s_filename );    
    
    if ( b_adaptRatio ) 
        d_ratioIs   = size(img,1) / double(size(img,2) );

        if( d_ratioIs < d_desiredRatio )
            % orig image is 'flater' than desired aspect ratio
            % -> scale y axis larger, or x axis smaller

            % we scale x axis smaller, since removing
            % information is easier then hallucinating new info

            i_numRows = size(img,1);
            i_numCols = round ( d_ratioIs/d_desiredRatio * size(img,2) );

        else
            % orig image is 'higher' than desired aspect ratio
            % -> scale y axis smaller, or x axis higher

            % we scale y axis smaller, since removing
            % information is easier then hallucinating new info

            i_numRows = round ( d_desiredRatio/d_ratioIs * size(img,1) );
            i_numCols = size(img,2);
        end

        img = imresize ( img, [i_numRows i_numCols] );
    end     
    
    i_sizeX = size ( img, 2 );
    i_sizeY = size ( img, 1 );
    
    imshow( img );    
    
    % convert image into gray scale - will be colored lateron depending on
    % the detection responses
    set(0,'CurrentFigure',figHandle);    
    imgGray = rgb2gray(img );
    hold on
    h = imshow( imgGray ); % Save the handle; we'll need it later
    hold off    

    % compute heat map based on detection responses
    myScoreMap = zeros( [size(img,1), size(img,2)]);
    
    % Are the bop features from training or test images? Only names of
    % fields differ...
    if ( isfield ( bopFeatures, 'posOfBoxTrain' ) )       
        % round just to be sure that indices are int-valued
        posOfBox        = round( bopFeatures.posOfBoxTrain );
        bopFeaturesFeat = bopFeatures.bopFeaturesTrain;
    elseif (isfield ( bopFeatures, 'posOfBoxTest' ) )
        % round just to be sure that indices are int-valued
        posOfBox        = round( bopFeatures.posOfBoxTest );
        bopFeaturesFeat = bopFeatures.bopFeaturesTest;        
    elseif (isfield ( bopFeatures, 'posOfBox' ) )
        % round just to be sure that indices are int-valued
        
        %FIXME reshaping is a nasty hack here...
        posOfBox        = reshape ( round( bopFeatures.posOfBox ), [size(bopFeatures.posOfBox,1),1,size(bopFeatures.posOfBox,2)]);
        bopFeaturesFeat = reshape ( bopFeatures.detectorScores, [1, size(bopFeatures.detectorScores,1)]);           
    else
        disp('No boxes for detection responses given... aborting heat map visualization!')
        return
    end
    
    % Go over all responses and add the score to the covered image region
    for bIdx=1:size(posOfBox,1)
        y1 = max( 1, posOfBox(bIdx,i_imgIdx,2) );
        x1 = max( 1, posOfBox(bIdx,i_imgIdx,1) );
        y2 = min( i_sizeY, posOfBox(bIdx,i_imgIdx,4) );
        x2 = min( i_sizeX, posOfBox(bIdx,i_imgIdx,3) );

        myScoreMap(y1:y2,x1:x2) = myScoreMap(y1:y2,x1:x2) + bopFeaturesFeat(i_imgIdx,bIdx);
    end
    
    % visualize heat map
    h_scoreImg = imagesc( myScoreMap );
    colormap('Jet')
    
    % Use our influence map image as the AlphaData for the heatmap score
    % image
    set(h_scoreImg, 'AlphaData', imgGray)
    
    % remove gray border and further nasty stuff from image
    posX = 100;
    posY = 100;
    set(gcf,'Position',[posX posY size(img,2) size(img,1)]);
    set(gca,'units','pixels');
    set(gca,'units','normalized','position',[0 0 1 1]);
    axis off;
    axis tight;    
    
    % do we want to print the image somewhere?
    if ( b_saveResults )
        
        % check that output directory exists if desired
        if ( b_saveResults && (~exist( s_dirResults, 'dir') ) )
            mkdir ( s_dirResults );
        end        
        
        idxSlash        = strfind( s_filename ,'/');    
        idxDot          = strfind ( s_filename, '.' );
        s_imgName       = s_filename( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
        idxDotImagename = strfind ( s_imgName, '.' );
        s_imgName(idxDotImagename) = '_';            
            
        s_className     = s_filename( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );                    
        idxDotClassname = strfind ( s_className, '.' );
        s_className(idxDotClassname) = '_';
                        
        s_filenameOrig  = sprintf( '%simg_%s_%s-orig.png', s_dirResults, s_className, s_imgName );
        
        set(figOrig,'PaperPositionMode','auto')
        print(figOrig, '-dpng', s_filenameOrig);   
        
        
                
        s_filenameHeat  = sprintf( '%simg_%s_%s.png', s_dirResults, s_className, s_imgName );
        
        set(figHandle,'PaperPositionMode','auto')
        print(figHandle, '-dpng', s_filenameHeat);        
    end
    
    % and wait for user input :)
    if ( b_waitForInput )
        pause        
    end

    % close images or leave them open?
    if ( b_closeImage )
        if ( nargout  == 0 )
            close ( figHandle );
        end
        close ( figOrig );    
    end
    
end