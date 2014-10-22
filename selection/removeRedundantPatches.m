function [ patchesCleanedUp, out_idxOfFinalPatches ]= removeRedundantPatches( patches, settings )    
%function [ patchesCleanedUp, out_idxOfFinalPatches ]= removeRedundantPatches( patches, settings )
%
%   BRIEF: 
%        Given discovered patch detectors, we compute pairwise cosine
%        similarities and remove all detectors with similarity higher than
%        a specified threshold.
%        If detectors have a field 'discriminativeness', then for two
%        redundant detectors, the higher scored onesis preferred.
%
%   INPUT: 
%        patches    --   our current set of patches (with models), we now want to figure
%                        out which of them are non-redundant
%        settings   --   struct, (optional), settings used: d_thrRedundant,
% 
%   OUTPUT: 
%        patchesCleanedUp      -- the subset of patches which were found to be
%                                 non-redundant
%        out_idxOfFinalPatches -- (optional), length(patches)  x 1 bool
%                                 vector indicating which detectors 'survived'
%
%   author: Alexander Freytag
%   date  : 15-05-2014 ( dd-mm-yyyy, last modified)

    if ( nargin < 2 )
        settings = 0;
    end
    
    d_thrRedundant = getFieldWithDefault ( settings, 'd_thrRedundant', 0.5 );
    
    idxOfFinalPatches = false( length(patches),1 );
    
    % have the detectors been scored previously be a selection technique?
    % then sort them according to those scores as done in the blocks that
    % shout paper.
    if ( isfield( patches(1), 'discriminativeness' ) )
        [~, indicesToProcess ] = sort ( [patches.discriminativeness], 'descend' );
    else
        indicesToProcess = 1:length(patches);
    end
    
    
    
    
    for idxCnt=1:length(patches)
        
        idx = indicesToProcess ( idxCnt );
        
        redundancy = checkForRedundancy( patches( idx ), patches( idxOfFinalPatches ), d_thrRedundant );
        
        if ( ~redundancy )
            %remember this index
            idxOfFinalPatches ( idx ) = true;
        else
            % do nothing, i.e., keep the current index on the 'redundant
            % list'
%            %show the HoG results of the redundant patch
%            figure(1);
%            showResults( patches( idx ) );
%            
%            %show the HoG results of the patch which lead to redundancy
%            figure(2);
%            showResults( patches(idxOfRedundantPatch) );           
% 
%            %wait for user response and close everything before
%            %continuing
%            pause;
%           close(1);close(2);
        end            
        
    end
    
    patchesCleanedUp = patches( idxOfFinalPatches );
    
    if ( nargout > 1 ) 
        out_idxOfFinalPatches  = idxOfFinalPatches;
    end
end
