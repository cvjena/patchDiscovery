function drawSyntheticImage( noOfCircles, drawTriangle, drawRectangle, filename )

  if (nargin < 2 )
      drawTriangle = false;
  end
  if (nargin < 3 )
      drawRectangle = false;
  end
  
  

%   hFig1=figure('Color',[1 1 1]);
  hFig1=figure();
   
  set(hFig1,'PaperUnits','inches');
  set(hFig1,'PaperPosition',[1 1 5 5]);
  set(hFig1,'PaperPositionMode','manual');  

  
  width = 500;
  height = 500;
  set(hFig1,'Color',[1 1 1]);
  set(hFig1, 'Position', [0 0 width height],'Color',[1 1 1]);
  %set the aspect ratio to be non-autoadjustive
  set(gca,'DataAspectRatio',[1 1 1]);
  % and also set the size fix, ie, non-autoadjustive
  axis([0 width 0 height])  
  
  hold on 
 
  %draw some circles
  
  myRadius = 30;
  myColor = [0 0 0]; 
  offset = 40;
  
  for i=1:noOfCircles     
      xc = (randi(width-2*offset,1)+offset);
      yc = (randi(height-2*offset,1)+offset);
      drawFilledCircle( xc, yc, myRadius, myColor );
  end
  
  myColor = [0.5,0.5,0.5];  %gray
  
  % now draw a triangle
  if ( drawTriangle )
      mySize=60;
      left = (randi(width-mySize-offset,1)+offset);
      bottom = (randi(width-mySize-offset,1)+offset);
      drawFilledTriangle( left, bottom, mySize, myColor );
  end
  
  
  % now draw a rectangle
  if ( drawRectangle )
      mySize=70;
      left = randi(width-mySize,1);
      bottom = randi(width-mySize,1);
      drawFilledRectangle( left, left+mySize, bottom, bottom+mySize, myColor );
  end

  axis off
  
  if ( nargin > 3 )
    print( hFig1, '-dpng', '-r100', filename);
  else
      pause
  end
  
  close( hFig1 );
    
end