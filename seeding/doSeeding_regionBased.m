function [ seedingBlocks, seedingBlockLabels ] = doSeeding_regionBased(dataset, settingsSeeding)

  % check for model argument -- sigma (gaussian smoothing)
  sigma = getFieldWithDefault ( settingsSeeding, 'sigma', 0.5 );
  
  % check for model argument -- k (region regularizer)  
  k = getFieldWithDefault ( settingsSeeding, 'k', 500 );

  % check for model argument -- minSize (hard lower bound)
  minSize = getFieldWithDefault ( settingsSeeding, 'minSize', 50 );
  
  % check for model argument -- b_verbose (show final results in every image)
  b_verbose = getFieldWithDefault ( settingsSeeding, 'b_verbose', false );
  
  % when displaying results, should we wait for keyboard response?
  b_waitForInput = getFieldWithDefault ( settingsSeeding, 'b_waitForInput', b_verbose );  
  
  
  % check for model argument -- b_debug (show intermediate results)
  b_debug = getFieldWithDefault ( settingsSeeding, 'b_debug', false );
  
  % check for model argument -- postProRelSize 
  postProRelSize = getFieldWithDefault ( settingsSeeding, 'postProRelSize', true );
  
  % check for model argument -- postProMinSize 
  postProMinSize = getFieldWithDefault ( settingsSeeding, 'postProMinSize', 1.0000e-03 );%equals 500 px for img of size 0.5 Mpx
  % previously: 500 as default, which correspondes to pixel rather to
  % relative sizes

  
  % check for model argument -- postProMaxSize 
  postProMaxSize = getFieldWithDefault ( settingsSeeding, 'postProMaxSize', 0.003 );%equals 1500 px for img of size 0.5 Mpx
  % previously: 1500 as default, which correspondes to pixel rather to
  % relative sizes  
  
  % check for model argument -- postProMinGrad 
  postProMinGrad = getFieldWithDefault ( settingsSeeding, 'postProMinGrad', 0.07 );%arbitrary value, chose a better one!  
  
  % check for model argument -- scales (for rescaling the image) 
  scales = getFieldWithDefault ( settingsSeeding, 'scales', [0;1;2;3] );%scale with 2^(-scales(1,idxScale)/3.0)
  
  % check for model argument -- b_useRegionBBs (BBs of regions or 64x64)
  b_useRegionBBs = getFieldWithDefault ( settingsSeeding, 'b_useRegionBBs', true );

  
  % check for model argument -- offset (space to img boundary that shall be without BB centers)
  %ideally, this should somehow equal half the sixe of the largest feature
  %we can extract... or something like this
  offset = getFieldWithDefault ( settingsSeeding, 'offset', 40 );
  
  % how many seeding results PER SCALE do we at least want to have?
  % note: if we set this to zero, we enforce no minimum number at all
  i_minNoBlocks = getFieldWithDefault ( settingsSeeding, 'i_minNoBlocks', 1 );
  
  % save seeding results if b_verbose = true?
  b_saveSeedingImage        = getFieldWithDefault ( settingsSeeding, 'b_saveSeedingImage', false );
  s_seedingImageDestination = getFieldWithDefault ( settingsSeeding, 's_seedingImageDestination', '' );
  
  if ( b_saveSeedingImage && (~exist( s_seedingImageDestination, 'dir') ) )
      mkdir ( s_seedingImageDestination );
  end

  
  d_overlapThr_sameScale = settingsSeeding.d_overlapThr_sameScale;
  d_overlapThr_diffScale = settingsSeeding.d_overlapThr_diffScale;
  
  if ( b_verbose )
    statusMsg = sprintf( '\n(1) ====== Seeding ==== \n');
    disp(statusMsg);  
  end
 
  
    % structure of seedingBlocks
    % seedingBlocks(i).im
    % seedingBlocks(i).x1 seedingBlocks(i).y1 seedingBlocks(i).x2 seedingBlocks(i).y2
    % seedingBlocks(i).label
    % seedingBlocks(i).cx
    % seedingBlocks(i).cy
  
 seedingBlocks =  struct('im',{},'x1',{},'y1',{},'x2',{},'y2',{},'cx',{},'cy',{},'label',{},'imgIdx',{});
 seedingBlockLabels = [];
 
  b_maskImages = settingsSeeding.b_maskImages;

  % we perform seeding only on training images, not on validation images
  for i=1:size(dataset.trainImages,2)     
      
      if ( b_debug )
        statusMsg = sprintf( '   seeding on trainImg %i / %i',i, size(dataset.trainImages,2));
        disp(statusMsg);        
      end
      
      imgOrig = readImage( dataset.images{ dataset.trainImages(i) });
      imgOrigNonMasked = imgOrig;
      
      if ( b_verbose )
          figOrig = figure;
          imshow ( imgOrig );
      end
      
      if ( b_maskImages )
          try 
            mask        = readMask( dataset.images{ dataset.trainImages(i) } );
            mask(:,:,2) = mask(:,:,1);
            mask(:,:,3) = mask(:,:,1);
            % simple masking to guide seeding to foreground regions
            % adapted this strategy from masking of our CVPR'14 paper
            imgOrig(mask==0)=0;      
          catch err
              if ( b_verbose )
                disp ( 'No masking information available!')
              end
          end
      end
      
      boundingBoxesImg=[];
      centroidsImg=[];
      aspectRatiosImg=[];
      
      seedingBlocksImg = {};
      seedingBlockLabelsImg = [];


      i_currentNoBlocks = 0;      
            
      for idxScale=1:size(scales,2)
          %% (0) Pre-Processing: re-scale input image
          scaleFactor = 2^(-scales(1,idxScale)/3.0);
          imgScaled = imresize(imgOrig, scaleFactor);

          %show scaled version of input image          
          if ( b_debug )
            fScale = figure;
            set ( fScale, 'name', 'Scaled version of input');
            imshow(imgScaled);
          end


          %% (1) run the segmentation algorithm on the scale image
          %TODO fix this and make it nicer - perhaps move the padding to
          %the segmentation-method, or even implement a special method for
          %gray scale images
          if ( length(size(imgScaled)) == 2) 
              [heightScaled, widthScaled, ~] =size(imgScaled);
              % nasty workaround since felzenszwalb does not support gray
              % scale images...
              imgTmp = cat(3, imgScaled, zeros(heightScaled,widthScaled ), zeros(heightScaled,widthScaled ) );
          else
              imgTmp = imgScaled;
          end
          [ segResult noSegs ] = segmentFelzenszwalb(imgTmp, sigma, k, minSize, false);

          % does our loading scheme works properly?
          if ( b_debug ) 
            fSegInput=figure;
            set ( fSegInput, 'name', 'Segmentation result');
            imshow(segResult);
            % make region colors visually distinguishable
            colormap ( 'lines' );
            pause
            close(fScale);            
            close(fSegInput);
          end
      
          

          %% (2) compute bounding boxes and centers of mass
          regionProbsResult = regionprops(segResult,'BoundingBox', 'Centroid','Area', 'Image' );
        

          %prepare centers of mass
          centroidsScaled = cat(1, regionProbsResult.Centroid);
          % detect NaN entries which occured due to Matlab stuff
          idxUsefulEntries = sum(isnan(centroidsScaled),2)==0;
          % remove NaN entries from results
          regionProbsResult = regionProbsResult(idxUsefulEntries);    
          centroidsScaled = centroidsScaled(idxUsefulEntries,:);
          %note: now we should have as many entries as noSegs says
          

          areasImg = cat(1, regionProbsResult.Area);
          % ensure that the ordering of our proposals is (almost) the same in
          % every run!
          % small regions preferred :)
          [ ~, sortIdx] = sort( areasImg, 'ascend');
          areasImg = areasImg ( sortIdx );
          
