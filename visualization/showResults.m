function showResults( patches, indicesToShow, additionalInfos )
% function showResults( patches, indicesToShow, additionalInfos )
% 
% author: Alexander Freytag
% last time modified: 27-02-2014 (dd-mm-yyyy)
%
% INPUT: 
%    patches         - patches from patch discovery, struct
%    indicesToShow   - (optional), vector of indices specifying which
%                      patches to visualize
%    additionalInfos - (optional, can also be the 2nd argument), additional
%                      infos, such as 'entropyScores', 'b_closeImg', 
%                      'b_waitForInput', 'b_savePatchImage', 's_patchImageDestination'
%                      'b_showBlocksInLine', 'b_sortPatchesByNumBlocks', 'patchScores',
%                      'fh_featureVisualization', 


    %% ( 1 ) get input
    if ( nargin < 3)
        additionalInfos = [];
    end  
    
    if ( nargin < 2)
        indicesToShow = [];
    end    
    
    % was no second argument given, but the third one instaed?
    if ( ~isa(indicesToShow,'float') && isa(indicesToShow,'struct'))
        additionalInfos = indicesToShow;
        indicesToShow = [];
    end
    
    if ( isempty(indicesToShow) )
        indicesToShow = 1:length(patches);
    end
    
    
    b_closeImg               = getFieldWithDefault ( additionalInfos, 'b_closeImg', true );
    
    b_waitForInput           = getFieldWithDefault ( additionalInfos, 'b_waitForInput', true );
    
    % do we want to save patch visualizations and/or model visualization?
    b_savePatchImage         = getFieldWithDefault ( additionalInfos, 'b_savePatchImage', false );
    b_saveModelImage         = getFieldWithDefault ( additionalInfos, 'b_saveModelImage', false );
    
    % should be a path to a proper directory, which will be created if
    % non-existing
    s_patchImageDestination  = ...
        getFieldWithDefault ( additionalInfos, 's_patchImageDestination', ['/users/tmp/' getenv('USER') '/'] );
    
    b_showBlocksInLine       = getFieldWithDefault ( additionalInfos, 'b_showBlocksInLine', false );
    
    i_maxNoBlocksToShow      = getFieldWithDefault ( additionalInfos, 'i_maxNoBlocksToShow', 49 );
            
    
    b_sortPatchesByNumBlocks = getFieldWithDefault ( additionalInfos, 'b_sortPatchesByNumBlocks', true );
    
    
    fh_featureVisualization  = getFieldWithDefault ( additionalInfos, 'fh_featureVisualization', [] );    
    
    s_convergenceFlag        = getFieldWithDefault ( additionalInfos, 's_convergenceFlag', 'all' );  % options: 'converged only', 'not converged only', everything else
        
  
    b_computeMeanImage       = getFieldWithDefault ( additionalInfos, 'b_computeMeanImage', true );
    
    
    %% 1.1 check whether output directory exists if needed
    if ( (b_savePatchImage || b_saveModelImage) && ~exist( s_patchImageDestination, 'dir') )
        mkdir ( s_patchImageDestination );
    end
   
    
    %% ( 2 ) pre-process order of patches
    
    if ( strcmp ( s_convergenceFlag, 'converged only' ) )
        indicesToShow = indicesToShow ( [patches(indicesToShow).isConverged] ); 
    elseif ( strcmp ( s_convergenceFlag, 'not converged only' ) )
        indicesToShow = indicesToShow ( ~ [patches(indicesToShow).isConverged] ); 
    else
        % nothing to do here
        % indicesToShow = indicesToShow; 
    end    
    
    %sort indices according to number of blocks used
    if ( b_sortPatchesByNumBlocks ) 
        [sortVal, sortIdx ] = sort ( cellfun ( @length, {patches(indicesToShow).blocksInfo}), 'descend' );
        indicesToShow = indicesToShow(sortIdx);
    end
    

   
    
    %% ( 3 ) show all patches in specified order, including their blocks and models
    
    disp('Show current patch detectors')
    
    for i=1:length(indicesToShow)
                
        myIndex = indicesToShow(i);
        
        if isfield( additionalInfos,'patchScores' )
             statusMsg = sprintf( 'Patch ranked as (%i) -- score: %i\n',myIndex, additionalInfos.patchScores( myIndex ));
             disp(statusMsg);        
        end
           
        if ( ~isempty ( fh_featureVisualization ) )
            
            modelFig=figure;
            modelVec = patches( myIndex ).model.w;
            if ( isfield ( fh_featureVisualization, 'settings' ) )
                settingsFeatVis = fh_featureVisualization.settings;
            else
                settingsFeatVis = [];
            end
                
            imgModel = fh_featureVisualization.mfunction( modelVec, settingsFeatVis );
            imshow ( imgModel );
            
  
            s_titleModle = sprintf('Model for patch %d', myIndex);
            set ( modelFig, 'name', s_titleModle);
        end
           
        
         %show the current patch in the orig image
         blocksFig=figure; 
         s_titleBlocks = sprintf('Blocks for patch %d', myIndex );            
         set ( blocksFig, 'name', s_titleBlocks);
            
         additionalInfosShowBlocks.b_closeImg          = false;
         additionalInfosShowBlocks.b_waitForInput      = false;
         additionalInfosShowBlocks.b_createNewFigure   = false;   
         additionalInfosShowBlocks.i_maxNoBlocksToShow = i_maxNoBlocksToShow;
         additionalInfosShowBlocks.b_showBlocksInLine  = b_showBlocksInLine;
            
         showBlocks( patches( myIndex ).blocksInfo, patches( myIndex ).model, additionalInfosShowBlocks )
         
         if ( b_computeMeanImage ) 
            meanImg = computeMeanImageFromBlocks ( patches( myIndex ).blocksInfo, patches( myIndex ).model );
            figMeanImg = figure;
            imshow ( uint8( meanImg ) );
            
            s_titleMean = sprintf('Mean patch image for %d', myIndex);
            set ( figMeanImg, 'name', s_titleMean);            
         end
         
         
            
   
          if ( b_savePatchImage )
               s_filename = sprintf('%spatchBlocks_%07d.png',s_patchImageDestination, myIndex);
               set(blocksFig,'PaperPositionMode','auto')
               print(blocksFig, '-dpng', s_filename);
          end
          
          if ( b_saveModelImage && ~isempty ( fh_featureVisualization ) )
               s_filename = sprintf('%spatchModel_%07d.png',s_patchImageDestination, myIndex);
               set(modelFig,'PaperPositionMode','auto')
               print(modelFig, '-dpng', s_filename);
          end          

           %% ( 4 ) wait for user input
           
           %wait for user response and close everything before
           %continuing
           if ( b_waitForInput )
            pause;
           end
           
           if ( b_closeImg )
               if ( ~isempty ( fh_featureVisualization ) )
                   close(modelFig);
               end
                close(blocksFig);   
                if ( exist( 'figMeanImg', 'var' ) )
                    close( figMeanImg );
                end
           end
    end

end
