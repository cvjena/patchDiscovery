function newpatches = expandPatchesConvolution(dataset, patches, ldaStuff, settingsExpansionSelection )
% function newpatches = expandPatchesConvolution(dataset, patches, ldaStuff, settingsExpansionSelection )
%
% BRIEF: 
%       Expand positive samples (blocks) of patch detectors by convolving them 
%       with training images and take valid responses as possible
%       candidates to add.
%       Results can be merged or replacing previous blocks if scored better
%       and extracted from overlapping regions
%
%   The function accepts the following options:
%   INPUT: 
%        dataset             --   our dataset, only training images are
%                                 needed here
%        patches             --   our current patch detectors 
%
%        ldaStuff            --   precomputed cov matrix R, as well as
%                                 'distribution' negative data (neg mean)
%        settingsExpansionSelection -- settings used: K, b_debug, b_verbose
%
%   OUTPUT: 
%        newpatches          --   updated set of patch detectors
% 
% author:               Alexander Freytag
% last time modified:   05-02-2014 (dd-mm-yyyy)


    if ( settingsExpansionSelection.b_verbose )
        statusMsg=sprintf( '\n(2) ====== Expansion ==== current # non-converged patches: %i\n', sum( ~[patches.isConverged] ));
        disp(statusMsg);
    end
    
    
    % okay, here's the very story of this method:
    % in each expansion step, we add at most K new bocks to a patch as
    % positive training samples. We only add those samples with higher scored
    % than the blocks currently used for training
    %
    % we add less, if i) there are no blocks scored better then the current
    % blocks used as training (i.e., bootstrapping is converged), or ii) if
    % a new block overlaps with one of the currently used training blocks.
    % In this case, the old one is replaced
    %
    % Since ii) would occur in almost any cases, noise is added to the
    % current model ala Denoising Auto-Encoders
    %
    % mini-pipeline
    % 0) compute datastructure for blocks containing the warped img block, the current score, the BB info, the img filename or idx
    % 1) perform convolution between detectors and training images ( of same class )
    % 2) check which blocks are scored better
    % 3) check for overlap, if so -> replace, if not -> add
    % 4) compute pos-normalized hog features from blocks
    


    %% ( 0 ) prepare variable settings
    b_fastConvolution = settingsExpansionSelection.b_fastConvolution;
    

    tStart_proposalGeneration = tic;
    
    %% ( 1 ) do the actual convolutions between all images and patches
    if ( b_fastConvolution ) 
        blockProposals = convolutionFFLD ( settingsExpansionSelection, dataset, patches );
    else
        blockProposals = convolutionByPyramids ( settingsExpansionSelection, dataset, patches );
    end
    
    %% ( 2 ) take possible responses and compute features for them 
    
    if ( settingsExpansionSelection.b_verbose )
        t_proposalGeneration = toc( tStart_proposalGeneration );
        statusMsg=sprintf( ' --- Time for proposal generation: %fs\n',t_proposalGeneration );
        disp(statusMsg); 
    end
    
    % copy data to new struct, since we possibly alter the converged-flags,
    % model-vectors, ... 
    newpatches = patches;    
    
    
    tStart_featureComputation = tic;
    % for every patch proposal, we compute the normalized position and the
    % resulting feature, since every proposal is at least as good as the
    % previous training samples
    for i=1:length(newpatches)
        
        % skip patches with no proposals (either nothing found, or already
        % converged) 
        if ( isempty( blockProposals(i).proposals ) )
            
            % if patch i did not converge so far, but no new proposals are
            % available, we set it to converged
            if ( ~newpatches(i).isConverged )
                newpatches(i).isConverged = true;
                if ( settingsExpansionSelection.b_debug )
                    statusMsg=sprintf( '     Patch %i converged bootstrapping... %\n',i );
                    disp(statusMsg);
                end                
            end
            continue;
        end
        
        % model needs to contain a model.w of appropiate size (only the first dimensions matter) and
        % model.i_numCells
        %
        % a warped block is simply a block (subimg) brought to a standard size
        warpedProposals = warpBlocksToStandardSize( newpatches(i).model, [blockProposals(i).proposals.box ], settingsExpansionSelection.fh_featureExtractor);

        % pre-compute features from the proposed blocks (size normalized)
        features = computeFeaturesForBlocks( warpedProposals, settingsExpansionSelection );

        for hIdx = 1 : length(features)
           blockProposals(i).proposals(hIdx).feature = features(hIdx);
        end
    end
    
    if ( settingsExpansionSelection.b_verbose )
        t_proposalComputation = toc( tStart_featureComputation );
        statusMsg=sprintf( ' --- Time for feature computation of block proposals: %fs\n',t_proposalComputation );
        disp(statusMsg);
    end
    
    
    
    %% ( 3 ) check which of the block proposal are useful to be included to block collections, then merge old training samples and new proposals
    
    for i=1:length(newpatches)
        
        % if this patch already converged bootstrapping earlier, we skip it
        if ( newpatches(i).isConverged )
            continue;
        end
        
