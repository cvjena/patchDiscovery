function [discrPatches, additionalInfos ] = selectDiscriminativePatches ( patches, dataset, settings, discriminativeness )
%function [discrPatches, additionalInfos ] = selectDiscriminativePatches ( patches, dataset, settings, discriminativeness )
%
%   BRIEF: 
%        Given discovered patch detectors, figure out which of them are
%        actually discriminative for the current classification task.
%
%   INPUT: 
%        patches    --   our current set of patches (with models), we now want to figure
%                        out which of them are the discriminative ones
%        dataset    --   the dataset containing a training set (previously: val set)
%        settings   --   struct, (optional), settings used: i_numPatchesPerClass,
%                        d_thrRedundant, b_debug b_removeDublicates,
%                        b_heavyDebug
%
%   OUTPUT: 
%        discrPatches --  the subset of patches which were found to be
%                         discriminative
%
%   author: Alexander Freytag
%   date  : 15-05-2014 ( dd-mm-yyyy, last modified)

  
    statusMsg = sprintf( '\n(3) ====== Selection ==== current # patches: %i\n',length(patches));
    disp(statusMsg);
    

    numPatches = length(patches);
    
    
    %%
    % ==========================================================
    %      get indices of discr. patches based on criterion
    % ==========================================================     
    
    % default: use nothing.
    idxOfFinalPatches    = false( 1, numPatches );
    
    i_numPatchesPerClass = settings.i_numPatchesPerClass;
    
    
    
    if ( settings.b_removeRedundantPatches )
        %% select the top scored ones - but check for redundancy!
        if ( strcmp( settings.s_selectionScheme, 'entropyRank' ) )
            affectedClasses = unique ( dataset.labels(dataset.trainImages )  );
            % this will be our counter for how many detectors per class already have
            % been selected
            numPerClass = zeros ( max(affectedClasses), 1);
            
            % order of loop is determined be decreasing score
            [~, indicesToProcess ] = sort ( discriminativeness, 'descend' );
            
            % loop over all detectors, and check for 1) redundancy and 2)
            % if they are still needed for the class
            for idxCnt=1:length(patches)

                idx = indicesToProcess ( idxCnt );
                
                % already enough detectors for class of current detector?
                % FIXME what to do for a set of labels? occurs in unsup.
                % bootstrapping...
                if ( numPerClass( patches(idx).label ) >= settings.i_numPatchesPerClass )
                    continue;
                end

                redundancy = checkForRedundancy( patches( idx ), patches( idxOfFinalPatches ), settings.d_thrRedundant );
                if ( ~redundancy )
                    %remember this index
                    idxOfFinalPatches ( idx ) = true;   
                    numPerClass( patches(idx).label ) = numPerClass( patches(idx).label ) + 1;
                end
            end
            
            % finally, take all remaining patches
            discrPatches = patches( idxOfFinalPatches );
            
        elseif ( strcmp( settings.s_selectionScheme, 'L1-SVM' )  )
            %TODO
        else
            % just take all non-redundant detectors
            discrPatches = removeRedundantPatches ( patches, settings );
        end            
        
        
    else
        %% don't care about redundant detectors - simply select the top scored ones 
        

        % let's now take a subset of detectors according to the scores they got
        if ( strcmp( settings.s_selectionScheme, 'entropyRank' ) )
            
            % select top scored ones for every class -> which classes are
            % affected?
            affectedClasses = unique ( dataset.labels(dataset.trainImages )  );

            for i=1:length( affectedClasses )
                i_classIdx = affectedClasses ( i ) ;

                idxSameCategory      = ismember( [patches.label], i_classIdx );

                scoresOfCategory     = discriminativeness(idxSameCategory);
                % sort ascend, since small entropy scores are nice...
                [~,idxScoresSorted] = sort ( scoresOfCategory, 'ascend');
                % pick desired number of detector for this class if possible
                i_K = min ( length(idxScoresSorted),  i_numPatchesPerClass );  

                idxSameCategory = find(idxSameCategory);
                idxChosenBlocks = idxSameCategory ( idxScoresSorted(1:i_K) );

                idxOfFinalPatches( idxChosenBlocks ) = true;            
            end
            
        elseif ( strcmp( settings.s_selectionScheme, 'L1-SVM' ) )
            %take only those dimensions that have non-zero weights

            %NOTE: we could also optimize this threshold by computing as many
            %diff. thresholds as we have dimensions (patches), compute the SVM
            %criterion for every threshold, and than that one that maximizes
            %the criterion
            idxOfFinalPatches = ( abs(discriminativeness) > 1e-8 );  

        else
            %just do nothing and take all
            idxOfFinalPatches = true( 1, numPatches );
        end

        discrPatches = patches ( idxOfFinalPatches ); 
        scoresTmp    = discriminativeness ( idxOfFinalPatches );        
        
        for i=1:length(discrPatches)
            discrPatches(i).discriminativeness =  scoresTmp(i);
        end
        scoresTmp = [];  
        
        if ( nargout <= 1 )
          additionalInfos = [];
        else
            additionalInfos.idxOfChosenPatches = idxOfFinalPatches; 
            additionalInfos.discriminativeness = discriminativeness( idxOfFinalPatches );
        end          
    end
       
       
      
    
    
