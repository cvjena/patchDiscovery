function out = CUB200_kNN_oracle ( settings ) 

    
    if ( nargin < 1 ) 
        settings = [];
    end
    

    
    %% load matches between test image and training images based on global features (hog in our case)    
    
    global birdNNMatching;
    if ( isempty( birdNNMatching ) )
        birdNNMatching = load ( getFieldWithDefault ( settings, 's_nnMatchingFile', ...
                                '/home/freytag/experiments/2014-03-13-nnMatchingCUB200/200/nnMatchingCUB200.mat') ...
                              );
        birdNNMatching = birdNNMatching.nnResults;
        nrClasses   = birdNNMatching.nrClasses;
    end
    
    nnMatching  = birdNNMatching.idxSorted;
    
%     
    global datasetCUB200;
    if ( isempty ( datasetCUB200 ) )
        settingsInitCUB.i_numClasses = nrClasses;
        datasetCUB200 = initCUB200_2011 ( settingsInitCUB ) ;
    end
    
    % work on 20 most similar training images to perform patch discovery
    i_kNearestNeighbors = getFieldWithDefault ( settings, 'i_kNearestNeighbors', 20 );

    
    b_showMatching = getFieldWithDefault ( settings, 'b_showMatching', false );
    
    % if true, oracle scores if at least a single among kNN results is
    % correct
    % if false, 'oracle' scores only if most frequ. class number is correct
    b_perfectOracle = getFieldWithDefault ( settings, 'b_perfectOracle', true );
    
    % if true, we additionally evaluate number of classes among kNNs
    b_computeClassDistributions = getFieldWithDefault ( settings, 'b_computeClassDistributions', false );
    if ( b_computeClassDistributions )
        numClasses = zeros ( size ( nnMatching , 2 ) , 1 );
    end
    
    % loop over all test images
    classAccuracies = zeros ( size ( unique ( datasetCUB200.labels ),1 ) , 1);
    
    %NOTE for rapid computations, a parfor might be an option here...
    for i = 1 : size ( nnMatching , 2 )    
        
        % get the training images that matches with the current query
        relevantIdx = nnMatching ( 1:i_kNearestNeighbors, i );        
        

        % check which of them had flipped versions as responses
        relevantIdxFlipped = unique ( relevantIdx( relevantIdx >  length(datasetCUB200.trainImages) ) );
        relevantIdx        = unique ( relevantIdx( relevantIdx <= length(datasetCUB200.trainImages) ) );
        
        
        relevantImages = datasetCUB200.images ( datasetCUB200.trainImages( relevantIdx ) );
        relevantImagesFlipped = datasetCUB200.images ( datasetCUB200.trainImages( relevantIdxFlipped-length(datasetCUB200.trainImages) ) );
        imgFolderNonFlipped = '/users/tmp/freytag/data/finegrained/cub200_2011/cropped_256x256/images/';
        imgFolderFlipped    = '/home/freytag/data/finegrained/cub200_2011/cropped_256x256_flipped/images/';
        relevantImagesFlipped = strrep(relevantImagesFlipped,  imgFolderNonFlipped, imgFolderFlipped);
        
        relevantImages = [relevantImages; relevantImagesFlipped];
        
        % okay, let's bring the images into 'correct' order, i.e., not
        % first all non-flipped, than all flipped, but rather sorted by
        % name/categorie/origIndex
        idxMerged = [relevantIdx;relevantIdxFlipped-length(datasetCUB200.trainImages)];
        [~,idxSort] = sort ( idxMerged, 'ascend' );
        relevantImages = relevantImages ( idxSort );
        
        yRelevant = datasetCUB200.labels( datasetCUB200.trainImages( idxMerged(idxSort) ) );
        
        
        if ( b_showMatching )
            % moderately dirty hack: we know where the flipped images are
            % located, so use them if matching tells so

            dataset.images      = relevantImages;
            dataset.trainImages = 1:i_kNearestNeighbors;      
            settingsVisDataset  = [];
            figTrainImg         = showDataset ( dataset, settingsVisDataset ) ;

            % show single test image
            figTestImg =figure;
            imshow ( datasetCUB200.images{ datasetCUB200.testImages(i) } );

            pause
            close ( figTestImg  );
            close ( figTrainImg );
        end
        
        % =============================
        % compare gt class against gt classes of training images
        % =============================
        
        yTest = datasetCUB200.labels( datasetCUB200.testImages(i) );
        
        if ( b_perfectOracle )
            oracleSucc = ( sum(yRelevant == yTest) > 0 );
        else
            oracleSucc = ( mode(yRelevant) == yTest );
        end
        if ( oracleSucc )
            classAccuracies ( yTest ) = classAccuracies ( yTest ) + 1;
        end       
        
        %
        % optionally, chech how many classes are present among kNNs
        %
        if ( b_computeClassDistributions )
            numClasses ( i ) = size ( unique ( yRelevant ), 1 );
        end
                
    end
    
    numTestSamplesPerClass = accumarray (  datasetCUB200.labels( datasetCUB200.testImages) ,1 );
    classAccuracies = classAccuracies ./ numTestSamplesPerClass;
    out.meanAcc = mean( 100*classAccuracies );
    out.stdAcc  = std( 100*classAccuracies );
    
    s_result = sprintf( 'Mean accuracy with %d neighbors: %f ', i_kNearestNeighbors, out.meanAcc );
    disp ( s_result );
    
    if ( b_computeClassDistributions )
        out.meanNumClasses = mean ( numClasses );
        out.stdNumClasses  = std  ( numClasses );
    end
    
end
