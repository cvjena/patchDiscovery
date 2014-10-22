function blockProposals = convolutionByPyramids ( settingsExpansionSelection, dataset, patches )
% function blockProposals = convolutionByPyramids ( settingsExpansionSelection, dataset, patches )  
% 
%  BRIEF: 
%       convolve patches with images by basically calling fconv for every
%       position and scale of an image and every patch detector
%  NOTE: If ( patches(i).isConverged ), the ith patch will be ommited. 
% 
% author: Alexander Freytag
% date:   05-02-2014 (dd-mm-yyyy)

    %% ( 0 ) init output data
    
    %blockProposals = repmat ( struct ('score', mat2cell(-Inf*ones(settingsExpansionSelection.i_K,1),repmat(1,settingsExpansionSelection.i_K,1),1)' , 'box',{[]} , 'imgIdx',{[]} , 'feature',{[]}, 'seedIdx', {[]}), [length(patches),2*settingsExpansionSelection.i_K]);
    %blockProposals = repmat ( struct ('proposals', repmat (struct ('score', mat2cell(-Inf*ones(settingsExpansionSelection.i_K,1),repmat(1,settingsExpansionSelection.i_K,1),1)' , 'box',{[]} , 'imgIdx',{[]} , 'feature',{[]}, 'seedIdx', {[]}), [2*settingsExpansionSelection.i_K, 1]) ), [length(patches),1] );
    blockProposals = repmat ( struct ('proposals', repmat (struct ('score', {[-Inf]} , 'box',{[]} , 'imgIdx',{[]} , 'feature',{[]}, 'seedIdx', {[]}), [2*settingsExpansionSelection.i_K, 1]) ), [length(patches),1] );
    
    
    %blockProposals = repmat ( struct ('score', mat2cell(-Inf*ones(settingsExpansionSelection.i_K,2),repmat(1,settingsExpansionSelection.i_K,1),2)' , 'box',{[]} , 'imgIdx',{[]} , 'feature',{[]}, 'seedIdx', {[]}), [length(patches),1]);
    
    

    % %(1) we do the convolution on our own
    for j=length(dataset.trainImages):-1:1
        if ( settingsExpansionSelection.b_verbose )
            statusMsg = sprintf( '   evaluating trainImg %i / %i',j, length(dataset.trainImages));
            disp(statusMsg);
            myTic = tic;
        end

        imgfn = dataset.images{ dataset.trainImages(j) };
        currentImg  = readImage(imgfn);

        %the information used here obtained from the models are the same for all models        
        pyraFeat = featPyramidGeneric( currentImg, patches(1).model, settingsExpansionSelection );
        

        [heightImg, widthImg, ~] =size(currentImg);
        
        % if masking is needed, we load the mask image already here and use
        % it for all patches.
        % In addition, the integral image can be pre-computed here.
        if ( settingsExpansionSelection.b_maskImages )
            mask           = readMask( imgfn );
            maskIntegral   = cumsum(cumsum(mask,2),1);
        end

        for i=length(patches):-1:1

            p = patches(i);

            if ( p.isConverged )
                continue;
            end        

            % do we only want to work on images of the same category? if so,
            % check the label of the current img here and only run those
            % detectors which are steming from the same class
            % 
            % since detectors can have blocks from several classes, we
            % check for sets of labels
            
            if ( settingsExpansionSelection.b_supervisedBootstrapping )
                if ( ~ismember( p.label, dataset.labels ( dataset.trainImages( j ) ) ) )
                    continue;
                end
            end


            %run detector over image
            boxes = detectWithGivenFeatures( pyraFeat, p.model, p.model.d_detectionThreshold);

            %first of all, check which of the responses have larger scores than our currently used blocks
            boxes = boxes ( boxes(:,5) > p.minScore, : );

            % get rid of boxes that are not completely in the image
            goodBoxIdx = (  (boxes(:,1) > 0 ) & (boxes(:,2) > 0 ) & (boxes(:,3) <= widthImg ) & (boxes(:,4) <= heightImg ) );
            boxes = boxes( goodBoxIdx, : );
            clear goodBoxIdx;
            
            % BRING BOXES TO INT-VALUES, NEEDED FOR PROPER INDEXING
            boxes(:,1:4) = round ( boxes(:,1:4) );
            
            % NEW: 
            % also get rid of the boxes which overlap with currently used
            % training samples of this patch detector
            if ( settingsExpansionSelection.b_noOverlapInBootstrapping )
                
                % which training samples of p are from the current image?
                idxOfSameImg = ismember( [ p.blocksInfo.imgIdx ], dataset.trainImages(j) );
                if ( sum(idxOfSameImg) > 0 )
                
                     patchBoxes = [ p.blocksInfo(idxOfSameImg).box ];
                     myX1 = [ patchBoxes.x1 ];
                     myY1 = [ patchBoxes.y1 ];
                     myX2 = [ patchBoxes.x2 ];
                     myY2 = [ patchBoxes.y2 ];
                     % for debugging...
                     %myBoxes =  [myX1; myY1; myX2; myY2]'
                     %figure; showboxes ( currentImg, myBoxes );
                     %showResults ( p );

                     %two rectangles overlap if: 
                     %    ( max(x1, x1') < min(x2, x2') ) 
                     %                  AND 
                     %    ( max(y1, y1') < min(y2, y2') )    
                         
                     maxX1 = arrayfun ( @(x) max(x,myX1), boxes(:,1),  'UniformOutput', false);
                     maxY1 = arrayfun ( @(x) max(x,myY1), boxes(:,2),  'UniformOutput', false);
                     minX2 = arrayfun ( @(x) min(x,myX2), boxes(:,1)+boxes(:,3),  'UniformOutput', false);
                     minY2 = arrayfun ( @(x) min(x,myY2), boxes(:,1)+boxes(:,4),  'UniformOutput', false);

                     overlapBoxIdx = ...
                         (cell2mat(maxX1) < cell2mat(minX2)) ...
                            & ...
                         (cell2mat(maxY1) < cell2mat(minY2));
                         %max ( myX1, boxes(:,1) ) < min ( myX2, (boxes(:,1)+boxes(:,3)) ) ...
                         %   & ...
                         %max ( myY1, boxes(:,2) ) < min ( myY2, (boxes(:,2)+boxes(:,4)) );

                     boxes = boxes( ~any(  overlapBoxIdx,2 ), : );

                end
                
                
            end
            
            if ( settingsExpansionSelection.b_maskImages && ~isempty(boxes) )
                try                     
                    
%                     %%% FIRST VERSION -- CHECK THAT CENTER IS IN MASK
%                     boxesCenter =  uint16( round ( ...
%                                           [ ( boxes(:,4) - boxes(:,2) ) /2, ... % center in width
%                                             ( boxes(:,3) - boxes(:,1) ) /2 ...
%                                           ]  )) ;   % center in height        
%                     % check whether center of response is in mask image,
%                     % if not, delete it
%                     idxBoxesInMask = ( mask (  sub2ind ( size ( mask), boxesCenter(:,1), boxesCenter ( :,2) ) ) == 1);
% %                     idxBoxesInMask = ( mask( boxesCenter(:,1),  boxesCenter(:,2) ) == 0);
%                     boxes = boxes ( idxBoxesInMask, : ); 

                    
                    %%% SECOND VERSION -- CHECK THAT >=1 px OF BOX ARE IN
                    %%% MASK
                    % efficient version with integral images
                    p_lu = [max(1,boxes(:,1)),            max(1,boxes(:,2)) ];%left upper
                    p_ll = [max(1,boxes(:,1)),            min(size(mask,2),boxes(:,4))];%left lower
                    p_ru = [min(size(mask,1),boxes(:,3)), max(1,boxes(:,2))];%right upper
                    p_rl = [min(size(mask,1),boxes(:,3)), min(size(mask,2),boxes(:,4))];%right lower
                    
                    lu_cumsum = maskIntegral (  sub2ind ( size ( mask), p_lu(:,2), p_lu ( :,1) ) );
                    ll_cumsum = maskIntegral (  sub2ind ( size ( mask), p_ll(:,2), p_ll ( :,1) ) );
                    ru_cumsum = maskIntegral (  sub2ind ( size ( mask), p_ru(:,2), p_ru ( :,1) ) );
                    rl_cumsum = maskIntegral (  sub2ind ( size ( mask), p_rl(:,2), p_rl ( :,1) ) );

                    % compute resulting number of foreground pixel
                    % covered by current box
                    numPxFG = lu_cumsum + rl_cumsum - ll_cumsum - ru_cumsum;
                    boxes = boxes ( numPxFG > 0, : );                     
                catch err
                    if ( settingsExpansionSelection.b_verbose )
                        disp ( 'No masking information available!')
                    end
                end
            end

            % now, take the top K responses (we look in every image for the top K responses, collect/filter them all, and finally pick the top K of them)
            %
            % note:
            % in order to save memory, we just keep the top K responses for a detector from the already processed images, and no more
            % therefore, check here whether in the current image there have been some responses with larger scores than among the top K from the already
            % processed images   

            if ( ~isempty(boxes) )
                %blockProposalsImg = getTopKNotOverlappingResponses( boxes, settingsExpansionSelection.i_K, dataset.trainImages(j), imgfn );
                
                topBoxes = nms(boxes, 0.0);
                topBoxes = topBoxes (1:min(size(topBoxes,1), settingsExpansionSelection.i_K),:);
                
            else
                % no boxes left to check, so continue with the next detector
                % (or the next image for the current detector)
                continue
            end

            for idxBox=1:size(topBoxes,1)
                blockProposals(i).proposals(idxBox+settingsExpansionSelection.i_K) = ...
                    struct ('score',{topBoxes(idxBox,5)}, 'box',{ struct('im',imgfn,'x1',topBoxes(idxBox,1),'y1',topBoxes(idxBox,2),'x2',topBoxes(idxBox,3),'y2',topBoxes(idxBox,4) ) }, ...
                    'imgIdx',{dataset.trainImages(j)} , 'feature',{[]}, 'seedIdx', {[]});
            end

%              blockProposals = [ blockProposals newBlock ];    

%             [~,perm]=sort( [blockProposals(i,:).score], 'descend' ); 
%             blockProposals(i,:) = blockProposals(i, perm );
            [~,perm]=sort( [blockProposals(i).proposals.score], 'descend' ); 
            blockProposals(i).proposals = blockProposals(i).proposals( perm );
             
             

%             blockProposals(i).proposals  = [blockProposals(i).proposals blockProposalsImg ];

%             if ( length ( blockProposals(i).proposals ) > settingsExpansionSelection.i_K)
%                 %sort together previous results and results from current image       
%                 [~,perm]=sort( [blockProposals(i).proposals.score], 'descend' );  
% 
%                 % and take only the top K of them
%                 blockProposals(i).proposals  = blockProposals(i).proposals ( perm(1:settingsExpansionSelection.i_K) );
%             end

        end
        
        if ( settingsExpansionSelection.b_verbose )
            myTime = toc(myTic);
            statusMsg = sprintf( '       time for trainImg %i / %i: %f',j, length(dataset.trainImages), myTime);
            disp(statusMsg);            
        end        
    end
    
    
    for i = 1:length(blockProposals)
        % take only the top K of them
        blockProposals(i).proposals = blockProposals(i).proposals(1:settingsExpansionSelection.i_K);
        %  check that scores are > -Inf
        blockProposals(i).proposals ( [blockProposals(i).proposals.score] == -Inf ) = [];
    end    
    %blockProposals = blockProposals(:,1:settingsExpansionSelection.i_K);
    
    
    
    
end

function blockProposals = getTopKNotOverlappingResponses( boxes, i_K, imgIdx, imgfn )

    % no boxes given to chose from
    if ( isempty(boxes) )
        return;
    end
      
    % init output struct
    blockProposals = struct ('score',{}, 'box',{} , 'imgIdx',{} , 'feature',{}, 'seedIdx', {});
    
    
    topBoxes = nms(boxes, 0.0);
    topBoxes = topBoxes (:,1:min(size(topBoxes,2),i_K));
    

    for i = 1 : i_K
      redundant = true;
      
      % we search until we found the index of a block proposal which is
      % non-overlapping with one of the training blocks, or until no
      % possible block proposal is available anymore
      %
      % -> non-maximum suppression
      
      %NOTE: think about smoothing the detection results first
      
      while ( redundant )
         [ maxVal, blockIdx ] = max( boxes(:,5) );
         
         if ( maxVal == -Inf )
             %no possible solutions left
             return;
         end

            
         doesOverlap = false;
         for j=1:length(blockProposals)
             
%             doesOverlap = checkOverlap ( blockProposals(j).box, boxes(blockIdx,:) );
% 
%             if ( doesOverlap )
            if  ( ( max( blockProposals(j).box.x1, boxes(blockIdx,1)) < min(blockProposals(j).box.x2, boxes(blockIdx,3)) ) && ( max(blockProposals(j).box.y1, boxes(blockIdx,2)) < min (blockProposals(j).box.y2, boxes(blockIdx,4)) ) )
                doesOverlap = true;
                %we found an overlapping block
                boxes(blockIdx,5) = -Inf;
                break;
            end
         end

         if ( ~doesOverlap )        
             % we  can savely add this guy, since it does not
             % overlap with blocks from the same image that are better
             % scored
             newBlock.score = boxes(blockIdx,5);
             boxStruct = struct('im',imgfn,'x1',boxes(blockIdx,1),'y1',boxes(blockIdx,2),'x2',boxes(blockIdx,3),'y2',boxes(blockIdx,4) );
             newBlock.box = boxStruct;
             newBlock.imgIdx = imgIdx;             
             newBlock.feature = [];
             % seed idx is not needed here, but the field should exist.
             newBlock.seedIdx = [];

             blockProposals = [ blockProposals newBlock ];                     

             boxes(blockIdx,5) = -Inf;
             redundant = false;
         end        
      end %while loop
      
                     
    end % for loop
  
  %done :)
end

function blockProposals = getTopKNotOverlappingResponsesOld( boxes, i_K, imgIdx, imgfn )

    % no boxes given to chose from
    if ( isempty(boxes) )
        return;
    end
      
    % init output struct
    blockProposals = struct ('score',{}, 'box',{} , 'imgIdx',{} , 'feature',{}, 'seedIdx', {});
    

    for i = 1 : i_K
      redundant = true;
      
      % we search until we found the index of a block proposal which is
      % non-overlapping with one of the training blocks, or until no
      % possible block proposal is available anymore
      %
      % -> non-maximum suppression
      
      %NOTE: think about smoothing the detection results first
      
      while ( redundant )
         [ maxVal, blockIdx ] = max( boxes(:,5) );
         
         if ( maxVal == -Inf )
             %no possible solutions left
             return;
         end

            
         doesOverlap = false;
         for j=1:length(blockProposals)
             
            doesOverlap = checkOverlap ( blockProposals(j).box, boxes(blockIdx,:) );
% 
            if ( doesOverlap )
%             if  ( ( max( blockProposals(j).box.x1, boxes(blockIdx,1)) < min(blockProposals(j).box.x2, boxes(blockIdx,3)) ) && ( max(blockProposals(j).box.y1, boxes(blockIdx,2)) < min (blockProposals(j).box.y2, boxes(blockIdx,4)) ) )
                %we found an overlapping block
                boxes(blockIdx,5) = -Inf;
                break;
            end
         end

         if ( ~doesOverlap )        
             % we  can savely add this guy, since it does not
             % overlap with blocks from the same image that are better
             % scored
             newBlock.score = boxes(blockIdx,5);
             boxStruct = struct('im',imgfn,'x1',boxes(blockIdx,1),'y1',boxes(blockIdx,2),'x2',boxes(blockIdx,3),'y2',boxes(blockIdx,4) );
             newBlock.box = boxStruct;
             newBlock.imgIdx = imgIdx;             
             newBlock.feature = [];
             % seed idx is not needed here, but the field should exist.
             newBlock.seedIdx = [];

             blockProposals = [ blockProposals newBlock ];                     

             boxes(blockIdx,5) = -Inf;
             redundant = false;
         end        
      end %while loop
      
                     
    end % for loop
  
  %done :)
end