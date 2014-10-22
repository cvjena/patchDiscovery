function doesOverlap = checkOverlap ( varargin)
 doesOverlap = false;

 %two rectangles overlap if: 
 %    ( max(x1, x1') < min(x2, x2') ) 
 %                  AND 
 %    ( max(y1, y1') < min(y2, y2') )
 
 if ( nargin == 2)
     box1 = varargin{1};
     box2 = varargin{2};
      
     % was box2 generated from detection engine?
     if ( isa(box2,'double') )
         if  ( ( max( box1.x1, box2(1,1)) < min(box1.x2, box2(1,3)) ) && ( max(box1.y1, box2(1,2)) < min (box1.y2, box2(1,4)) ) )
             doesOverlap = true;
         end
     % or is it from our block-struct?    
     else
         if  ( ( max( box1.x1, box2.x1  ) < min(box1.x2, box2.x2)   ) && ( max(box1.y1, box2.y1  ) < min (box1.y2, box2.y2) )   )
             doesOverlap = true;
         end     
     end
 elseif ( nargin == 5)
     box1 = varargin{1};
     box2_x1 = varargin{2};
     box2_y1 = varargin{3};
     box2_x2 = varargin{4};
     box2_y2 = varargin{5};
     if  ( ( max( box1.x1, box2_x1) < min(box1.x2, box2_x2) ) && ( max(box1.y1, box2_y1) < min (box1.y2, box2_y2) ) )
         doesOverlap = true;
     end     
 else
     false; % unknown
 end
 
end