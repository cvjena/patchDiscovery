function [ redundancy, idxOfRedundantPatch ]= checkForRedundancy( currentPatch, patches, d_thrRedundant)
% function [ redundancy, idxOfRedundantPatch ]= checkForRedundancy( currentPatch, patches, d_thrRedundant)
% 
%   BRIEF: 
%        Given discovered patch detectors, figure out which of them are
%        actually discriminative for the current classification task.
% 
%   INPUT: 
%        currentPatch      --   a detector which needs to be checked for
%                               redundancy
%        patches           --   our current set of (non-redundant) patches,
%                               the current patch detector is compared
%                               against
%        d_thrRedundant    --   double scalar, min. cosine similarity for
%                               considering two patches as being 'similar', and 
%                               hence one of them being redundant
%
%   OUTPUT: 
%        redundancy          -- bool scalar, stating whether or not the
%                               current detector is redundant
%        idxOfRedundantPatch -- (optional), int scalar, index of detectors 
%                               causing the reduncancy of current detector 

%   author: Alexander Freytag
%   date  : 15-05-2014 ( dd-mm-yyyy, last modified)


  %default: everything is fine, not redundant
  redundancy = false;
  
  if ( nargout > 1 )
     idxOfRedundantPatch = -1;
  end  

  % can we spot a similar detector in the previous ones?
  % 'similar' is measured in terms of cosine similarity between model
  % weight vectors
  w1 = currentPatch.model.w;
  
  % run over all remaining detectors 
  for i=1:length( patches )
      
      % get model and weight vector
      w2 = patches( i ).model.w;   
      
      % compute similarity score in terms of cosine similarty
      sim = dot(w1(:),w2(:))/(norm(w1(:),2)*norm(w2(:),2));
      
      if ( sim > d_thrRedundant )
          %fprintf ( 'Red to idx %03d with sim %f\n', i, sim )
          redundancy = true;
          
          if ( nargout > 1 )
              idxOfRedundantPatch = i;              
          end
          
          % we can abort here, since already a single detector too similar
          % is sufficient for stating that the current detector is
          % redundant
          break;
      end
  end
  


end