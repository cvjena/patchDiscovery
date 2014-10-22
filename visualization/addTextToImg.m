function imWithText = addTextToImg ( im, s_text, position ) 
% function imWithText = addTextToImg ( im, s_text, position ) 

    %TODO add color and further specifications via additional settings struct

    if ( (nargin < 3 ) || isempty(position) ||  ( size(position,2) ~=2 ))
        position = [100 100];
    end
    

    %% Create the text mask 
    % Make an image the same size and put text in it 
    hf = figure('color','white','units','normalized','position', [.1 .1 .8 .8]);
    image(ones(size(im))); 
    set(gca,'units','pixels','position',[5 5 size(im,2)-1 size(im,1)-1],'visible','off')

    % Text at arbitrary position 
    text('units','pixels','position', position ,'fontsize',10,'string',s_text) 

    % Capture the text image 
    % Note that the size will have changed by about 1 pixel 
    tim = getframe(gca); 
    close(hf) 

    % Extract the cdata
    tim2 = tim.cdata;

    % Make a mask with the negative of the text 
    tmask = tim2==0; 

    
    % Place white text 
    % Replace mask pixels with UINT8 max 
    
    % get single dimensions
    imR = im(:,:,1);
    imG = im(:,:,2);
    imB = im(:,:,3);
    
    % index dimensions separately and set color to easily recognizable
    % color spec
    imR ( tmask(:,:,1) ) = 125;
    imG ( tmask(:,:,2) ) = 0;
    imB ( tmask(:,:,3) ) = 125;
    
    % cat everything together and return image
    imWithText = cat( 3, imR, imG, imB);    
    
end