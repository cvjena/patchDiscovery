function patches = initPatches ( features, seedingBlockLabels, ldaStuff, seedingBlocks, d_relMinScore )
% function patches = initPatches ( features, seedingBlockLabels, ldaStuff, seedingBlocks, d_relMinScore )
%
% BRIEF:
%    At the beginning, every detector is built only from a single
%    block (see the 1-SVM paper for motivation details)
%
%    Lateron, further blocks are added to this struct increasing the
%    number of training samples of every detector
%
% INPUT:
%    features            -- features computed from seeding blocks
%    seedingBlockLabels  -- labels of seeding blocks
%    ldaStuff            -- struct containing following fields:
%                   ldaStuff.R               -- covariance matrix of all data
%                   ldaStuff.neg             -- mean of universal negative data
%                   ldaStuff.modelTemplate   -- model template for LDA models
%                   ldaStuff.i_truncDim      -- int specifying whether
%                                               or a certain feature dimension 
%                                               is used as truncation
%                                               feature only
%   d_relMinScore        -- (optional), set patch.minScore to
%                           selfScore*d_relMinScore
%
% OUTPUT:
%    patches   -- struct containing following fields:
%                   patches.label         -- label of the image its block stems from
%                   patches.model         -- initially trained detector model
%                   patches.minScore      -- re-classif score
%                   patches.blocksInfo    -- info of blocks used as pos.
%                                            training samples, including 'score',
%                                            'box','imgIdx','hogfeature'
%                   patches.isConverged   -- bool flag specifying whether
%                                            bootstrapping converged or not
        
  if ( (nargin < 5) || isempty ( d_relMinScore ) )
      % useful for HOG arrays
      d_relMinScore = 0.5;
      %useful for color mean patches
      %d_relMinScore = 0.85;
  end

   n = length(features);  
   for i=n:-1:1
        
        % the class label of a detector is the label of the image its block stems from
        patches(i).label = seedingBlockLabels(i);
        
        %initially train the model        
        patches(i).model = learnWithGivenWhitening(ldaStuff.modelTemplate,ldaStuff.R, ldaStuff.neg, features(i), ldaStuff.i_truncDim );        
        
        score                 = scoreBlocks( features(i), patches(i).model );
        
        patches(i).minScore   = max( 0, d_relMinScore*score );
         % useful as default solution to accept some initial firings for
         % every detector
%         patches(i).minScore  = -1;
        
        patches(i).blocksInfo =  [];
        patches(i).blocksInfo(1).score   = score;
        patches(i).blocksInfo(1).box.im  = seedingBlocks(i).im;
        patches(i).blocksInfo(1).box.x1  = seedingBlocks(i).x1;
        patches(i).blocksInfo(1).box.y1  = seedingBlocks(i).y1;
        patches(i).blocksInfo(1).box.x2  = seedingBlocks(i).x2;        
        patches(i).blocksInfo(1).box.y2  = seedingBlocks(i).y2;
        patches(i).blocksInfo(1).imgIdx  = seedingBlocks(i).imgIdx;
        patches(i).blocksInfo(1).feature = features(i);  
        patches(i).blocksInfo(1).seedIdx = i;  
        
        patches(i).isConverged = false;

    end
end