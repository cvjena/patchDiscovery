function [ seedingBlocks, seedingBlockLabels ] = doSeeding_groundTruthParts(dataset, settingsSeeding)

    
  % check for model argument -- b_verbose (show final results in every image)
  b_verbose = getFieldWithDefault ( settingsSeeding, 'b_verbose', false );
  
  % check for model argument -- b_debug (show intermediate results)
  b_debug = getFieldWithDefault ( settingsSeeding, 'b_debug', false ); 
    
  % when displaying results, should we wait for keyboard response?
  b_waitForInput = getFieldWithDefault ( settingsSeeding, 'b_waitForInput', b_verbose );      
  
  % save seeding results if b_verbose = true?
  b_saveSeedingImage        = getFieldWithDefault ( settingsSeeding, 'b_saveSeedingImage', false );
  s_seedingImageDestination = getFieldWithDefault ( settingsSeeding, 's_seedingImageDestination', '' );  
  
  if ( b_saveSeedingImage && (~exist( s_seedingImageDestination, 'dir') ) )
      mkdir ( s_seedingImageDestination );
  end  
  
  
   if ( b_verbose )
	 statusMsg = sprintf( '\n(1) ====== Seeding ==== \n');
	 disp(statusMsg);
   end  
  
  

 
    %
    % Get the real ground-truth part locations
    %
    if ( true )%strcmp ( dataset.name, 'cub200_2011') )
        if ( ~isfield ( dataset, 'location') )
            %FIXME
            dataset.location = '/home/freytag/data/finegrained/cub200_2011/cropped_enlarged_256x256/';
        end
        
        dataBaseDir        = [dataset.location '/'];                  
            
        parts        = load([ dataBaseDir 'part_locs.txt' ]);
        
        fid = fopen([ dataset.location 'images.txt' ]);
        images = textscan(fid, '%s %s');
        fclose(fid);
        images = images{2};

        images = strcat([dataset.location 'images/'],images);         
    else
        assert(false, 'unknown gt part positions for specified dataset')
    end
    
    % structure of seedingBlocks
    % seedingBlocks(i).im
    % seedingBlocks(i).x1 seedingBlocks(i).y1 seedingBlocks(i).x2 seedingBlocks(i).y2
    % seedingBlocks(i).label
    % seedingBlocks(i).cx
    % seedingBlocks(i).cy
  
    seedingBlocks =  struct('im',{},'x1',{},'y1',{},'x2',{},'y2',{},'cx',{},'cy',{},'label',{},'imgIdx',{});
 
 
    i_maxNoPartsPerImage = 15;
    % as done in our bird paper
    %i_PartWith = 256*sqrt(2)/16; 
    %i_PartHeight = 256*sqrt(2)/16;
    
    % visually nicer
    i_PartWith = 256*sqrt(2)/8; 
    i_PartHeight = 256*sqrt(2)/8;    
 
 
    %pre-allocate memory for speed reasons
    seedingBlocks(length(dataset.trainImages)*i_maxNoPartsPerImage).im = '';
    usedBlocks = true(length(dataset.trainImages)*i_maxNoPartsPerImage,1);
    
    seedingBlockLabels = ones(length(dataset.trainImages)*i_maxNoPartsPerImage,1, 'uint16');    

    % we perform seeding only on training images, not on validation images
    for i=1:size(dataset.trainImages,2)   
        
        imgOrig = readImage( dataset.images{ dataset.trainImages(i) });
        
        i_imgHeight = size(imgOrig,1);
        i_imgWidth = size(imgOrig,2);        
      
        if ( b_debug )
            statusMsg = sprintf( '   seeding on trainImg %i / %i',i, size(dataset.trainImages,2));
            disp(statusMsg);        
        end
      
        s_fnOrig = dataset.images{ dataset.trainImages(i) };
        b_isFlipped = false;
        if ( ~isempty( strfind(s_fnOrig, '_flipped') ) )
            s_fnOrig = strrep( s_fnOrig, '_flipped','' );
            b_isFlipped = true;
        end
        idxOrig_img = find(cellfun(@(x) strcmp(x,s_fnOrig),images'));
            
        %<imgID partID centerX centerY visible>
            partsOfImg = parts( parts(:,1)==idxOrig_img,:); 
            if ( b_isFlipped )
                img = imread( s_fnOrig ); 
                sizeX = size( img, 2);
                partsOfImg(:,3) = sizeX - partsOfImg(:,3);
            end
      
      
        %store information in our output struct
        for tmpPartIdx=1:i_maxNoPartsPerImage
              partIdx = (i-1)*i_maxNoPartsPerImage + tmpPartIdx;              

            if ( partsOfImg(tmpPartIdx,5) == 0 ) % not visible
                usedBlocks ( partIdx ) = false;
            else % visible
                  %assign img name
                seedingBlocks( partIdx ).im = dataset.images{ dataset.trainImages(i) };
                %assign bounding box of patch
                seedingBlocks( partIdx ).x1 = max (0 , partsOfImg(tmpPartIdx,3) - i_PartWith/2 );
                seedingBlocks( partIdx ).y1 = max (0 , partsOfImg(tmpPartIdx,4) - i_PartHeight/2 );
                seedingBlocks( partIdx ).x2 = min (i_imgWidth , partsOfImg(tmpPartIdx,3) + i_PartWith/2 );
                seedingBlocks( partIdx ).y2 = min (i_imgHeight , partsOfImg(tmpPartIdx,4) + i_PartHeight/2 );

                %assign center of mass of region
                seedingBlocks( partIdx ).cx = partsOfImg(tmpPartIdx,3) ;
                seedingBlocks( partIdx ).cy = partsOfImg(tmpPartIdx,4) ;                
                % add label information of the corresponding image
                seedingBlocks( partIdx ).label = dataset.labels( dataset.trainImages(i) );

                seedingBlocks( partIdx ).imgIdx = dataset.trainImages(i); % equals: dataset.map_fnToIdx( dataset.images{ dataset.trainImages(i) } ) ;

                seedingBlockLabels( partIdx ) = dataset.labels( dataset.trainImages(i) );
            end

        end    
      
              
        if ( b_verbose )
            
            bbFig=figure;
            imshow(imgOrig)
            % maximize image
%             scrsz = get(0,'ScreenSize');
%             set(bbFig, 'Position', scrsz );
            hold on   
            myBB = [   [seedingBlocks(  ((i-1)*i_maxNoPartsPerImage + 1) : (i*i_maxNoPartsPerImage) ).x1 ]; ...
                        [seedingBlocks(  ((i-1)*i_maxNoPartsPerImage + 1) : (i*i_maxNoPartsPerImage) ).y1 ]; ...
                        [seedingBlocks(  ((i-1)*i_maxNoPartsPerImage + 1) : (i*i_maxNoPartsPerImage) ).x2 ]; ...
                        [seedingBlocks(  ((i-1)*i_maxNoPartsPerImage + 1) : (i*i_maxNoPartsPerImage) ).y2 ] ...
                    ];
            showboxes(imgOrig, myBB');
            hold off         
            
            if ( b_saveSeedingImage )
                s_filename = sprintf('%sseedingResult_GTparts_Img_%07d.png',s_seedingImageDestination, dataset.trainImages(i) );
                set(bbFig,'PaperPositionMode','auto')
                print(bbFig, '-dpng', s_filename);
            end              

            if ( b_waitForInput )
                pause
            end
            close(bbFig);
        end      
            
     
    end
  
    seedingBlocks = seedingBlocks(usedBlocks);
    seedingBlockLabels = seedingBlockLabels(usedBlocks);

end