%         % if this patch didn't got new blocks in this round, it is
%         % considered as 'converged', so we have nothing to do here anymore
%         if ( isempty( blockProposals(i).proposals) )
%             newpatches(i).isConverged = true;
%             
%             if ( settingsExpansionSelection.b_debug )
%                 statusMsg=sprintf( '     Patch %i converged bootstrapping... %\n',i );
%                 disp(statusMsg);
%             end
% 
%             continue;
%         end
        
        %these are the actual blocks that serve as positive examples for
        %the detector of this kind of patch
        blocks = newpatches(i).blocksInfo;
        
        %show what our current model for this very patch looks like
        if ( settingsExpansionSelection.b_debug ) 
            % do something here if you like
        end    
                
        % check for every block proposal, whether it was computed from the
        % same img as one of the training blocks
        
        % dirty brechstangen-solution using for-loops
        idxGoodOldBlocks = true(length(blocks),1);
%         for trBlockIdx = 1 : length(blocks)
%             blocksOfSameImg = ismember( [ blockProposals(i).proposals.imgIdx ], blocks(trBlockIdx).imgIdx );
%             
%             idxBlocksOfSameImg = find(blocksOfSameImg);
%             
%             if ( sum( blocksOfSameImg) > 0 )
%                 for overLapIdx = 1 : length(idxBlocksOfSameImg)
%                     
%                     overlap =  computeIntersectionOverUnion ( ...
%                                      blockProposals(i).proposals( idxBlocksOfSameImg(overLapIdx) ).box, ...
%                                      blocks(trBlockIdx).box ...
%                                        );
%                     % threshold the score
%                     doesOverlap = ( overlap > settingsExpansionSelection.d_thrOverlap );
% 
%                     if ( doesOverlap )
%                         %we found an overlapping block
%                         idxGoodOldBlocks(trBlockIdx) = false;
%                         break;
%                     end
%                 end
%             end
%         end
        
        newpatches(i).blocksInfo = [ blocks(idxGoodOldBlocks) blockProposals(i).proposals];
        
        % an elegant solution might start like this:
        %blocksOfSameImg = ismember( [ blockProposals(i).proposals.imgIdx ], [ blocks.imgIdx ] );
        %
        %if ( sum( blocksOfSameImg) > 0 )
        % ... do something smart here
        %end
 
        
        % retrain the detector
        newpatches(i).model = learnWithGivenWhitening( ...
                                  ldaStuff.modelTemplate, ...
                                  ldaStuff.R, ldaStuff.neg, ...
                                  [newpatches(i).blocksInfo.feature], ...
                                  ldaStuff.i_truncDim ...
                                  );
        
        %re-score the blocks given the updated model        
        scores = scoreBlocks( [newpatches(i).blocksInfo.feature], newpatches(i).model );
        for blockIdx=1:length(newpatches(i).blocksInfo)
            newpatches(i).blocksInfo(blockIdx).score = scores(blockIdx);
        end
        
        
        
        %adapt the minScore accordingly
        % NEW: relative weighting of updated min-score
        % 
        d_relMinScore = settingsExpansionSelection.d_relMinScore;
        newpatches(i).minScore = d_relMinScore*min(scores);
        
        % this patch detector is not yet converged in bootstrapping 
        newpatches(i).isConverged = false;  

    end

end

