function demo5_nnMatchingAndClassification
% BRIEF:
%   A small demo visualizing the kNN matching on CUB200 2011, patch discovery, 
%   model training, and classification.
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
%     settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
%         struct('name','Color Names', 'mfunction',@computeColorNames) );       
  settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
      struct('name','HOG and Color Names', 'mfunction',@computeHOGandColorNames) );       
   
   % depending on the feature type chosen, set the visualization technique
   % accordingly   
    settingsFeatVis = getFieldWithDefault ( settings, 'settingsFeatVis', [] );
    % just to specify how models are visualized
    settingsFeatVis.b_hardAssignment = false;   
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
    
    settings.lda.b_noiseDropOut = getFieldWithDefault ( settings.lda, 'b_noiseDropOut', false );
    settings.lda.lambda         = getFieldWithDefault ( settings.lda, 'lambda', 0.01 );
    
    
    % ------ settings for seeding step ------
    settings.settingsSeeding           = ...
             getFieldWithDefault ( settings, 'settingsSeeding', [] );
    settings.settingsSeeding.b_verbose = ...
             getFieldWithDefault ( settings.settingsSeeding, 'b_verbose', false );
    settings.settingsSeeding.b_debug   = ...
        getFieldWithDefault ( settings.settingsSeeding, 'b_debug', false );

    settings.fh_doSeeding = getFieldWithDefault ( settings, 'fh_doSeeding', ...
        struct('name','do seeding using unsupervised segmentation results', 'mfunction',@doSeeding_regionBased) );           
