function patches = mergeRedundantPatches(allPatches, d_thrRedundant, ldaStuff, settings)    
    
    patches = [];
    
%    %NOTE we could think about sorting all patches in advance, e.g.,
%    %descending wrt their current minScore or their number of blocks.
%    %a possible solution could look like this
%     b_sortByMinValue = true;
%     
%     if ( b_sortByMinValue )
%         [~, idxToProcess ] = sort ( [allPatches.minScore], 'descend' );   
%     else
%         idxToProcess = 1:length(allPatches);
%     end
        
    
    
    for idx=1:length( allPatches )
        
        [ redundancy idxOfRedundantPatch ] = checkForRedundancy( allPatches( idx ), patches , d_thrRedundant);
        
        if ( ~redundancy )
            %remember this index
            patches = [ patches ;  allPatches( idx ) ];  
        else
            % merge training data of both patches
            
            % that's the one we want to merge into an existing patch
            patchToMerge = allPatches( idx );
            % that's the existing patch we want to merge the current one with
            patchToMergeWith = patches( idxOfRedundantPatch );
            
            % check for overlapping blocks in both sets
            % if two blocks overlap, we simply take the one of the first
            % patch (greedy, but efficient)
            idxBlocksToMerge = true ( length(patchToMerge.blocksInfo) ,1 );
            
            for blockIdx = 1 : length(patchToMerge.blocksInfo)

                blocksOfSameImg = ismember( [patchToMergeWith.blocksInfo.imgIdx], patchToMerge.blocksInfo(blockIdx).imgIdx );

                idxBlocksOfSameImg = find(blocksOfSameImg);

                if ( sum( blocksOfSameImg) > 0 )
                    for overLapIdx = 1 : length(idxBlocksOfSameImg)
                        
                        overlap =  computeIntersectionOverUnion ( ...
                                         patchToMergeWith.blocksInfo( idxBlocksOfSameImg(overLapIdx) ).box, ...
                                         patchToMerge.blocksInfo(blockIdx).box ...
                                           );
                        % threshold the score
                        doesOverlap = ( overlap > settings.d_thrOverlap );                        
                        
                        if ( doesOverlap )
                            %we found an overlapping block
                            idxBlocksToMerge(blockIdx) = false;
                            break;
                        end                        
                    end
                end
            end
                    
            
            patchToMergeWith.blocksInfo = [ [patchToMergeWith.blocksInfo] [patchToMerge.blocksInfo(idxBlocksToMerge)] ];
            
            %% update model
            patchToMergeWith.model = learnWithGivenWhitening( ...
                                              ldaStuff.modelTemplate, ...
                                              ldaStuff.R, ldaStuff.neg, ...
                                              [patchToMergeWith.blocksInfo.feature], ...
                                              ldaStuff.b_ignoreLastDim ...
                                              );
            
            %% update scores
            scores = scoreBlocks( [patchToMergeWith.blocksInfo.feature], patchToMergeWith.model );
            for blockIdx=1:length(patchToMergeWith.blocksInfo)
                patchToMergeWith.blocksInfo(blockIdx).score = scores(blockIdx);
            end            
            
            %% update min score
            patchToMergeWith.minScore = min(scores);
            
            %% merge model labels
            patchToMergeWith.label = union ( patchToMergeWith.label, patchToMerge.label);
            
            %% update converged flag
            % we only keep it as converged if both partners are already
            % converged...
            % and even then, it might not be completely justifiable... ;)
            patchToMergeWith.isConverged = (patchToMergeWith.isConverged && patchToMerge.isConverged);
            
            %% update corresponding patch element
            patches ( idxOfRedundantPatch ) = patchToMergeWith;
        end            
        
    end
    
end