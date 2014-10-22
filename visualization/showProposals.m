function showProposals( proposals, additionalInfos, dataset )
% function showProposals( proposals, additionalInfos, dataset )
% 
% author: Alexander Freytag
% last time modified: 24-02-2014 (dd-mm-yyyy)
% 
%  BRIEF:
%    ...
%
%  INPUT: 
%    proposals       - several blocks selected from images, most likely used 
%                      as positive samples to learn a patch detector from
%    additionalInfos - (optional), additional infos, such as 
%                      'additionalInfos', 'b_waitForInput', 
%                      'b_createNewFigure', 'i_maxNoProposalsToShow', 
%                      'b_showProposalsInLine'
    

    %% ( 1 ) get input
    if ( nargin < 3)
        dataset = [];
    end        
    
    if ( nargin < 2)
        additionalInfos = [];
    end    
   
    b_closeImg              = getFieldWithDefault ( additionalInfos, 'b_closeImg', false );
    
    b_waitForInput          = getFieldWithDefault ( additionalInfos, 'b_waitForInput', true );

    b_createNewFigure       = getFieldWithDefault ( additionalInfos, 'b_createNewFigure', true );    

    i_maxNoProposalsToShow  = getFieldWithDefault ( additionalInfos, 'i_maxNoProposalsToShow', 49 );    
   
    b_showProposalsInLine   = getFieldWithDefault ( additionalInfos, 'b_showProposalsInLine', true );    
    
    b_colorProposalsByClass = getFieldWithDefault ( additionalInfos, 'b_colorProposalsByClass', false );
    
    b_verbose               = getFieldWithDefault ( additionalInfos, 'b_verbose', true );
 
    
    cropsize = [ 80 , 80 ];
    
    %% ( 2 ) show blocks in image
    
    if ( b_verbose ) 
        s_msg = sprintf('Show current patch detectors\n');
        disp ( s_msg ) 
    end

   
    %show the current patch in the orig image
    if ( b_createNewFigure )
        blocksFig=figure; 
    end

    noProposals = length(proposals);
    % show at most 49 proposals - more is senseless, since (i) we
    % can't see anything anymore and (ii) plotting takes ages...
    noProposalsToShow = min ( noProposals, i_maxNoProposalsToShow);    
    
    if ( b_showProposalsInLine )
        maxi = noProposalsToShow;
    else
        maxi = ceil(sqrt( noProposalsToShow ));
    end
    
    if ( b_colorProposalsByClass )
        labels = dataset.labels ( [proposals.imgIdx] );
        labelsUnique = unique ( labels );
        i_numClasses = numel ( unique( labels ) );

        myColors = 255*distinguishable_colors( i_numClasses );
    end

    for blCnt=1:noProposalsToShow
        if ( b_showProposalsInLine )
            subplot(1,maxi,blCnt );
        else
            subplot(maxi,maxi,blCnt );
        end

        x1 = proposals(blCnt).box.x1;
        x2 = proposals(blCnt).box.x2;
        y1 = proposals(blCnt).box.y1;
        y2 = proposals(blCnt).box.y2;

        w=round( x2 - x1 );
        h=round( y2 - y1 );
        
        imgOrig  = readImage( proposals(blCnt).box.im );
        mySubImg = imcrop ( imgOrig, [x1,y1,w,h]);
        warpedSubImg = imresize(mySubImg, cropsize, 'bilinear', 'Antialiasing', false);
        
        if ( b_colorProposalsByClass )
            warpedSubImg = myPadArray ( warpedSubImg, 5, myColors( labelsUnique == labels(blCnt), : ) );
        end
        
        subimage ( warpedSubImg );  
        axis off     
        if ( b_verbose ) 
            scoreMsg = sprintf ( 'Score for proposal %d: %f', blCnt, proposals(blCnt).score);
            disp( scoreMsg )
        end
    end


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