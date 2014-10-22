function [ seedingBlocks, seedingBlockLabels ] = doSeeding_Manually(dataset, settingsSeeding)
% [ seedingBlocks, seedingBlockLabels ] = doSeeding_Manually(dataset, settingsSeeding)
% 
% date: 04-02-2014 (dd-mm-yyyy)
% author: Alexander Freytag

    
    % check for model argument -- b_debug (show intermediate results)
    b_debug = getFieldWithDefault ( settingsSeeding, 'b_debug', false );    
    
     % save seeding results if b_verbose = true?
    b_saveSeedingImage        = getFieldWithDefault ( settingsSeeding, 'b_saveSeedingImage', false );
    s_seedingImageDestination = getFieldWithDefault ( settingsSeeding, 's_seedingImageDestination', '' );    
  
  
    statusMsg = sprintf( '\n(1) ====== Seeding ==== \n');
    disp(statusMsg);  
  
  
    
    % structure of seedingBlocks
    % seedingBlocks(i).im
    % seedingBlocks(i).x1 seedingBlocks(i).y1 seedingBlocks(i).x2 seedingBlocks(i).y2
    % seedingBlocks(i).label
    % seedingBlocks(i).cx
    % seedingBlocks(i).cy
  
    seedingBlocks =  struct('im',{},'x1',{},'y1',{},'x2',{},'y2',{},'cx',{},'cy',{},'label',{},'imgIdx',{});

    i_maxNoPartsPerImage = 15;
 
 
    %pre-allocate memory for speed reasons
    seedingBlocks(length(dataset.trainImages)*i_maxNoPartsPerImage).im = '';
    
    seedingBlockLabels = ones(length(dataset.trainImages)*i_maxNoPartsPerImage,1, 'uint16');    

    % we perform seeding only on training images, not on validation images
    tmpPartIdx = 1;
    for i=1:size(dataset.trainImages,2)   
        
        imgOrig = readImage( dataset.images{ dataset.trainImages(i) });
      
      
        if ( b_debug )
            statusMsg = sprintf( '   seeding on trainImg %i / %i',i, size(dataset.trainImages,2));
            disp(statusMsg);        
        end
      
        imgFig = figure;
        imshow ( imgOrig );  
        
        [X1,Y1,X2,Y2]=clickBoundingBoxes2D( i_maxNoPartsPerImage );
        
        %store information in our output struct
        for tmpIdx=1:size(X1,1)

            %assign img name
            seedingBlocks( tmpPartIdx ).im = dataset.images{ dataset.trainImages(i) };

            %assign bounding box of patch
            seedingBlocks( tmpPartIdx ).x1 = X1(tmpIdx);
            seedingBlocks( tmpPartIdx ).y1 = Y1(tmpIdx);
            seedingBlocks( tmpPartIdx ).x2 = X2(tmpIdx);
            seedingBlocks( tmpPartIdx ).y2 = Y2(tmpIdx);

            %assign center of mass of region
            seedingBlocks(tmpPartIdx).cx = abs ( X2(tmpIdx)-X1(tmpIdx) ) ;
            seedingBlocks(tmpPartIdx).cy = abs ( Y2(tmpIdx)-Y1(tmpIdx) );                
            % add label information of the corresponding image
            seedingBlocks(tmpPartIdx).label = dataset.labels( dataset.trainImages(i) );

            seedingBlocks(tmpPartIdx).imgIdx = dataset.trainImages(i); % equals: dataset.map_fnToIdx( dataset.images{ dataset.trainImages(i) } ) ;

            seedingBlockLabels(tmpPartIdx) = dataset.labels( dataset.trainImages(i) );

            % increse counter accordingly
            tmpPartIdx = tmpPartIdx +1;                
        end 
        
        if ( b_saveSeedingImage )
            
        	s_filename = sprintf('%sseedingResultImg_%07d.png',s_seedingImageDestination, dataset.trainImages(i) );
            set(  imgFig,'PaperPositionMode','auto')
            print(imgFig, '-dpng', s_filename);
        end          
        
        if ( b_debug )
            pause
        end        
        
        
        close ( imgFig ) ;
     
    end
  
    % remove empty blocks
    seedingBlocks      = seedingBlocks( 1:tmpPartIdx-1 );
    seedingBlockLabels = seedingBlockLabels( 1:tmpPartIdx-1 );

end
