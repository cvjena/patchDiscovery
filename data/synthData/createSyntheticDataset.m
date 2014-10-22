function [dataset] = createSyntheticDataset ( destination, noImgPerClass, noCircles, saveImages )

  if ( (nargin < 1) | destination == 0 )
    destination = './synthData/';
  end
  
  if ( (nargin < 2) | (isnumeric(noImgPerClass) && noImgPerClass == 0) )
    noImgPerClass = 30;
  end
  
  if ( (nargin < 3) | (isnumeric(noCircles) && noCircles == 0) )
    noCircles = 5;
  end
  
  if ( (nargin < 4) )
      saveImages = true;
  end
  
  %setting for first class
  drawTriangle = true;
  drawRectangle = false;
  
  %pre-allocate storage for output variables
  if ( nargout > 0 )
      dataset.images = cell(2*noImgPerClass,1);
      dataset.labels = zeros(1,2*noImgPerClass);
  end
  
  for i=1:noImgPerClass
      filename=sprintf('%striangles/triangleImg%i.png', destination,i ); 
      
      if ( saveImages )
        drawSyntheticImage( noCircles, drawTriangle, drawRectangle, filename);
      else
%         drawSyntheticImage( noCircles, drawTriangle, drawRectangle);
      end
      
      if ( nargout > 0 )
        dataset.images{i} = filename;
        dataset.labels(i) = 1;
      end      
  end
  
  %setting for second class
  drawTriangle = false;
  drawRectangle = true;
  
  for i=1:noImgPerClass
      filename=sprintf('%srectangles/rectangleImg%i.png', destination,i ); 
      
      if ( saveImages )
          drawSyntheticImage( noCircles, drawTriangle, drawRectangle, filename);
      else
%         drawSyntheticImage( noCircles, drawTriangle, drawRectangle);          
      end

      
      
      if ( nargout > 0 )
        dataset.images{noImgPerClass+i} = filename;
        dataset.labels(noImgPerClass+i) = 2;
      end      
  end 
  

  noTrainImg = 15;
  dataset.trainImages = [1:noTrainImg, noImgPerClass+1:noImgPerClass+1+noTrainImg ];
  dataset.valImages = [noTrainImg+1:noImgPerClass, noImgPerClass+1+noTrainImg:2*noImgPerClass ];
      
end