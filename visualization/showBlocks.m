function showBlocks( blocks, model, additionalInfos )
% function showBlocks( blocks, model, additionalInfos )
% 
% author: Alexander Freytag
% last time modified: 14-02-2014 (dd-mm-yyyy)
% 
%  BRIEF:
%    Warp given blocks to specified size, arrange them in a single figure,
%    and show the figure to a user. Among others, useful for checking which
%    blocks have been chosen to form a patch detector.
%
%  INPUT: 
%    blocks          - several blocks selected from images, most likely used 
%                      as positive samples to learn a patch detector from
%    model           - (optional), only needed to warp blocks to proper
%                      size wrt to size of model.w and number of grid cells
%    additionalInfos - (optional), additional infos, such as 
%                      'additionalInfos', 'b_waitForInput', 
%                      'b_createNewFigure', 'i_maxNoBlocksToShow', 
%                      'b_showBlocksInLine'
    

    %% ( 1 ) get input
    if ( nargin < 3)
        additionalInfos = [];
    end    
   
    
    b_closeImg          = getFieldWithDefault ( additionalInfos, 'b_closeImg', false );
    
    b_waitForInput      = getFieldWithDefault ( additionalInfos, 'b_waitForInput', true );    
     
    b_createNewFigure   = getFieldWithDefault ( additionalInfos, 'b_createNewFigure', true );
    
    i_maxNoBlocksToShow = getFieldWithDefault ( additionalInfos, 'i_maxNoBlocksToShow', 49 ); 
    
    b_showBlocksInLine  = getFieldWithDefault ( additionalInfos, 'b_showBlocksInLine', true );
    
    
    %% ( 2 ) show blocks in image
       
    %show the current patch in the orig image
    if ( b_createNewFigure )
        blocksFig=figure; 
    end

    noBlocks = length(blocks);
    % show at most 49 blocks - more is senseless, since (i) we
    % can't see anything anymore and (ii) plotting takes ages...
    noBlocksToShow = min ( noBlocks, i_maxNoBlocksToShow);    
    
    if ( b_showBlocksInLine )
        maxi = noBlocksToShow;
    else
        maxi = ceil(sqrt( noBlocksToShow ));
    end

    if ( nargin > 2)
        warpedTrainBlocks = warpBlocksToStandardSize ( model, [ blocks.box] );
    else
        warpedTrainBlocks = blocks;
    end
    
    i_blockHeight   = size ( warpedTrainBlocks{1}, 1 );
    i_blockWidth    = size ( warpedTrainBlocks{1}, 2 );            
    i_blockDim      = size ( warpedTrainBlocks{1}, 3 );
    s_classOfBlocks = class( warpedTrainBlocks{1} );
    
    %note: we could also determine this based an mean of image values
    vPad = 127;
    
    if ( b_showBlocksInLine )
        % manually pad all images together
        % reason: figure fits nicely to images :)
        
        % a bit of padding for nice visualization
        buff = 2;        
        % assumption: warped images have all same size
        widthOfPaddedBlock  = 2*buff + i_blockWidth;
        heightOfPaddedBlock = 2*buff + i_blockHeight;
        width  = noBlocksToShow*widthOfPaddedBlock;
        height = heightOfPaddedBlock;
        
        im = zeros ( height, width, i_blockDim, s_classOfBlocks );
        for blCnt=1:noBlocksToShow
            yStart = 1;
            yEnd   = heightOfPaddedBlock;
            xStart = (blCnt-1)*heightOfPaddedBlock+1;
            xEnd   = (blCnt)*widthOfPaddedBlock;

            % write padded image to desired place
            if ( i_blockDim == 3 )  
                im ( yStart : yEnd, xStart : xEnd, : ) =  ...
                    myPadArray ( warpedTrainBlocks{blCnt}, [buff buff, 0 ], vPad );
            else
                im ( yStart : yEnd, xStart : xEnd ) =  ...
                    myPadArray ( warpedTrainBlocks{blCnt}, [buff buff ], vPad );
            end             
        end
   
    else           
        % own padded version, manually pad all images together
        % reason: figure fits nicely to images :)

        % a bit of padding for nice visualization
        buff = 2;        
        % assumption: warped images have all same size
        widthOfPaddedBlock  = 2*buff + i_blockWidth;
        heightOfPaddedBlock = 2*buff + i_blockHeight;
        width  = maxi*widthOfPaddedBlock;
        height = ceil(noBlocksToShow/maxi)*widthOfPaddedBlock;

        im = zeros ( height, width, i_blockDim, s_classOfBlocks );
        for blCnt=1:noBlocksToShow
            yStart = (floor( (blCnt-1)/maxi)  ) *heightOfPaddedBlock+1;
            yEnd   = (floor( (blCnt-1)/maxi)+1) *heightOfPaddedBlock;
            xStart = (mod(blCnt-1,maxi))*widthOfPaddedBlock+1;
            xEnd   = (mod(blCnt-1,maxi)+1) *widthOfPaddedBlock;

            % write padded image to desired place
            if ( i_blockDim == 3 )  
                im ( yStart : yEnd, xStart : xEnd, : ) =  ...
                    myPadArray ( warpedTrainBlocks{blCnt}, [buff buff, 0 ], vPad );
            else
                im ( yStart : yEnd, xStart : xEnd ) =  ...
                    myPadArray ( warpedTrainBlocks{blCnt}, [buff buff ], vPad );
            end                
        end
    
    end
    

    iptsetpref('ImshowBorder','tight');
    iptsetpref('ImshowAxesVisible','off');
    imshow ( im, []) ;        

    %make images beeing displayed correctly, i.e., not skewed
    axis image;
    %don't show axis ticks
    set(gca,'Visible','off');



    %% ( 3 ) wait for user input
    
    %wait for user response and close everything before
    %continuing
    if ( b_waitForInput )
        pause;
    end
    
    if ( b_closeImg && b_createNewFigure )
        close(blocksFig);
    end

end