%         statusMsg=sprintf( 'scale: %f  --  segs: %d --  largest area: %f \n', scales(1,idxScale), noSegs, areasImg(1:1) );
%         disp(statusMsg);          
                    
            
          regionProbsResult = regionProbsResult( sortIdx );
          centroidsScaled = centroidsScaled( sortIdx, : );
          clear ( 'sortIdx' );

          %prepare bounding boxes and areas for postprocessing stage
          boundingBoxesImgScaled = cat(1, regionProbsResult.BoundingBox);
          
          % not needed anymore
          clear( 'regionPropsResult') ;



          %% (3) postProcessing

          %postProcessing ( 3.1 ) - reject too small / large regions
          
          invFactorScale = 1.0 / scaleFactor;          
          
          [heightOrig, widthOrig, ~] =size(imgOrig);

          if ( postProRelSize )              
              idxAreasToAccept = ( ( (invFactorScale^2 * areasImg) < (postProMaxSize*widthOrig*heightOrig) ) & ( (invFactorScale^2 * areasImg)  >  (postProMinSize*widthOrig*heightOrig) ) );
          else
             idxAreasToAccept = ( ( (invFactorScale^2 * areasImg) < postProMaxSize) & ( (invFactorScale^2 * areasImg) > postProMinSize) );
          end
          
          if ( sum(idxAreasToAccept) == 0)
              if ( b_debug )
                disp('removed almost all seedings due to small area')
              end
          end

          %not needed anymore
          clear('areasImg');

          boundingBoxesImgScaled = boundingBoxesImgScaled(idxAreasToAccept,:);
          centroidsScaled = centroidsScaled(idxAreasToAccept,:);
          
          
          
          
          
          %postProcessing ( 3.2 ) - reject regions too close to the img boundary
          [heightScaled, widthScaled, ~] =size(imgScaled);
          checkLeft = offset;
          checkTop = offset;
          checkRight = widthScaled - offset;
          checkBottom = heightScaled - offset;
          
