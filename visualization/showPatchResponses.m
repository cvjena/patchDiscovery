function showPatchResponses(imgfn, patches, settings)
% function showPatchResponses(imgfn, patches, settings)

    
    
    %% ( 1 ) compute representation for current image
    img      = readImage ( imgfn );
    pyraFeat = featPyramidGeneric( img, patches(1).model, settings );
    
    %% ( 2 ) perform convolutions off given image and all patch models
    bopResults = zeros( length(patches),1);
    bopBoxes = uint8( zeros( length(patches),4) );    
    
    [height,width,~]=size(img);
    
    for i=1:length(patches)
        p = patches(i);    
        boxes = detectWithGivenFeatures( pyraFeat, p.model, p.model.d_detectionThreshold);
        
        %remove results not fully located in the image
        boxes = boxes ( boxes(:,1) > 0      ,: );
        boxes = boxes ( boxes(:,2) > 0      ,: );
        boxes = boxes ( boxes(:,3) < width  ,: );
        boxes = boxes ( boxes(:,4) < height ,: );
        
        [val,idx] = max( boxes(:,5) );
        if ( ~isempty ( val ) )
            bopResults(i) = val;
            bopBoxes(i,:) =  boxes(idx,1:4);         
        end
    end
    
    %% ( 3 ) visual evaluation
    
    [~,perm] = sort(bopResults, 'descend');
    
    if ( ( ~isfield(settings,'i_noPatchesToShow'))  || isempty(settings.i_noPatchesToShow) )
        i_noPatchesToShow = 3;
    else
        i_noPatchesToShow = settings.i_noPatchesToShow;
    end
    
    i_noPatchesToShow = min ( i_noPatchesToShow, length(perm) );
    
    
    i_maxNoBlocksToShow = 5;
    
%     mySettings.b_waitForInput = false;
%     mySettings.b_closeImage = false;

    [height,~,~] = size(img);
    
    for i=1:i_noPatchesToShow
        fig = figure;
        s_title = sprintf('Response %i', i );            
        set ( fig, 'name', s_title);        
        
        currentBox = bopBoxes( perm ( i ), : );
        


        %[dist-to-left dist-to-top dist-to-left+width dist-to-top+height]
        imWithBoxes = drawBoxesToImg( img, currentBox );        
        
        s_score = sprintf('%f', bopResults ( perm ( i ) ) );        
 
        %[dist-to-left dist-to-bottom]
        imgWithText = addTextToImg ( imWithBoxes, s_score, [bopBoxes( perm ( i ), 1 ) height-bopBoxes( perm ( i ), 2 )+5] );
        
        imshow( imgWithText );
        
        %show the current patch in the orig image
        blocksFig=figure; 
        s_titleBlocks = sprintf('Blocks for patch %d', perm ( i ) );            
        set ( blocksFig, 'name', s_titleBlocks);  
        
        additionalInfosShowBlocks.b_closeImg        = false;
        additionalInfosShowBlocks.b_waitForInput    = false;
        additionalInfosShowBlocks.b_createNewFigure = false;
        showBlocks( patches( perm ( i ) ).blocksInfo, p.model, additionalInfosShowBlocks );
        
%         showResults ( patches, perm ( i ), mySettings );

%         hogFig=figure;
%         showHOG(patches( perm ( i ) ).model.w);           
%             
%         s_titleHoG = sprintf('Model for patch %d', perm ( i ));
%         set ( hogFig, 'name', s_titleHoG);



        pause
        
        close(fig);
        %close(hogFig);
        close(blocksFig);
    end    
    
end