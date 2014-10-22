function demo4_nnMatching
% BRIEF:
%   A small demo visualizing the kNN matching on CUB200 2011.
% 
% author: Alexander Freytag
% date  : 06-05-2014 ( dd-mm-yyyy )   

    % load the settings we usually use throughout the experiments (thresholds,
    % acceptable sizes, ... )
    load ( 'demos/settings/settings.mat', 'settingsHOGandColorNames' );


  
    %renaming for easy re-usage of code
    settings = settingsHOGandColorNames;

       %% load settings and stuff like that
    
    % ------ settings for feature extraction and visualization ------
    settings.settingsVisual     = getFieldWithDefault ( settings, 'settingsVisual', [] );
    
%  settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
%        struct('name','Compute HOG features using WHO code', 'mfunction',@computeHOGs_WHO) );
%    settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
%        struct('name','Compute patch means', 'mfunction',@computePatchMeans) ); 
%    settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
%        struct('name','HOG and Patch Means concatenated', 'mfunction',@computeHOGandPatchMeans) );   
   settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
       struct('name','Color Names', 'mfunction',@computeColorNames) );       
%    settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
%        struct('name','HOG and Color Names', 'mfunction',@computeHOGandColorNames) );       
   
   % depending on the feature type chosen, set the visualization technique
   % accordingly   
   settingsFeatVis = getFieldWithDefault ( settings, 'settingsFeatVis', [] );
    if ( strcmp( settings.fh_featureExtractor.name , 'Compute HOG features using WHO code' )  )
       settings.settingsVisual.fh_featureVisualization = ...
            getFieldWithDefault ( settings, 'fh_featureVisualization', ...
            struct('name','Show HOG weights', 'mfunction',@showWeightVectorHOG, 'settings', settingsFeatVis ) );
    elseif ( strcmp( settings.fh_featureExtractor.name , 'Compute patch means' )  )
       settings.settingsVisual.fh_featureVisualization = ...
            getFieldWithDefault ( settings, 'fh_featureVisualization', ...
            struct('name','Show patch mean weights', 'mfunction',@showWeightVectorPatchMeans, 'settings', settingsFeatVis ) );        
    elseif ( strcmp( settings.fh_featureExtractor.name , 'HOG and Patch Means concatenated' )  )
       settings.settingsVisual.fh_featureVisualization = ...
            getFieldWithDefault ( settings, 'fh_featureVisualization', ...
            struct('name','Show HOG and patch mean weights', 'mfunction',@showWeightVectorHOGandPatchMeans, 'settings', settingsFeatVis ) );         
    elseif ( strcmp( settings.fh_featureExtractor.name , 'Color Names' )  )
       settings.settingsVisual.fh_featureVisualization = ...
            getFieldWithDefault ( settings, 'fh_featureVisualization', ...
            struct('name','Show color name weights', 'mfunction',@showWeightVectorColorNames, 'settings', settingsFeatVis ) );                 
    elseif ( strcmp( settings.fh_featureExtractor.name , 'HOG and Color Names' )  )
       settings.settingsVisual.fh_featureVisualization = ...
            getFieldWithDefault ( settings, 'fh_featureVisualization', ...
            struct('name','Show HOG and color name weights', 'mfunction',@showWeightVectorHOGandColorNames, 'settings', settingsFeatVis ) );          
    else
       settings.settingsVisual.fh_featureVisualization = ...
            getFieldWithDefault ( settings, 'fh_featureVisualization', [] );          
    end   
   
    
   % ------ settings for model representation, i.e., lda etc. ------
    settings.lda    = getFieldWithDefault ( settings, 'lda', [] );
    
    settings.lda.bg = getFieldWithDefault ( settings.lda, 'bg', [] );
    if ( isempty(settings.lda.bg) )
        persistent bgCUB200;
        if ( isempty( bgCUB200 ) )
            bgCUB200 = load ( 'bgCUB200_2011_meanPatchesRGB.mat' );
        end
        settings.lda.bg = bgCUB200.bgMeanPatchesRGB;        
    end
         
    % ----- visualization options to show discovery results  ----
    settingsEval            = getFieldWithDefault ( settings, 'settingsEval', [] );
    i_stepSizeProgressBar   = getFieldWithDefault ( settingsEval, 'i_stepSizeProgressBar',   2 );

    % ----- settings for the kNN matching (query computations) ----
    settingsMatching        = getFieldWithDefault ( settings, 'settingsMatching', [] );
    % work on 20 most similar training images to perform patch discovery
    i_kNearestNeighbors     = getFieldWithDefault ( settingsMatching, 'i_kNearestNeighbors', 20 );   
    settingsMatching.i_kNearestNeighbors = i_kNearestNeighbors;
    %TODO less dependent on feature extraction for patch detection
    %please...
    settingsMatching.settingsFeat.fh_featureExtractor = settings.fh_featureExtractor;    

    %% load matches between test image and training images based on global features (hog in our case)    
    
    global birdNNMatching;
    
    if ( isempty( birdNNMatching ) )
        try 
            load ( getFieldWithDefault ( settingsMatching, 's_nnMatchingFile', ...
                                '/home/freytag/experiments/2014-03-13-nnMatchingCUB200/200/nnMatchingCUB200.mat') , ...
                                    'birdNNMatching'...
                                  );
        catch err
            disp ( '*** No cached matching loadable - perform NN matching on the fly. *** ')
        end
    end
    
    nnMatching  = birdNNMatching.idxSorted;    
    nrClasses   = birdNNMatching.nrClasses;    
    
            
    %     
    global datasetCUB200;    
    if ( isempty ( datasetCUB200 ) )
        settingsInitCUB.i_numClasses = nrClasses;
        datasetCUB200 = initCUB200_2011 ( settingsInitCUB ) ;
    end      
    
    if ( isempty ( datasetCUB200 ) )
        disp(' *** WARNING: NO DATASET SPECIFIED, AND NOT CACHE FOUND. ABORTING! ***')
        return
    end
       
    %% operate on every test image...
    %NOTE for rapid computations, a parfor might be an option here...
        
    i_startForLoop     = getFieldWithDefault ( settingsEval, 'i_startForLoop',   1);
    i_endForLoop       = getFieldWithDefault ( settingsEval, 'i_endForLoop', size ( datasetCUB200.testImages , 2 ) );
    
    
    myRandIdx = round(rand(1,size(datasetCUB200.testImages,2))*size(datasetCUB200.testImages,2));
    
    for i = i_startForLoop : i_endForLoop
        
        if( rem(i-1,i_stepSizeProgressBar)==0 )
            fprintf('%04d / %04d\n', i, i_endForLoop );
        end          
        
        % get the training images that matches with the current query
        if ( exist( 'nnMatching', 'var' ) )
            relevantIdx = nnMatching ( 1:i_kNearestNeighbors, myRandIdx(i) );        
        else
            relevantIdx = doNNQuery ( datasetCUB200.images ( datasetCUB200.trainImages), ... %training images
                                      datasetCUB200.images{ datasetCUB200.testImages(myRandIdx(i)) }, ... % test image (query)
                                      settingsMatching ); % settings
        end   
        
        % check which of them had flipped versions as responses
        relevantIdxFlipped = unique ( relevantIdx( relevantIdx >  length(datasetCUB200.trainImages) ) );
        relevantIdx        = unique ( relevantIdx( relevantIdx <= length(datasetCUB200.trainImages) ) );
        
        
        relevantImages        = datasetCUB200.images ( datasetCUB200.trainImages( relevantIdx ) );
        relevantImagesFlipped = datasetCUB200.images ( datasetCUB200.trainImages( relevantIdxFlipped-length(datasetCUB200.trainImages) ) );
        imgFolderNonFlipped   = '_256x256/';
        imgFolderFlipped      = '_256x256_flipped/';
        relevantImagesFlipped = strrep(relevantImagesFlipped,  imgFolderNonFlipped, imgFolderFlipped);
        
        relevantImages = [relevantImages; relevantImagesFlipped];
        
        % okay, let's bring the images into 'correct' order, i.e., not
        % first all non-flipped, than all flipped, but rather sorted by
        % name/categorie/origIndex
        idxMerged = [relevantIdx;relevantIdxFlipped-length(datasetCUB200.trainImages)];
        [~,idxSort] = sort ( idxMerged, 'ascend' );
        relevantImages = relevantImages ( idxSort );
        
        yRelevant = datasetCUB200.labels( datasetCUB200.trainImages( idxMerged(idxSort) ) );
        dataset = [];
        dataset.images      = relevantImages;
        dataset.trainImages = 1:i_kNearestNeighbors;         
        dataset.labels      = yRelevant;
        
            % moderately dirty hack: we know where the flipped images are
            % located, so use them if matching tells so

     
            settingsVisDataset  = [];
            figTrainImg         = showDataset ( dataset, settingsVisDataset ) ;

            % show single test image
            figTestImg =figure;
            imshow ( datasetCUB200.images{ datasetCUB200.testImages(myRandIdx(i)) } );

            pause
            close ( figTestImg  );
            close ( figTrainImg );
    end

end