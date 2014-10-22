function ivo = computeIntersectionOverUnion ( varargin )

    %% (1) parse inputs
    
    if ( nargin == 2)

         box1 = varargin{1};
         box2 = varargin{2};    
         %two rectangles overlap if: 
         %    ( max(x1, x1') < min(x2, x2') ) 
         %                  AND 
         %    ( max(y1, y1') < min(y2, y2') )

         if ( isa(box1,'double') && isa(box2,'double') )
             % were both boxes generated from regionprobs?
             % than (:,1) - x1, (:,2) - y1, (:,3) - x2, (:,4) - y2
             box1_x1 = box1(1,1);
             box1_y1 = box1(1,2);
             box1_x2 = box1(1,3);
             box1_y2 = box1(1,4); 

             box2_x1 = box2(1,1);
             box2_y1 = box2(1,2);
             box2_x2 = box2(1,3);
             box2_y2 = box2(1,4);             
             

         elseif ( isa(box2,'double') )
             % was only box2 generated from regionprobs?     
             % than (:,1) - x1, (:,2) - y1, (:,3) - widht, (:,4) - height
             box1_x1 = box1.x1;
             box1_y1 = box1.y1;
             box1_x2 = box1.x2;
             box1_y2 = box1.y2; 

             box2_x1 = box2(1,1);
             box2_y1 = box2(1,2);
             box2_x2 = box2(1,1)+box2(1,3);
             box2_y2 = box2(1,2)+box2(1,4);
             
             width  = max( 0.0, min (box1.x2, box2(1,1)+box2(1,3)) - max( box1.x1, box2(1,1)) ) ;
             height = max( 0.0, min (box1.y2, box2(1,2)+box2(1,4)) - max( box1.y1, box2(1,2)) ) ;
             intersection = width*height;
             area1 = abs ( ( box1.x2 - box1.x1) * ( box1.y2 - box1.y1 ) );
             area2 = box2(1,3) * box2(1,4);
             union = area1+area2-intersection;
             %note: we assume regions to have areas > 0 
             ivo = intersection / double ( union );

         else
             % are both boxes from our block-struct?   
             box1_x1 = box1.x1;
             box1_y1 = box1.y1;
             box1_x2 = box1.x2;
             box1_y2 = box1.y2; 

             box2_x1 = box2.x1;
             box2_y1 = box2.y1;
             box2_x2 = box2.x2;
             box2_y2 = box2.y2;
         
         end
         
         clear ( 'box1');
         clear ( 'box2');
         
    elseif ( nargin == 5)
         box1 = varargin{1};
         box1_x1 = box1.x1;
         box1_y1 = box1.y1;
         box1_x2 = box1.x2;
         box1_y2 = box1.y2; 
         clear('box1');
         
         box2_x1 = varargin{2};
         box2_y1 = varargin{3};
         box2_x2 = varargin{4};
         box2_y2 = varargin{5};    
    else
        ivo = 0.0;  % unknown
        return;
    end
 
    
    %% (2) actually compute the ivo score
    % are both boxes from our block-struct?         
    width  = max( 0.0, min (box1_x2, box2_x2) - max( box1_x1, box2_x1) ) ;
    height = max( 0.0, min (box1_y2, box2_y2) - max( box1_y1, box2_y1) ) ;
    intersection = width*height;
    area1 = abs ( ( box1_x2 - box1_x1) * ( box1_y2 - box1_y1 ) );
    area2 = abs ( ( box2_x2 - box2_x1) * ( box2_y2 - box2_y1 ) );
    union = area1+area2-intersection;
    
    %note: we assume regions to have areas > 0 
    ivo = double(intersection) / double ( union );      
    
end