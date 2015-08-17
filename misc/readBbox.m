function [bbox] = readBbox( s_imgfn )
% function [bbox] = readBbox( s_imgfn )
% 
% author: Alexander Freytag
% date:   02-04-2014 ( dd-mm-yyyy )
% 
% BRIEF:  Reads the gt bbox from file. Dataset is determined from path.
% 
% INPUT:   s_imgfn -- char array ( relative or absolute filename of image)
% 
% OUTPUT:  bbox    -- struct with fields 'left', 'top', 'right', 'bottom'


    if ~exist(s_imgfn,'file')
        s_imgfn = [getenv('HOME') '/' s_imgfn];
    end

    idxSlash = strfind(s_imgfn,'/');
    
    imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): end );
    className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );
    %imgDir      = s_imgfn( (idxSlash( (size(idxSlash,2)-2))+1):(idxSlash(size(idxSlash,2)-1)-1) );
    dataBaseDir = s_imgfn( 1:(idxSlash(size(idxSlash,2)-2)-1) );

    


    % dataset specific

    if ( ~isempty( strfind(s_imgfn,'cub200_2011') )  )  

        try
            fid = fopen([ dataBaseDir '/images.txt' ]);
            %todo: clever scan!            
            images = textscan(fid, '%s %s');
            fclose(fid);

            % searcg for ID of that specific image            
            imageId = find(strcmp(images{2}, sprintf('%s/%s',className, imgName)  ));
            assert(length(imageId) == 1);
            
            %todo: clever scan!
            bboxes = load([ dataBaseDir '/bounding_boxes.txt' ]);

            bbox.left   = bboxes(imageId,2);
            bbox.top    = bboxes(imageId,3);
            bbox.right  = bbox.left + bboxes(imageId,4);
            bbox.bottom = bbox.top  + bboxes(imageId,5);
            
        catch err
            fprintf('Error while reading bounding box information for image:\n\"%s\" \n -> take whole image instead...\n',s_imgfn)                       
            
            % read image and simply return full image size as bounding box
            im = imread(s_imgfn);
            bbox.left   = 1;
            bbox.top    = 1;
            bbox.right  = size(im,2);
            bbox.bottom = size(im,1);
        end


    else
        fprintf( 'there were no gt bounding boxes for this image. Is that supposed to happen?\n')
        
        % read image and simply return full image size as bounding box
        im = imread(s_imgfn);
        bbox.left   = 1;
        bbox.top    = 1;
        bbox.right  = size(im,2);
        bbox.bottom = size(im,1);
    end
end
