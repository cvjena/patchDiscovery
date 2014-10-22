function nnResults = computeNNDistances(imagesTrain, imagesTest, settings)
% function nnResults = computeNNDistances(imagesTrain, imagesTest, settings)
% 
% author: Alexander Freytag
% date  : 03-04-2014 ( dd-mm-yyyy )
% 
% BRIEF:
%   Perform HOG-based NN matching between all test and all training samples.  
%   Similar to the version used in our CVPR'14 paper about non-parametric part transfer.
% 

    if ( isempty ( imagesTest ))
        b_trainSelfMatch = true;
    else
        b_trainSelfMatch = false;
    end

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
        if ( b_trainSelfMatch )
            load( s_destCacheMatching, 'hog_train_both' );
            hog_train = hog_train_both(1:size(hog_train_both,1)/2,:);
        else
            load( s_destCacheMatching, 'hog_train_both', 'hog_test');
        end
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


        if ( ~b_trainSelfMatch )
            hog_test = [];

            % loop through all test images
            for ii = length(imagesTest):-1:1
                %     parfor ii = length(imagesTest):-1:1
                if mod(ii,100) == 0
                    fprintf('HOG Calculation for all test images %d/%d\n',ii,length(imagesTest));
                end
                image_name = imagesTest{ii};

                im   = readImage( image_name, settingsReadData );
                mask = readMask( image_name, settingsReadData );
                mask(:,:,2) = mask(:,:,1);
                mask(:,:,3) = mask(:,:,1);
                % simple HOG masking
                im(mask==0)=0;

                hog = settingsFeat.fh_featureExtractor.mfunction( im, settingsFeat);
                hog_test(ii,:) = hog(:);
            end
        end       

        if ( b_trainSelfMatch )
            save( s_destCacheMatching, 'hog_train_both', 'settings');
        else
            save( s_destCacheMatching, 'hog_train_both', 'hog_test', 'settings');
        end

    end
    

    % perform nearest neighbour search based on HOG
    if ( b_trainSelfMatch )
        [d_distances]=pdist2( hog_train_both, hog_train, s_distanceMeasure );
    else
        [d_distances]=pdist2( hog_train_both, hog_test,  s_distanceMeasure );
    end
    
    % sort distances for every test sample
    [distScores,idxSorted]=sort(d_distances);
    
    if ( b_trainSelfMatch  &&  getFieldWithDefault ( settings, 'b_undoIdMatching', false ) )

        myTmp = repmat(1:size(idxSorted,2),[size(idxSorted,1),1]);
        selfMatchIdx=(myTmp==idxSorted);
        
        myMirrorTmp = repmat(size(idxSorted,2)+1:2*size(idxSorted,2),[size(idxSorted,1),1]);
        selfMatchMirrorIdx=(myMirrorTmp==idxSorted);     
        
        myIdxReordered = reshape( idxSorted(~selfMatchIdx & ~selfMatchMirrorIdx), [size(idxSorted,1)-2,size(idxSorted,2)] );
        myIdxReordered = [myIdxReordered; idxSorted(selfMatchMirrorIdx)'];
        myIdxReordered = [myIdxReordered; idxSorted(selfMatchIdx)'];        
        
        idxSorted      = myIdxReordered;
        
        myScoReordered = reshape( distScores(~selfMatchIdx & ~selfMatchMirrorIdx), [size(distScores,1)-2,size(distScores,2)] );
        
        scoresMax      = max( distScores, [] , 1);
        
        myScoReordered = [myScoReordered; scoresMax+1001];
        myScoReordered = [myScoReordered; scoresMax+1002];     
        
        distScores     = myScoReordered;
    end
    
    
    nnResults.distScores = distScores;
    nnResults.idxSorted  = idxSorted;   
    
end