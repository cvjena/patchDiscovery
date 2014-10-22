function blockProposals = getTopKNotOverlappingResponsesFFLDOutput( results, i_K,  d_overlapThr)

    blockProposals = [];

    if ( nargin < 3 ) 
        d_overlapThr = 0.5;
    end

    % no results given to chose from
    if ( isempty(results) ||  isempty(results{1} ))
        return;
    end
      
    % init output struct
    blockProposals = struct ('score',{}, 'box',{} , 'imgIdx',{} , 'feature',{});
    
    
    [ ~, perm] = sort(  results{3}, 'descend' );    
    if ( isempty(perm) )
        return;
    end
    

    idxCurrent = 0;
    
    for i = 1 : i_K
      redundant = true;
            
      while ( redundant )
          idxCurrent=idxCurrent+1;
          
          
         % NOTE: results are already sorted with descending detection scores
         
         if ( idxCurrent > length( results{1} ) )
             %no possible solutions left
             return;
         end

         idxCurrentPerm = perm(idxCurrent);
            
         doesOverlap = false;
         for j=1:length(blockProposals)
             if ( ~strcmp( blockProposals(j).box.im , results{1}{idxCurrentPerm} )  )
                 % different image, not overlapping...
                 continue
             end
             
             overlap =  computeIntersectionOverUnion ( blockProposals(j).box, ...
                       results{4}(idxCurrentPerm), results{5}(idxCurrentPerm),... %x1 y1
                       results{6}(idxCurrentPerm), results{7}(idxCurrentPerm) ... %x2 y2
                                       );
             % threshold the score
             doesOverlap = ( overlap > d_overlapThr );
                 

            if ( doesOverlap )
                %we found an overlapping block
                break;
            end
         end

         if ( ~doesOverlap )        
             % we  can savely add this guy, since it does not
             % overlap with previous results for this model 
             % that are scored better
             newProposal.score = results{3}(idxCurrentPerm);
             boxStruct = struct('im', results{1}(idxCurrentPerm),...
                           'x1', results{4}(idxCurrentPerm), ...
                           'y1', results{5}(idxCurrentPerm),...
                           'x2', results{6}(idxCurrentPerm),...
                           'y2', results{7}(idxCurrentPerm) ...
                         );
             newProposal.box = boxStruct;
             newProposal.imgIdx = [];             
             newProposal.feature = [];

             blockProposals = [ blockProposals newProposal ];                     

             redundant = false;
         end        
      end %while loop
      
                     
    end % for loop
  
  %done :)
end