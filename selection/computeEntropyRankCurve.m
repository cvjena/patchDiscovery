function [ aucScore, entropyScores ] = computeEntropyRankCurve( scoresOfBlocks, labels, maxRank )
% function [ aucScore, entropyScores ] = computeEntropyRankCurve( topScoringBlocks, labels, maxRank )
%
%   BRIEF: 
%     Compute the entropy-rank-curve statistic to measure the
%     'discriminativeness' of a patch detector as introduced in the Blocks
%     that shout paper (CVPR 2013).
%
%   INPUT: 
%     scoresOfBlocks -- double vector, detection scores obtained from current patch
%                       detector
%     labels        -- int/double vector, labels indicating GT class of the scored blocks
%     maxRank       -- int scalar, specify how many top-scored blocks shall
%                      be inspected to build the entropy-rank curve
%
%   OUTPUT: 
%     aucScore      -- double scalar, area under the entropy-rank-curve
%                      (smaller is better in terms of discriminativeness)
%     entropyScores -- double vector (1 x maxRank ), contains in index i
%                      the entropy score when considering top i blocks
%
%   author: Alexander Freytag
%   date  : 15-05-2014 ( dd-mm-yyyy, last modified)  
 

  entropyScores = zeros(1,maxRank);
  % sort to select the r detection results with highest score
  [~,perm] = sort(scoresOfBlocks,'descend');  
  
  for r=1:maxRank
      affectedClasses = unique ( labels( perm(1:r) ) );      
      
      for cl=1:length(affectedClasses)
          blocksOfClass    = sum( labels( perm(1:r) ) == affectedClasses(cl) );
          fraction         = blocksOfClass /double(r);
          entropyScores(r) = entropyScores(r) + fraction * log2(fraction);
      end
      
  end

  %compute the final score as area under the curve
  % we take the abs since entropy is usually a negative score
  entropyScores = abs(entropyScores);
  aucScore      = trapz(1:maxRank,entropyScores); 
end