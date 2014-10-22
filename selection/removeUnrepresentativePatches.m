function [patchesRelevant] = removeUnrepresentativePatches ( patches, settingsFinalSelection )
% function [patches] = removeUnrepresentativePatches ( patches, settingsFinalSelection )
%
% BRIEF: selectPatches 
%
%   The function accepts the following options:
%   INPUT: 
%        patches    --   our current set of patches (with models), we now want to figure
%                        out which of them are the discriminative ones
%        settingsSelection  --   
%
%   OUTPUT: 
%        patches --  the subset of patches which were found to be
%                    representative, i.e., containing at least k 
%                    positive training blocks
%

    if ( (~isfield ( settingsFinalSelection, 'i_minNoPos' ) ) || (isempty( settingsFinalSelection.i_minNoPos ) ) )
        i_minNoPos = 3;
    else
        i_minNoPos = settingsFinalSelection.i_minNoPos;
    end

    idxRepresentative = ( cellfun ( @length, {patches.blocksInfo}) >= i_minNoPos );
    patchesRelevant = patches( idxRepresentative );

end