%           idxNotTooClose = ( ( invFactorScale * centroidsScaled(:,1)   > checkLeft) & ...
%               ( invFactorScale * centroidsScaled(:,1)   < checkRight) &  ...
%               ( invFactorScale * centroidsScaled(:,2)   > checkTop) & ...
%               ( invFactorScale * centroidsScaled(:,2)   < checkBottom) );
          idxNotTooClose = ( ( centroidsScaled(:,1)   > checkLeft) & ...
                             ( centroidsScaled(:,1)   < checkRight) &  ...
                             ( centroidsScaled(:,2)   > checkTop) & ...
                             ( centroidsScaled(:,2)   < checkBottom) );

          noGoodBlocksBoundary = sum(idxNotTooClose);
           
          % here we definitely (!) reject all blocks that do not satisfy the
          % criterion of being a bit away from the boundary, even if we
          % would delete (almost) all of our proposals
          if ( noGoodBlocksBoundary < i_minNoBlocks)
              if ( b_debug )
                disp('removed almost all seedings due to small distances to img boundary')
              end
          end          
          clear('noGoodBlocksBoundary');
          
          
          boundingBoxesImgScaled = boundingBoxesImgScaled(idxNotTooClose,:);
          centroidsScaled = centroidsScaled(idxNotTooClose,:);
          
          clear( 'idxNotTooClose');
          
         % postProcessing ( 3.3 )
         % remove regions overlapping too strongly
         % keep the one with better (bigger) aspect ratio
         
         % therefore, let's first compute the aspect ratios for all
         % proposals of this scale with the actual bounding boxes obtained
         % from regionprob
         aspectRatios = zeros( length (boundingBoxesImgScaled), 1);
         for bbIt = 1:size(boundingBoxesImgScaled,1)
             aspectRatios( bbIt ) = min ( double(boundingBoxesImgScaled(bbIt,3) ) ...
                 / ( boundingBoxesImgScaled(bbIt,4)  ) ...
                 ,  ...
                 double(boundingBoxesImgScaled(bbIt,4) ) ...
                 / ( boundingBoxesImgScaled(bbIt,3) ) );
         end          
          

          
          %convert bounding boxes from [ x y width height] to [xl yl xr yr]          
          if (~b_useRegionBBs)
                boundingBoxesImgScaled(:,1) = centroidsScaled(:,1)-offset;
                boundingBoxesImgScaled(:,2) = centroidsScaled(:,2)-offset;
                boundingBoxesImgScaled(:,3) = centroidsScaled(:,1)+offset;
                boundingBoxesImgScaled(:,4) = centroidsScaled(:,2)+offset;   
          else
              boundingBoxesImgScaled(:,3) = boundingBoxesImgScaled(:,1) + boundingBoxesImgScaled(:,3);
              boundingBoxesImgScaled(:,4) = boundingBoxesImgScaled(:,2) + boundingBoxesImgScaled(:,4);               
          end
          
          
          %%% and go on with postProcessing ( 3.3 )
         
         idxNonOverlapping = true( size (boundingBoxesImgScaled,1), 1);
         
         if ( b_debug )
             fBB=figure;
             set ( fBB, 'name', 'Bounding boxes found in current scale');
             imshow(imgScaled)
             hold on   
             myBB = [  boundingBoxesImgScaled(:,1), boundingBoxesImgScaled(:,2), boundingBoxesImgScaled(:,3), boundingBoxesImgScaled(:,4) ];
             showboxes(imgScaled, myBB);
             hold off
         end

         % let's do a greedy approach for getting an "independent set of
         % proposals"
         for bbIt = 1:size(boundingBoxesImgScaled,1)
             for bbItInner = 1:bbIt-1
                 % only considere boxes which do not have been removed
                 % already
                 if ( ~idxNonOverlapping(bbItInner) )
                     continue;
                 end
                 % compute overlap over union
                 overlap =  computeIntersectionOverUnion ( boundingBoxesImgScaled(bbIt,:), boundingBoxesImgScaled(bbItInner,:) );

                 % threshold the score
                 if ( overlap > d_overlapThr_sameScale )
                    idxNonOverlapping ( bbIt ) = false;
                    break;                        
                 end                 
             end
         end
         
         if ( b_debug )
             fBBAfter = figure;
             set ( fBBAfter, 'name', 'Cleaned bounding boxes in current scale');
             imshow(imgScaled)
             hold on   
             myBB = [  boundingBoxesImgScaled(idxNonOverlapping,1), boundingBoxesImgScaled(idxNonOverlapping,2), boundingBoxesImgScaled(idxNonOverlapping,3), boundingBoxesImgScaled(idxNonOverlapping,4) ];
             showboxes(imgScaled, myBB);
             hold off         

             pause;
             close(fBB);
             close(fBBAfter);
         end
         
         
         boundingBoxesImgScaled = boundingBoxesImgScaled(idxNonOverlapping,:);
         centroidsScaled = centroidsScaled( idxNonOverlapping,:);    
         aspectRatios = aspectRatios( idxNonOverlapping); 
       

         
         %% ++++++++++++++++++++++++++++++++++          
          
          
          
          %postProcessing ( 3.4 ) - reject uniform regions
          %NOTE THIS SEEMS TO BE UNINTUITIVE, BUT WE STILL FOLLOW THE PAPER
          %AND DO IT NONETHELESS...

          %compute gradient image
          if ( size(imgScaled,3) == 3 )
             [gradMagHor,gradMagVer] = gradient(im2double(rgb2gray(imgScaled)));
          else
               [gradMagHor,gradMagVer] = gradient(im2double( imgScaled ));
          end
          gradMag = (gradMagHor.^2 + gradMagVer.^2).^(0.5);

          %take sub-windows corresponding to current regions

          imgVariations = zeros(size(boundingBoxesImgScaled,1) , 1);
          for bbIt = 1:size(boundingBoxesImgScaled,1)
              %myRect = [xmin, ymin, width, height]
              myRect = [ boundingBoxesImgScaled(bbIt,1), boundingBoxesImgScaled(bbIt,2), boundingBoxesImgScaled(bbIt,3)-boundingBoxesImgScaled(bbIt,1), boundingBoxesImgScaled(bbIt,4)-boundingBoxesImgScaled(bbIt,2)];
              subImg = imcrop(gradMag, myRect );
              imgVariations(bbIt) = mean ( subImg(:) );

              % show bounding boxes and sub image of gradient image for all
              % bbs
              if ( b_debug )
                  fRes = figure;
                  %imshow(segResult)
                  %nice title
                  set ( fRes, 'name', 'A BB on seg result');
                  
                  %show current box - this script also calls imshow(...)
                  myBB = [  boundingBoxesImgScaled(bbIt,1), boundingBoxesImgScaled(bbIt,2), boundingBoxesImgScaled(bbIt,3), boundingBoxesImgScaled(bbIt,4) ];
                  showboxes(segResult, myBB);
                  
                  % additionally, plot the centroid
                  hold on
                  plot(centroidsScaled(bbIt,1), centroidsScaled(bbIt,2), 'b*');
                  
                  
                  % make region colors visually distinguishable
                  colormap ( 'lines' );                  
                  hold off

                  fSub = figure;
                  set ( fSub, 'name', 'Subimage of BB');
                  imshow(subImg)

                  pause
                  close(fRes);    
                  close(fSub);    
              end
          end

          %only considere a region lateron if there is enough
          %gradient energy in it
          idxImgVariation = (imgVariations >= postProMinGrad);
          
          noGoodBlocksVariation = sum(idxImgVariation);
           
          if ( noGoodBlocksVariation < i_minNoBlocks)
              % run over variation scores and take at least m of the best results, 
              % in order to enshure that every images leads at least to several seeding blocks
              if ( b_debug )
                disp('removed all seedings due to low average gradient')
              end
              [~,permVariations] = sort(imgVariations,'descend');
              % note - we possibly have already less than i_minNoBlocks
              % proposals, but we pick min. i_minNoBlocks if possible
              idxImgVariation( permVariations(1:min( noGoodBlocksVariation,i_minNoBlocks) ) ) = true;
          end          
          clear( 'imgVariations'); clear('noGoodBlocksVariation');

          boundingBoxesImgScaled = boundingBoxesImgScaled( idxImgVariation,:);
          centroidsScaled = centroidsScaled( idxImgVariation,:);
          aspectRatios = aspectRatios( idxImgVariation); 
          %not needed anymore
          clear('regionPropsResult');
          

          %% (XXX) Convert everything into same scale
          
          % convert results for this scaling level to original resolution
          % this is ESSENTIAL since we extract HoG features based on these
          % bounding boxes from the input images
          boundingBoxesImgScaled = boundingBoxesImgScaled.* invFactorScale;          
          centroidsScaled        = centroidsScaled.* invFactorScale;
          
          
          % append to previously computed results of this image
          boundingBoxesImg = [boundingBoxesImg; boundingBoxesImgScaled];
          centroidsImg     = [ centroidsImg; centroidsScaled];
          aspectRatiosImg  = [aspectRatiosImg; aspectRatios];
          
          
          i_currentNoBlocks = i_currentNoBlocks + size(boundingBoxesImgScaled,1);
      end
      
      %% finally, perform some post-processing that removes proposals
      %% from different scales which overlap too strongly
      
         idxNonOverlapping = true( i_currentNoBlocks , 1);
         
         if ( b_debug )
             fBB=figure;
             set ( fBB, 'name', 'Orig image');
             imshow(imgOrig)
             hold on   
             myBB = [  boundingBoxesImg(:,1), boundingBoxesImg(:,2), boundingBoxesImg(:,3), boundingBoxesImg(:,4) ];
             showboxes(imgOrig, myBB);
             hold off
         end
         
         % remove regions overlapping too strongly
         % keep the the first one (assumed to be from scale with higher res.)
             
         % let's do a greedy approach for getting an "independent set of
         % proposals"
         for bbIt = 1:size(boundingBoxesImg,1)
             for bbItInner = 1:bbIt-1
                 % only considere boxes which do not have been removed
                 % already
                 if ( ~idxNonOverlapping(bbItInner) )
                     continue;
                 end

                 % compute overlap over union
                 overlap =  computeIntersectionOverUnion ( boundingBoxesImg(bbIt,:), boundingBoxesImg(bbItInner,:) );

                 % threshold the score
                 if ( overlap > d_overlapThr_diffScale )
                    idxNonOverlapping ( bbIt ) = false;
                    break;                        
                 end                 
             end
         end
         
         if ( b_debug )
             fBBAfter = figure;
             set ( fBBAfter, 'name', 'Cleaned BBs');
             imshow(imgOrig)
             hold on   
             myBB = [  boundingBoxesImg(idxNonOverlapping,1), boundingBoxesImg(idxNonOverlapping,2), boundingBoxesImg(idxNonOverlapping,3), boundingBoxesImg(idxNonOverlapping,4) ];
             showboxes(imgOrig, myBB);
             hold off         

             pause;
             close(fBB);
             close(fBBAfter);
         end      
      
      
      centroidsImg          = centroidsImg(idxNonOverlapping,:);
      boundingBoxesImg      = boundingBoxesImg(idxNonOverlapping,:);
      
      
      if ( b_verbose ) 
          bbFig=figure;
          set ( bbFig, 'name', 'Orig images with bb and centroids');
          imshow(imgOrigNonMasked)
 
          b_showBackgroundInGray = getFieldWithDefault ( settingsSeeding, 'b_showBackgroundInGray', false );
          
          if ( b_showBackgroundInGray )
              I=rgb2gray(imgOrigNonMasked);   

              hold on
              %plot(centroidsImg(:,1), centroidsImg(:,2), 'b*');
              handle = showboxes(I, boundingBoxesImg);
              hold off
              alpha_data = 196*uint8( ( mask(:,:,1) == 0 ) );
              alpha_data = 196*uint8( ( mask(:,:,1) == 0 ) );
              set(handle, 'AlphaData', alpha_data);                        
          else

              hold on
              %plot(centroidsImg(:,1), centroidsImg(:,2), 'b*');
              handle = showboxes(imgOrigNonMasked, boundingBoxesImg);
              hold off
          end
          
          if ( b_saveSeedingImage )
               s_filename = sprintf('%sseedingResultImg_%07d.png',s_seedingImageDestination, dataset.trainImages(i) );
               set(bbFig,'PaperPositionMode','auto')
               print(bbFig, '-dpng', s_filename);
          end      
          
          if ( b_waitForInput )
            pause
          end
          close(bbFig);
          close(figOrig);
      end
      
      i_currentNoBlocks = size ( boundingBoxesImg, 1 );
      %clear ( seedingBlocksImg );
      
      
      % convert all information to integer values
      boundingBoxesImg = round ( boundingBoxesImg );
      centroidsImg     = round ( centroidsImg );
      
      %store information in our output struct
      % decreasing loop for better storage usage (no re-allocations needed)
      for tmpIdx=i_currentNoBlocks:-1:1
          %assign img name
          seedingBlocksImg(tmpIdx).im = dataset.images{ dataset.trainImages(i) };
          %assign bounding box of patch
          seedingBlocksImg(tmpIdx).x1 = boundingBoxesImg(tmpIdx,1);
          seedingBlocksImg(tmpIdx).y1 = boundingBoxesImg(tmpIdx,2);
          seedingBlocksImg(tmpIdx).x2 = boundingBoxesImg(tmpIdx,3);
          seedingBlocksImg(tmpIdx).y2 = boundingBoxesImg(tmpIdx,4);

          %assign center of mass of region
          seedingBlocksImg(tmpIdx).cx = centroidsImg(tmpIdx,1);
          seedingBlocksImg(tmpIdx).cy = centroidsImg(tmpIdx,2);                
          % add label information of the corresponding image
          seedingBlocksImg(tmpIdx).label = dataset.labels( dataset.trainImages(i) );

          seedingBlocksImg(tmpIdx).imgIdx = dataset.trainImages(i); % equals: dataset.map_fnToIdx( dataset.images{ dataset.trainImages(i) } ) ;


          seedingBlockLabelsImg(tmpIdx) = dataset.labels( dataset.trainImages(i) );

      end         
      
      clear( 'aspectRatiosImg' );      
      clear( 'centroids' );
      clear( 'boundingBoxesImg' );
      
      if ( ~isempty(seedingBlocksImg) )
        seedingBlocks      =  cat ( 2, seedingBlocks, seedingBlocksImg );
        seedingBlockLabels = [seedingBlockLabels , seedingBlockLabelsImg ] ;
      else
          if ( b_debug )
            disp('No seeding blocks found for this image...');
          end
      end
    
  end

end