% old code stuff    
%     %%
% 
%     numPatches = length(patches);
%         
%     additionalInfos.entropyScores(numPatches).x = [];
%     additionalInfos.entropyScores(numPatches).y = [];
%     
%     
%     detectScores = ( zeros (numPatches, length(dataset.valImages)) );
% 
%     % loop through all images of the validation set
%     for j=1:length(dataset.valImages)
%         statusMsg = sprintf( 'evaluating valImg %i / %i',j, length(dataset.valImages));
%         disp(statusMsg);
%         
%         imgfn = dataset.images{ dataset.valImages(j) };
%         currentImg  = readImage(imgfn);
% 
%         %the information used here obtained from the models are the same for all models
%         pyraFeat = featpyramid(currentImg,patches(1).model);
%         
%         
%         for i=1:numPatches  
% 
%             model = patches(i).model;
%         
%             %if we want to compute the features for validation img for
%             %every patch again 
%             %imgfn = dataset.images{ dataset.valImages(j) };
%             %currentImg = readImage(imgfn);            
%             %boxes = detect(currentImg, model, model.thresh);
%             % if we already precomputed features for val imgs
%             boxes = detectWithGivenFeatures( pyraFeat, model, model.thresh);
%             [maxVal, maxInd] = max(boxes(:,5));
%             bestBox = boxes(maxInd,:);
% 
%             detectScores( i,j ) = maxVal;
%             
%             
%             %show which detection achieved the best score in this val image
%             if ( settingsExpansionSelection.b_heavyDebug ) 
%                 %show the current patch in the orig image
%                 figure(1); 
%                 imshow(currentImg);
%                 hold on
%                 myBB = [ bestBox(1), bestBox(2), bestBox(3), bestBox(4) ];
%                 showboxes(currentImg, myBB);
%                 hold off           
%                %show the HoG results 
%                figure(2);
%                showHOG(model.w);                
% 
% 
%                %wait for user response and close everything before
%                %continuing
%                pause;
%               close(1);close(2);
%             end            
%             
%             %note: do we need non-max-supp here?
%         end
%     end
%     
%     % normalize scores by dividing every detector output by its max
%     % range -> map it to [-1 +1]
%     %
%     
%     [minVal, ~] = min( detectScores, [], 2 );
%     [maxVal, ~] = max( detectScores, [], 2 );
% 
%     detectScores = 2*bsxfun ( @rdivide , bsxfun( @minus, detectScores, minVal ), (maxVal-minVal) ) -1;
%     %detectScores = 2*bsxfun ( @rdivide , bsxfun( @minus, detectScores, minVal ), (maxVal-minVal) ) -1;
%     
%     
% %     detectScores(i,:) = 2* (detectionTopScores(:,1) - minVal)./(maxVal-minVal) -1;
%     
% 
%     if ( strcmp( settingsExpansionSelection.s_selectionScheme, 'L1-SVM' ) )
%         
%         labels = 2*(dataset.labels([dataset.valImages(:) ])-1)-1;
%         svmModel = train ( labels', sparse(detectScores'), '-s 5' ); %L1 regularizer
%         additionalInfos.discriminativeness = abs(svmModel.w);
%         
%         % sort to select the r patches with largest impact on SVM decision
%         % scores
%         [~,perm] = sort( additionalInfos.discriminativeness ,'descend');
%         
%     elseif ( strcmp( settingsExpansionSelection.s_selectionScheme, 'entropyRank' ) )
%         % compute area under the entropy rank curve etc.
%         maxRank = length(dataset.valImages);
%         for i=numPatches:-1:1
%             [additionalInfos.discriminativeness(i) additionalInfos.entropyScores(i).y] = computeEntropyRankCurve( detectScores(i,:), dataset.labels(dataset.valImages), maxRank );
%             additionalInfos.entropyScores(i).x = 1:numPatches;
%         end
%         
%         % sort to select the r patches with smallest auc scores 
%         [~,perm] = sort( additionalInfos.discriminativeness,'ascend');
%         
%     else
%         %no scoring at all
%         additionalInfos.discriminativeness = zeros(numPatches,1);
%         perm=1:additionalInfos.discriminativeness;
%     end
% 
%      
%     
%  
%     
%     %remove redundant models, keep finally n detectors per class
%     % (skipping those ones with sim > thresh to already taken ones)
% 
%         
%     if ( settingsExpansionSelection.b_removeDublicates ) 
%         idxOfFinalPatches=[];
% 
%         %NOTE we keep all patches for this evaluation. However, we could also just use
%         %the top noPerClass as done by Vedaldis Blocks that shout
%         %while ( (sum(patchesPerClass < noPerClass) ) && (idx< length(aucScores) ) ) 
%         for idx=1:numPatches
% 
%             [ redundancy idxOfRedundantPatch ]= checkForRedundancy( patches( perm(idx) ), patches(idxOfFinalPatches), d_thrRedundant);
% 
%             if ( ~redundancy )
%                 %remember this index
%                 idxOfFinalPatches = [ idxOfFinalPatches , perm(idx) ];
%             else
%                 if ( settingsExpansionSelection.b_heavyDebug )             
%                    % show the HoG results of the redundant patch
%                    figure(1);
%                    showHOG( patches(perm(idx)).model.w);
% 
%                    % show the HoG results of the patch which lead to redundancy
%                    figure(2);
%                    idxAllCurrent=idxAll(idxOfFinalPatches);
%                    showHOG( patches( idxAllCurrent(idxOfRedundantPatch) ).model.w);           
% 
%                    % wait for user response and close everything before
%                    % continuing
%                    pause;
%                   close(1);close(2);
%                 end
%             end  
%         end
%     else
%         %simply take all patches without deleting redundant ones
%        idxOfFinalPatches=1:length(patches);             
%     end
%     
%     % let's now take a subset of detectors according to the scores they got
%     if ( strcmp( settingsExpansionSelection.s_selectionScheme, 'L1-SVM' ) )
%         %take only those dimensions that have non-zero weights
%         
%         %NOTE: we could also optimize this threshold by computing as many
%         %diff. thresholds as we have dimensions (patches), compute the SVM
%         %criterion for every threshold, and than that one that maximizes
%         %the criterion
%         idxOfFinalPatches = idxOfFinalPatches ( abs(additionalInfos.discriminativeness) > 1e-8 );
%     elseif ( strcmp( settingsExpansionSelection.s_selectionScheme, 'entropyRank' ) )
%         % do something class wise
%         affectedClasses = unique ( dataset.labels(dataset.valImages )  );
%         patchesPerClass = zeros(1, length(affectedClasses) );
%         
%         % TODO check whether this works correct or not!
%         idxToPick = zeros(1, length(idxOfFinalPatches) );
%         for idx=1:length(idxOfFinalPatches)
%             classLabel = dataset.labels( patches( perm( idxOfFinalPatches ( idx ) ) ).label   );
%             
%             % do we want to have more patches for this class?
%             if ( patchesPerClass(classLabel) < i_numPatchesPerClass)
%                 patchesPerClass(classLabel) = patchesPerClass(classLabel) +1 ;
%                 idxToPick( idx ) = 1;
%                 
%                 %are we done with selecting? -- note, we could make this if
%                 %statement for effective, but well...
%                 if ( sum(patchesPerClass < noPerClass) == length(affectedClasses) )
%                     break;
%                 end
%       
%             else
%                 %if not, skip this detector
%             end
%         end
%         
%         idxOfFinalPatches = idxOfFinalPatches(idxToPick);
%     else
%         %just do nothing and take all
%     end
%         
%     
%     
%     discrPatches = patches( idxOfFinalPatches );
%     
%     if ( nargout <= 1 )
%       additionalInfos = [];
%     else
%         additionalInfos.idxOfChosenPatches = idxOfFinalPatches; 
%         additionalInfos.discriminativeness = additionalInfos.discriminativeness( idxOfFinalPatches );
%     end
    
end