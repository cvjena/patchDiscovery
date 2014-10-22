function figTrainImg = showDataset ( dataset, settings ) 
% function figTrainImg = showDataset ( dataset, settings ) 
% 
%  BRIEF:
%    Show all images ( or a specified subset) of a given dataset.
% 
%  INPUT:
% 
%  OUTPUT:
% 
% 
% author: Alexander Freytag
% date  : 05-03-2014 ( dd-mm-yyyy )

    if ( nargin < 2  )
        settings = [];
    end
    
    % dataset empty? than nothing to display
    if ( isempty( getFieldWithDefault ( dataset, 'images', [] ) ) )
        return;
    end

    % how many images to display? default: all :)
    i_numImagesToDisplay = getFieldWithDefault ( settings, 'i_numImagesToDisplay', length ( dataset.images ) );
    
    figTrainImg = figure;
    maxi = ceil(sqrt( i_numImagesToDisplay ));
    vPad = 255;
    % a bit of padding for nice visualization
    buff = 2;        
    

    % get size of first image
    firstIm     = readImage ( dataset.images{ 1 } );
    i_imgHeight = size ( firstIm, 1 );
    i_imgWidth  = size ( firstIm, 2 );            
    i_numDim    = size ( firstIm, 3 );
    
    % was a given size for images enforced? If so, set it accordingly
    % if not, take size of first image as standard
    i_imgHeight = getFieldWithDefault ( settings, 'i_imgHeight', i_imgHeight );
    i_imgWidth  = getFieldWithDefault ( settings, 'i_imgWidth', i_imgWidth );
    i_numDim    = getFieldWithDefault ( settings, 'i_numDim', i_numDim );

    widthOfPaddedBlock  = 2*buff + i_imgWidth;
    heightOfPaddedBlock = 2*buff + i_imgHeight;
    width  = maxi*widthOfPaddedBlock;    
    height = ceil(i_numImagesToDisplay/maxi)*heightOfPaddedBlock;

    %pre-allocate memory since we assume all images being of same size
    %note: we could also inforce this here...
    currentImg      = readImage ( dataset.images{ 1 } );
    s_classOfImages = class(currentImg);
    im = zeros ( height, width, i_numDim, s_classOfImages );
    
    for blCnt=1:i_numImagesToDisplay
        yStart = (floor( (blCnt-1)/maxi)  ) *heightOfPaddedBlock+1;
        yEnd   = (floor( (blCnt-1)/maxi)+1) *heightOfPaddedBlock;
        xStart = (mod(blCnt-1,maxi))*widthOfPaddedBlock+1;
        xEnd   = (mod(blCnt-1,maxi)+1) *widthOfPaddedBlock;

        currentImg = readImage ( dataset.images{ blCnt } );
        %adapt size of current image if necessary
        if ( [size( currentImg,1),size( currentImg,2),size( currentImg,3)] ~= ...
             [ i_imgHeight, i_imgWidth, i_numDim] )
           if ( i_numDim == 3 )  
               currentImg = resizeColor ( currentImg );
           else
               currentImg = resizeGrayScale ( currentImg );
           end
           % be aware of not changing the type
           currentImg = cast ( currentImg, s_classOfImages );
        end

        % write padded image to desired place
        if ( i_numDim == 3 )  
            im ( yStart : yEnd, xStart : xEnd, : ) =  ...
                myPadArray ( currentImg, [buff buff, 0 ], vPad );
        else
            im ( yStart : yEnd, xStart : xEnd ) =  ...
                myPadArray ( currentImg, [buff buff ], vPad );
        end
    end

    iptsetpref('ImshowBorder','tight');
    iptsetpref('ImshowAxesVisible','off');
    imshow ( im ) ;
    % make images beeing displayed correctly, i.e., not skewed
    axis image;
    %don't show axis ticks
    set(gca,'Visible','off');     
end