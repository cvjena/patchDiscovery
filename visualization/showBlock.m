function showBlock( block, b_closeImages )
% function showBlock( block, b_closeImages )
% 
% author: Alexander Freytag
% date  : 14-02-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   Shows a single cropped block together with its original images it 
%   belongs to. Among others, useful to check proper results of seeding
%   (e.g., via  >>>  showBlock ( seedingBlocks(1), false );  )
% 
% INPUT :
%    block         --  struct, which consists at least of the fields 
%                        block.im ( filename of the orignal image) and
%                        block.x1, block.y1, block.x2, block.y2 (corner
%                        coordinates of cropped block)
%    b_closeImages --  (optional), if true, shown images are closed before
%                      ending the script, default: true
%          

    if ( nargin < 2 ) 
        b_closeImages = true;
    end

    imgOrig = readImage(block.im);
    
    figOrig = figure;
    s_titleOrig = sprintf('Original image' );            
    set ( figOrig, 'name', s_titleOrig);     
    imshow( imgOrig );
    
    x1 = block.x1;
    x2 = block.x2;
    y1 = block.y1;
    y2 = block.y2;
    
    w=round( x2 - x1 );
    h=round( y2 - y1 );
    
    % NOTE we could also think about painting the block rectangle into the
    % original image here...
    
    imgCropped = imcrop ( imgOrig, [x1,y1,w,h]);
    
    figCropped = figure;
    s_titleCropped = sprintf('Cropped block' );            
    set ( figCropped, 'name', s_titleCropped);     
    imshow ( imgCropped );
    
    pause
    
    if ( b_closeImages )
        close ( figOrig );
        close ( figCropped );
    end

end