function out = showWeightVectorColorNames( w, settings )
% function out = showWeightVectorColorNames( w, settings )
% 
% author: Alexander Freytag
% date  : 17-03-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   Given a weight vector w obtained by training a model with colorNamesFeatures, 
%   positive and negative components are displayed separately
% 
% INPUT :
%    w       --  weight vector of model
%    settings
%            --  (optional), struct with possible fields, e.g.,
%                'b_closeImg', 'b_hardAssignment', ...
% 
% OUTPUT :
%    out     -- (optional), the resulting image of visualized model


    %% ( 0 ) check input
    if ( nargin  < 2 )
        settings = [];
    end
    
    b_closeImg = getFieldWithDefault ( settings, 'b_closeImg', false);

    %% ( 1 ) Make pictures of positive and negative weights
    
    settings  = addDefaultVariableSetting( settings, 'widthOfCell',  20, settings ); 
    settings  = addDefaultVariableSetting( settings, 'heightOfCell', 20, settings );
    settings  = addDefaultVariableSetting( settings, 'b_showImage',  false, settings );
    pos = visualizeColorNames (  w, settings );
    neg = visualizeColorNames ( -w, settings );
    
    scale = max(max(w(:)),max(-w(:)));
    pos = pos ./ scale;
    neg = neg ./ scale;
 

    %% ( 2 ) Put pictures together
    if min( w(:) ) < 0
      buff = 10;
      pos  = myPadArray( pos, [buff buff, 0], 0.5 );
      neg  = myPadArray( neg, [buff buff, 0], 0.5 );
      im   = [pos neg];
    else
      im   = pos;
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
