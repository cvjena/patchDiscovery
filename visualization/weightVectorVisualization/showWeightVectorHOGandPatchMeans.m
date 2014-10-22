function out = showWeightVectorHOGandPatchMeans( w, settings )
% function out = showWeightVectorHOGandPatchMeans( w, settings )
% 
% author: Alexander Freytag
% date  : 12-03-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   Given a weight vector w obtained by training a model with patchMeanFeatures, 
%   positive and negative components are displayed separately
% 
% INPUT :
%    w       --  weight vector of model
%    settings
%            --  (optional), struct with possible fields, e.g.,
%                'b_closeImg', ...
% 
% OUTPUT :
%    out     -- (optional), the resulting image of visualized model

    %% ( 0 ) check input
    if ( nargin  < 2 )
        settings = [];
    end
    
    b_closeImg = getFieldWithDefault ( settings, 'b_closeImg', false);


    %% ( 1 ) Make pictures of positive and negative weights
    imPos = visualizeHOGandPatchMeans (  w, settings );
    imNeg = visualizeHOGandPatchMeans ( -w, settings );
    
    %scalePM = max( max(max(max(w(:,:,33:end)))), max(max(max(-w(:,:,33:end)))) );
    %scaleHOG = max( max(max(max(w(:,:,1:32)))), max(max(max(-w(:,:,1:32)))) );
%     scale = max(max(imPos(:)),max(imNeg(:)));
%     imPos = imPos ./ scale;
%     imNeg = imNeg ./ scale;    
    
    %% ( 2 ) Put pictures together
    if min( w(:) ) < 0
        buff = 10;
        imPos  = myPadArray( imPos, [buff buff, 0], 0.5 );
        imNeg  = myPadArray( imNeg, [buff buff, 0], 0.5 );
        im     = [imPos imNeg];
    else
        im     = imPos;
    end
    
    %% ( 3 ) saturate image information out of [0,1]
    im(im < 0) = 0;
    im(im > 1) = 1;
    
    % scale to [0,255]
    im = im*255;    
    
    % convert to uint8 as usually done for images
    im = uint8(im); 
    
    %% ( 4 ) draw figure or output result
    if ( nargout == 0 )
        
        % create new figure
        figWeightVector = figure;
        
        % nice title
        s_titleWeight = sprintf('Pos and neg weight vector elements' );            
        set ( figWeightVector, 'name', s_titleWeight);          
        
        imagesc(im); 
        % make images beeing displayed correctly, i.e., not skewed
        axis image;
        %don't show axis ticks
        set(gca,'Visible','off');
        
        if ( b_closeImg )
            pause;
            close ( figWeightVector );
        end        
    else
      out = im;
    end 
end