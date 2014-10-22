function mask = readMask( imageName, settings )
% function mask = readMask( imageName, settings )
% 
% author: Alexander Freytag
% date:   18-03-2014 ( dd-mm-yyyy )

    if ( nargin < 2 )
        settings = [];
    end

    

    %% (1) READ THE MASK IN THE DESIRED WAY
    
    s_maskTechnique = getFieldWithDefault ( settings, 's_maskTechnique', 'gt' );
    if ( strcmp ( s_maskTechnique, 'gt' ) )
        if ~isempty(strfind(imageName,'cub200_2011')) 
            maskName = strrep(imageName, '/images/', '/segmentations/');
            maskName = strrep(maskName, 'jpg', 'png');
        else
            assert(false,'no gt masks implemented for this dataset');
        end
        anno = imread( maskName );
        mask = (anno > 0);
    elseif ( strcmp ( s_maskTechnique, 'grabcut' ) )
        
        im   = imread(imageName);        
        
        b_initGrabCutByBB = getFieldWithDefault ( settings, 'b_initGrabCutByBB', true );
        if ( b_initGrabCutByBB )
            bbox = readBbox( imageName );
        else
            bbox.left   = 1;
            bbox.top    = 1;            
            bbox.right  = size(im,2);
            bbox.bottom = size(im,1);
        end
        
        mask = grabCutMex(im,[bbox.lseft bbox.top bbox.right-bbox.left bbox.bottom-bbox.top]);
    elseif ( strcmp ( s_maskTechnique, 'bbox' ) )
        im   = imread(imageName);
        mask = false( size(im,1),size(im,2) );                
        
        bbox = readBbox( imageName );
        mask (bbox.top:bbox.bottom, bbox.left:bbox.right) = true;        
    else
        im   = imread(imageName);
        mask = true( size(im,1),size(im,2) );        
    end
    
    %% (2) CROP TO BOUNDING BOX IF DESIRED
    
    b_cropToBB = getFieldWithDefault ( settings, 'b_cropToBB', false );
    if ( b_cropToBB )
        
        bbox = readBbox( imageName );
        
        mask = imcrop(mask, [bbox.left bbox.top bbox.right-bbox.left bbox.bottom-bbox.top ]);
    end  
    
    %% (3) RESIZING TO STANDARD SIZE IF DESIRED
    
    if ( getFieldWithDefault (settings, 'b_resizeImageToStandardSize', false ) )
        
        i_standardImageSize = getFieldWithDefault ( settings, 'i_standardImageSize', [128,128]);
        
        if ( ndims(i_standardImageSize) == 1)
            i_standardImageSize = repmat(i_standardImageSize, [1,2]);
        else
            i_standardImageSize = settings.i_standardImageSize;
        end
        
       mask = imresize(mask, i_standardImageSize);  
    end   
    

end