%     settings.fh_doSeeding = getFieldWithDefault ( settings, 'fh_doSeeding', ...
%         struct('name','do seeding using manual (interactive) annotations', 'mfunction',@doSeeding_Manually) );           

    settings.settingsSeeding.b_removeDublicates = ...
             getFieldWithDefault ( settings.settingsSeeding, 'b_removeDublicates', false );
    settings.settingsSeeding.d_thrRedundant     = ...
             getFieldWithDefault ( settings.settingsSeeding, 'd_thrRedundant', 0.95 );

    
    % ------ settings for expansion step ------
    settings.settingsExpansionSelection  = ...
             getFieldWithDefault ( settings, 'settingsExpansionSelection', [] );    
         
    settings.settingsExpansionSelection.b_removeDublicates = ...
             getFieldWithDefault ( settings.settingsExpansionSelection, 'b_removeDublicates', false ); 
         
    settings.settingsExpansionSelection.d_thrRedundant = ...
             getFieldWithDefault ( settings.settingsExpansionSelection, 'd_thrRedundant', 0.95 );     
         
    settings.settingsExpansionSelection.i_noIterations = ...
             getFieldWithDefault ( settings.settingsExpansionSelection, 'i_noIterations', 10 );     
    
    %add at most 3 new blocks per iteration
    settings.settingsExpansionSelection.i_K = ...
             getFieldWithDefault ( settings.settingsExpansionSelection, 'i_K', 3 );     
         
    % only run bootstrapping on images of same category
    % 1) faster
    % 2) higher accuracy
    settings.settingsExpansionSelection.b_supervisedBootstrapping = true;  
    
    % -> Bootstrap on seeding blocks only? Then uncomment the following
    %    line.
    %settings.settingsExpansionSelection.b_expansionByConvolution = false;
    
     
    % ------ settings for final selection step ------
    settings.settingsFinalSelection  = ...
             getFieldWithDefault ( settings, 'settingsFinalSelection', [] );        
    settings.settingsFinalSelection.b_removeUnrepresentativePatches = ...
             getFieldWithDefault ( settings.settingsFinalSelection, 'b_removeUnrepresentativePatches', true );          
         
         
    % ----- visualization options to show discovery results  ----
    settingsEval            = getFieldWithDefault ( settings, 'settingsEval', [] );
    i_stepSizeProgressBar   = getFieldWithDefault ( settingsEval, 'i_stepSizeProgressBar',   2 );

    % ----- settings for the kNN matching (query computations) ----
    settingsMatching        = getFieldWithDefault ( settings, 'settingsMatching', [] );
    % work on 20 most similar training images to perform patch discovery
    i_kNearestNeighbors     = getFieldWithDefault ( settingsMatching, 'i_kNearestNeighbors', 20 );   
    %
    % hard coded to be faster
    i_kNearestNeighbors = 10;
    settingsMatching.i_kNearestNeighbors = i_kNearestNeighbors;
    %TODO less dependent on feature extraction for patch detection
    %please...
    settingsMatching.settingsFeat.fh_featureExtractor = settings.fh_featureExtractor;    
    
    % ----- settings for the final classification model  ----
    settingsClassification  = getFieldWithDefault ( settings, 'settingsClassification', [] );
    b_linearSVM             = getFieldWithDefault ( settingsClassification, 'b_linearSVM', true );    
    
    % enable a bit of output
    settings.b_verbose = true;

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
    
    
    for i = i_startForLoop : i_endForLoop
        
        if( rem(i-1,i_stepSizeProgressBar)==0 )
            fprintf('%04d / %04d\n', i, i_endForLoop );
        end          
        
        % get the training images that matches with the current query
        if ( exist( 'nnMatching', 'var' ) )
            relevantIdx = nnMatching ( 1:i_kNearestNeighbors, i );        
        else
            relevantIdx = doNNQuery ( datasetCUB200.images ( datasetCUB200.trainImages), ... %training images
                                      datasetCUB200.images{ datasetCUB200.testImages(i) }, ... % test image (query)
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
            imshow ( datasetCUB200.images{ datasetCUB200.testImages(i) } );

            pause
            close ( figTestImg  );
            close ( figTrainImg );        
        
        %% patch discovery
        patches = findPatches ( dataset, settings ) ;
        
        % uncomment the following line if you are interested in a visualization of discovered patches
        % showResults ( patches, settings )
        
        % =============================
        %    encrypt training images
        % =============================
        settingsBOP = [];
        settingsBOP.b_computeFeaturesTrain = true;
        settingsBOP.b_computeFeaturesTest  = false;
        % caching of BOP features is done outside, since we are only
        % interested in the results, and not in the surrounding settings
        % (which would be saved as well in the script)
        settingsBOP.b_saveFeatures = false;
        %todo check whether we need some settings for the convolutions...
        settingsBOP.fh_featureExtractor = settings.fh_featureExtractor;
        % working? 
        settingsBOP.d_maxRelBoxExtent   = 0.5;
        bopFeaturesTrain = computeBoPFeatures (dataset, settingsBOP, patches);
        bopFeaturesTrain = bopFeaturesTrain.bopFeaturesTrain;
        
        % =============================
        % post-process features of training images
        % =============================
        settingsFeaturePostPro = getFieldWithDefault ( settings, 'settingsFeaturePostPro', [] );
        settingsFeaturePostPro = setupVariables_postprocessing  ( settingsFeaturePostPro );
        % map patch responses to desired interval              
        [ bopFeaturesTrain, featMapping_additionalInfos] = ...
            settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTrain, settingsFeaturePostPro.fh_bopFeatureMapping.settings );    
        
        % further normalization if desired, e.g., L1
        if ( ~isempty( settingsFeaturePostPro.fh_bopFeatureNormalization ) )
            bopFeaturesTrain = settingsFeaturePostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTrain,  settingsFeaturePostPro.fh_bopFeatureNormalization.settings);
        end        
      
        
        % embed features in higher dim. space
        bopFeaturesTrain = ...
            encryptFeatures( settingsFeaturePostPro, bopFeaturesTrain);        
        
        % =============================
        %       train classifier 
        % =============================
        labels   = dataset.labels;        
        
        if ( b_linearSVM )
            % use liblinear
            svmModel = liblinear_train ( labels, sparse(bopFeaturesTrain), settingsClassification );
        else
            % use libsvm
            svmModel = libsvm_train ( labels, sparse(bopFeaturesTrain), settingsClassification );
        end
        
        % not needed anymore
        bopFeaturesTrain = [];   
        
        % =============================
        %      encrypt query image
        % =============================
        settingsBOP.b_computeFeaturesTrain = false;
        settingsBOP.b_computeFeaturesTest  = true;

        % NOTE!
        % Using GT segmentations on test images is a assumption too
        % strong for praxis. Therefore, we ignore it here. Check that your
        % remaining results are consistent here...
        settingsBOP.b_maskImages = false;


        datasetTest = [];
        datasetTest.images = datasetCUB200.images( datasetCUB200.testImages(i) );
        datasetTest.testImages = 1;
        bopFeaturesTest = computeBoPFeatures (datasetTest, settingsBOP, patches); 
        bopFeaturesTest = bopFeaturesTest.bopFeaturesTest;        
        
       % =============================
        % post-process features of query image
        % =============================
        % map patch responses to desired interval
        bopFeaturesTest = ...
            settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTest, featMapping_additionalInfos );    
        
        % further normalization if desired, e.g., L1
        if (  ~isempty( settingsFeaturePostPro.fh_bopFeatureNormalization ) )
            bopFeaturesTest = settingsFeaturePostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTest,  settingsFeaturePostPro.fh_bopFeatureMapping.settings);
        end      

        % embed features in higher dim. space
        bopFeaturesTest = ...   
            encryptFeatures( settingsFeaturePostPro, bopFeaturesTest);        
        
        % =============================
        % get ground truth class number of test image
        % =============================
        
        yTest = datasetCUB200.labels( datasetCUB200.testImages(i) );        
        
        % =============================
        %     classify test image
        % =============================
        
        if ( b_linearSVM )
            % use liblinear
            [predicted_label, ~, scores] = liblinear_test( yTest, sparse(bopFeaturesTest), svmModel, settingsClassification );
        else
            % use libsvm
            [predicted_label, ~, scores] = libsvm_test( yTest, sparse(bopFeaturesTest), svmModel, settingsClassification );
        end        
        
        msgResult = sprintf( 'GT: %3d, est: %3d', yTest, predicted_label );
        disp ( msgResult )        
        

    end

end