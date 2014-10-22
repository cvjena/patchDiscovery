function imWithBoxes = drawBoxesToImg(im, boxes, partcolor)
% showboxes(im, boxes)
% Draw boxes on top of image.


if nargin < 3,
  partcolor{1}    = [255,0,0];
  partcolor(2:20) = num2cell(repmat( [0,0,255], [19,1]),2);
end

i_linewidth = 1;


if ( nargout == 0)
    %imagesc(im); axis image; axis off;
    imshow(im); hold on;
    if ~isempty(boxes)
      numparts = floor(size(boxes, 2)/4);
      for i = 1:numparts
        x1 = boxes(:,1+(i-1)*4);
        y1 = boxes(:,2+(i-1)*4);
        x2 = boxes(:,3+(i-1)*4);
        y2 = boxes(:,4+(i-1)*4);
        line([x1 x1 x2 x2 x1]',[y1 y2 y2 y1 y1]','Color',partcolor{i},'linewidth',i_linewidth);
      end
    end
    drawnow;
    hold off;
else
    
    if ( ndims(im) == 2 )
        imWithBoxes = repmat( im, [1,1,3] );        
    else
        imWithBoxes = im;
    end
        
    
    hold on;
    
    i_offset = i_linewidth/2;
    

    %imagesc(im); axis image; axis off;
    if ~isempty(boxes)
      numparts = floor(size(boxes, 2)/4);
           
            
      for i = 1:numparts
          
        %[dist-to-left dist-to-top dist-to-left+width dist-to-top+height]  
        x1 = boxes(:,1+(i-1)*4);
        y1 = boxes(:,2+(i-1)*4);
        x2 = boxes(:,3+(i-1)*4);
        y2 = boxes(:,4+(i-1)*4);
        
        [ height, width, ~ ] = size ( imWithBoxes );
        
        i_minLeft   = max ( 1 , x1-i_offset );
        i_maxRight  = min ( width, x2+i_offset);
        i_minBottom = max ( 1 , y1-i_offset );
        i_maxTop    = min ( height, y2+i_offset);
%         
        imWithBoxes( i_minBottom:y2+i_offset, i_minLeft:x1+i_offset, 1) = partcolor{i}(1);
        imWithBoxes( i_minBottom:y2+i_offset, i_minLeft:x1+i_offset, 2) = partcolor{i}(2);
        imWithBoxes( i_minBottom:y2+i_offset, i_minLeft:x1+i_offset, 3) = partcolor{i}(3);
%         
        imWithBoxes( i_minBottom:i_maxTop,        x2-i_offset:i_maxRight, 1) = partcolor{i}(1);
        imWithBoxes( i_minBottom:i_maxTop,        x2-i_offset:i_maxRight, 2) = partcolor{i}(2);
        imWithBoxes( i_minBottom:i_maxTop,        x2-i_offset:i_maxRight, 3) = partcolor{i}(3);
%         
        imWithBoxes( i_minBottom:y1+i_offset, x1:x2, 1) = partcolor{i}(1);
        imWithBoxes( i_minBottom:y1+i_offset, x1:x2, 2) = partcolor{i}(2);
        imWithBoxes( i_minBottom:y1+i_offset, x1:x2, 3) = partcolor{i}(3);
%         
        imWithBoxes( y2-i_offset:i_maxTop, x1:x2, 1) = partcolor{i}(1);      
        imWithBoxes( y2-i_offset:i_maxTop, x1:x2, 2) = partcolor{i}(2); 
        imWithBoxes( y2-i_offset:i_maxTop, x1:x2, 3) = partcolor{i}(3); 
      end
    end
end


