function patches = removeFeatureFromPatchStructs ( patches ) 
% function patches = removeFeatureFromPatchStructs ( patches ) 
% 
% author: Alexander Freytag
% date  : 03-05-2014 ( dd-mm-yyyy )
% 
% BRIEF:
%    In the current patch discovery implementation, we store for every
%    positive sample of a patch detector the corresponding feature vector.
%    However, ones the discovery is done, the features themselves are not
%    needed anymore and only demand lots of memory.
%    -> We delete them here :)

    for i=1:length(patches)
        [ myBI ] = patches(i).blocksInfo;
        myBI = rmfield ( myBI, 'feature' );
        patches(i).blocksInfo = myBI;
    end
end