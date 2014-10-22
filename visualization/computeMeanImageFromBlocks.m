function meanImg = computeMeanImageFromBlocks( blocks, model )
% function meanImg = computeMeanImageFromBlocks( blocks, model )
% 
% BRIEF:
%    Computes mean image by averaging over a set of blocks.
% 
% INPUT:
%    blocks   --  cell array of (dimX x dimX x colordepth) arrays,
%                 -> several blocks selected from images, most likely used 
%                    as positive samples to learn a patch detector from
%    model    -- (optional), only needed to warp blocks to proper
%                 size wrt to size of model.w and number of grid cells
% 
% OUTPUT:
%    meanImg  -- (dimX x dimX x colordepth) double array
% 
% author: Alexander Freytag
% date  : 16-05-2014 ( dd-mm-yyyy )
% 

    % pre-process blocks to standard size?
    % if no model was given, blocks are assumed to be already fitting...
    if ( nargin > 1)
        warpedTrainBlocks = warpBlocksToStandardSize ( model, [ blocks.box] );
    else
        warpedTrainBlocks = blocks;
    end
    
    % init memory
    meanImg = zeros(size(warpedTrainBlocks{1}) );
    
    % add image content of all blocks
    for blCnt=1:length(blocks)
        meanImg = meanImg +     double( warpedTrainBlocks{blCnt} );
    end
    
    % normalize to number of images
    meanImg = meanImg ./ double(  length(blocks) );

end