function [matchingIdx,matchingDist] = doNNQuery ( imagesTrain, imageQuery, settings )

    
    settingsReadData = getFieldWithDefault ( settings, 'settingsReadData', [] );

    % read images, crop to bounding box, and resize result to fixed size
    settingsReadData = addDefaultVariableSetting ( settingsReadData, 'b_cropToBB', true, settingsReadData);
    settingsReadData = addDefaultVariableSetting ( settingsReadData, 'b_resizeImageToStandardSize', true, settingsReadData);
    settingsReadData = addDefaultVariableSetting ( settingsReadData, 'i_standardImageSize', [128 128], settingsReadData);
    % do no further foreground masking (gt, grabcut, ...)
    settingsReadData = addDefaultVariableSetting ( settingsReadData, 's_maskTechnique', 'none', settingsReadData);

    
    settingsFeat = getFieldWithDefault ( settings, 'settingsFeat', [] );
    settingsFeat.fh_featureExtractor = getFieldWithDefault ( settingsFeat, 'fh_featureExtractor', ...
       struct('name','Compute HOG features using WHO code', 'mfunction',@computeHOGs_WHO) );    
    
    settingsFeat = addDefaultVariableSetting ( settingsFeat, 'hog_cellsize', 16, settingsFeat );
    settingsFeat = addDefaultVariableSetting ( settingsFeat, 'i_binSize', 16, settingsFeat );

    
    s_distanceMeasure = getFieldWithDefault ( settings, 's_distanceMeasure', 'euclidean');
    
    s_destCacheMatching = getFieldWithDefault ( settings, 's_destCacheMatching', 'cacheMatching.mat' );
    
    
   
    if exist( s_destCacheMatching,'file')
        load( s_destCacheMatching, 'hog_train_both');
    else

        hog_train = [];
        hog_train_flipped = [];

        % loop through all training images
        for ii = length(imagesTrain):-1:1
            if mod(ii,100) == 0
                fprintf('HOG Calculation for all train images %d/%d\n',ii,length(imagesTrain));
            end
            image_name = imagesTrain{ii};

            im   = readImage( image_name, settingsReadData );
            mask = readMask( image_name, settingsReadData );
            mask(:,:,2) = mask(:,:,1);
            mask(:,:,3) = mask(:,:,1);
            % simple HOG masking
            im(mask==0)=0;

            hog = settingsFeat.fh_featureExtractor.mfunction( im, settingsFeat);
            hog_train(ii,:) = hog(:);

            im_flipped = flipdim(im,2);
            hog = settingsFeat.fh_featureExtractor.mfunction( im_flipped, settingsFeat);
            hog_train_flipped(ii,:) = hog(:);
        end
        
        hog_train_both = [hog_train; hog_train_flipped];

        save( s_destCacheMatching, 'hog_train_both', 'settings'); 
    end

    % now, compute features for query image
    image_name = imageQuery;

    im          = readImage( image_name, settingsReadData );
    mask        = readMask( image_name, settingsReadData );
    mask(:,:,2) = mask(:,:,1);
    mask(:,:,3) = mask(:,:,1);
    % simple HOG masking
    im(mask==0) = 0;

    hog = settingsFeat.fh_featureExtractor.mfunction( im, settingsFeat);
    hogQuery = hog(:);


    % perform nearest neighbour search based on HOG
    [d_distances]=pdist2(hog_train_both, hogQuery', s_distanceMeasure );
    
    % sort distances for every test sample
    [d_distancesSorted,matchingIdx]=sort(d_distances, 'ascend'); 
    
    i_kNearestNeighbors = getFieldWithDefault ( settings, 'i_kNearestNeighbors', size ( imagesTrain, 2) );
    
    matchingIdx = matchingIdx(1:i_kNearestNeighbors );
    if ( nargout > 2 )
        matchingDist = d_distancesSorted(1:i_kNearestNeighbors );
    end
end