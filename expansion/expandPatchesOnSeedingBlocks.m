function newpatches = expandPatchesOnSeedingBlocks( patches, ldaStuff, settingsExpansionSelection, seedingBlocks, seedingBlockLabels, featOfBlocks )
% function newpatches = expandPatchesOnSeedingBlocks( patches, ldaStuff, settingsExpansionSelection, seedingBlocks, seedingBlockLabels, featOfBlocks )
%
% BRIEF: 
%       Expand positive samples (blocks) of patch detectors by scoring all seeding 
%       with the current models, and use the top-k responses for bootstrapping.
%       -> in the style of the blocks-that-shout-paper 
%
%   The function accepts the following options:
%   INPUT: 
%        patches             --   our current patch detectors 
%
%        ldaStuff            --   precomputed cov matrix R, as well as
%                                 'distribution' negative data (neg mean)
%        settingsExpansionSelection -- settings used: K, b_debug, b_verbose
% 
%        seedingBlocks       --   information for all seeding blocks
% 
%        seedingBlockLabels  --   class labels of all seeding blocks
% 
%        featOfBlocks        --   features computed for all seeding blocks
%
%   OUTPUT: 
%        newpatches          --   updated set of patch detectors
% 
% author:  Alexander Freytag
% date  :  08-05-2014 (dd-mm-yyyy)


    if ( settingsExpansionSelection.b_verbose )
        statusMsg=sprintf( '\n(2) ====== Expansion ==== current # non-converged patches: %i\n', sum( ~[patches.isConverged] ));
        disp(statusMsg);
    end

    newpatches = patches;
    
    % do we want to use our fancy thresholding for estimating convergence?
    % If so, we add at most i_K new samples, if not, we add exactly i_K new
    % samples per iteration. 
    % -> default: true.
    b_useBootstrapThreshold   = settingsExpansionSelection.b_useBootstrapThreshold;
    
    % should every patch detector get at maximum one positive sample per
    % image? Plausible for birds, less useful for scenes.
    % -> default: true.
    b_bootstrapOnlyOnePerImg  = settingsExpansionSelection.b_bootstrapOnlyOnePerImg;
    
    % perform convolution with images of same class? Or with ALL images?
    % -> default: true.    
    b_supervisedBootstrapping = settingsExpansionSelection.b_supervisedBootstrapping;
        
    for i=1:length(newpatches)
        
        % if this patch already converged bootstrapping earlier, we skip it
        if ( newpatches(i).isConverged )
            continue;
        end
        
        %%
        % compute detection scores of current model on all seeding blocks
        scores = scoreBlocks( featOfBlocks, newpatches(i).model );        
        
        
        %%
        % CHECK WHICH SEEDING BLOCKS HAVE ACCEPTABLE SCORES
        if ( b_useBootstrapThreshold )
            idxScoreAcceptable = ( scores >= newpatches(i).minScore );

            if ( isempty ( idxScoreAcceptable ) )
                newpatches(i).isConverged  = true;
                continue;
            end

            scoresAcceptable   = scores ( idxScoreAcceptable );
            idxScoreAcceptable = find(idxScoreAcceptable);
        else
            scoresAcceptable   = scores;
            idxScoreAcceptable = 1:length( seedingBlockLabels );
        end
        
        %%
        % CHECK WHICH SEEDING BLOCKS ARE ALREADY USED
        seedIdxUsed = [newpatches(i).blocksInfo.seedIdx];   
        unusedIdx   = ~ismember ( idxScoreAcceptable, seedIdxUsed );
        
        if ( sum( unusedIdx ) == 0)
            newpatches(i).isConverged  = true;
            continue;
        end        
        
        scoresAcceptable = scoresAcceptable( unusedIdx );
        
        idxScoreAcceptable = idxScoreAcceptable( unusedIdx );
        
        %%
        % CHECK WHICH SEEDING BLOCKS ARE FROM THE SAME CATEGORY
        if ( b_supervisedBootstrapping )
            idxSameCategory    = ismember( seedingBlockLabels(idxScoreAcceptable), newpatches(i).label );
           
            scoresAcceptable   = scoresAcceptable ( idxSameCategory );
            idxScoreAcceptable = idxScoreAcceptable( idxSameCategory );
        end
        
        %%
        % CHECK WHICH SEEDING BLOCKS ARE FROM THE SAME IMAGE
        if ( b_bootstrapOnlyOnePerImg )
            idxSameImg = ismember( [seedingBlocks(idxScoreAcceptable).imgIdx], [newpatches(i).blocksInfo.imgIdx] );

            if ( sum( idxSameImg ) == length(idxSameImg) )
                newpatches(i).isConverged  = true;
                continue;
            end  
            
            scoresAcceptable   = scoresAcceptable ( ~idxSameImg );
            idxScoreAcceptable = idxScoreAcceptable( ~idxSameImg );
        end
        
        
        [ ~ , idxScoresSorted] = sort ( scoresAcceptable, 'descend');

  
        %%
        %Chose the top k results, if still available        
        i_K = min ( length(idxScoresSorted),  settingsExpansionSelection.i_K );        
        
        if ( i_K == 0 )
            newpatches(i).isConverged  = true;
            continue;
        end        
        
        idxChosenBlocks = idxScoreAcceptable ( idxScoresSorted(1:i_K) );
        
        
        % update block information
        i_numOldBlocks=size(newpatches(i).blocksInfo,2);
        for biIdx = length(idxChosenBlocks):-1:1
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).score   = 0; % will be changen in a minute
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).box.im  = seedingBlocks( idxChosenBlocks(biIdx) ).im;
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).box.x1  = seedingBlocks( idxChosenBlocks(biIdx) ).x1;
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).box.y1  = seedingBlocks( idxChosenBlocks(biIdx) ).y1;
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).box.x2  = seedingBlocks( idxChosenBlocks(biIdx) ).x2;        
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).box.y2  = seedingBlocks( idxChosenBlocks(biIdx) ).y2;
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).imgIdx  = seedingBlocks( idxChosenBlocks(biIdx) ).imgIdx;
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).feature = [];%features not needed, we always use the seedingFeats
            newpatches(i).blocksInfo(biIdx+i_numOldBlocks).seedIdx = idxChosenBlocks(biIdx);  
        end
        
        
        % retrain the detector
        newpatches(i).model = learnWithGivenWhitening( ...
                                  ldaStuff.modelTemplate, ...
                                  ldaStuff.R, ldaStuff.neg, ...
                                  [ featOfBlocks(seedIdxUsed),  featOfBlocks(idxChosenBlocks) ] , ...
                                  ldaStuff.i_truncDim ...
                                  );
        
        if ( b_useBootstrapThreshold )
            %re-score the blocks given the updated model        
            scores = scoreBlocks( [ featOfBlocks(seedIdxUsed),  featOfBlocks(idxChosenBlocks) ], newpatches(i).model );
            for blockIdx=1:length(newpatches(i).blocksInfo)
                newpatches(i).blocksInfo(blockIdx).score = scores(blockIdx);
            end



            %adapt the minScore accordingly
            % NEW: relative weighting of updated min-score
            % 
            d_relMinScore = settingsExpansionSelection.d_relMinScore;
            newpatches(i).minScore = d_relMinScore*min(scores);
        end
        
        % this patch detector is not yet converged in bootstrapping 
        newpatches(i).isConverged = false;  

    end

end

