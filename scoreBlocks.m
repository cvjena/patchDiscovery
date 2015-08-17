function scores = scoreBlocks(features, detector)
% function scores = scoreBlocks(features, detector)
%
% BRIEF: Compute detection scores for several blocks with pre-computed 
%        features using a single detector. Scoring is done by elementwise
%        multiplication of weight entries and feature values.
%
% INPUT: 
%        features     --   struct of size (1 x numBlocks), every entry has 
%                          at least the field 'feature' (double matrix)
%        detector     --   1x1 struct, with at least the field w being the weight
%                          vector of the model. 
% 
% OUTPUT: 
%        scores       --  1 x numBlocks double array, contains
%                         detection scores
%
% author: Alexander Freytag
% date  : 08-05-2014 ( dd-mm-yyyy )

  %% ( 0 ) init output
  scores = zeros( 1, size(features, 2) );
  
  %% ( 1 ) do the actual scoring
  for i=1:size(features,2)   
    %use the fconv mex version as in who
    if ( ndims ( detector.w ) > 2 ) 
        res  = fconv3D( double(features(i).feature), {detector.w} , 1,1);
        scores(i) = res{1};
    else
        res  = fconv2D( double(features(i).feature), {detector.w} , 1,1);
        scores(i) = res{1};        
    end
  end
  
  % manual alternative (3x slower in my experiments)
  % results are the same
  %
  % scores = arrayfun(@(x) sum(sum(sum( x.feature.*newpatches(i).model.w ))), featOfBlocks );  
  
end