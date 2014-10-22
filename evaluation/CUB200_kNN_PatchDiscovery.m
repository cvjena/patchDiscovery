function out = CUB200_kNN_PatchDiscovery ( settings ) 

    
    if ( nargin < 1 ) 
        settings = [];
    end
    
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
             getFieldWithDefault ( settings.settingsExpansionSelection, 'b_removeDublicates', true ); 
         
    settings.settingsExpansionSelection.d_thrRedundant = ...
             getFieldWithDefault ( settings.settingsExpansionSelection, 'd_thrRedundant', 0.95 );     
         
    settings.settingsExpansionSelection.i_noIterations = ...
             getFieldWithDefault ( settings.settingsExpansionSelection, 'i_noIterations', 10 );     
    
    %add at most 3 new blocks per iteration
    settings.settingsExpansionSelection.i_K = ...
             getFieldWithDefault ( settings.settingsExpansionSelection, 'i_K', 3 );     
     
    % ------ settings for final selection step ------
    settings.settingsFinalSelection  = ...
             getFieldWithDefault ( settings, 'settingsFinalSelection', [] );        
    settings.settingsFinalSelection.b_removeUnrepresentativePatches = ...
             getFieldWithDefault ( settings.settingsFinalSelection, 'b_removeUnrepresentativePatches', true );          
     
 

         
    % ----- visualization options to show discovery results  ----
    settingsEval            = getFieldWithDefault ( settings, 'settingsEval', [] );
    b_showDiscoveredPatches = getFieldWithDefault ( settingsEval, 'b_showDiscoveredPatches', false );
    b_showRespOnTrainImg    = getFieldWithDefault ( settingsEval, 'b_showRespOnTrainImg',    false );
    b_showRespOnTestImg     = getFieldWithDefault ( settingsEval, 'b_showRespOnTestImg',     false );
    b_showHeatmapsTrain     = getFieldWithDefault ( settingsEval, 'b_showHeatmapsTrain',     false );
    b_showHeatmapsTest      = getFieldWithDefault ( settingsEval, 'b_showHeatmapsTest',      true  );
    b_verbose               = getFieldWithDefault ( settingsEval, 'b_verbose',               true  );
    b_debug                 = getFieldWithDefault ( settingsEval, 'b_debug',                 false );
    b_showMatching          = getFieldWithDefault ( settingsEval, 'b_showMatching',          false );
    i_stepSizeProgressBar   = getFieldWithDefault ( settingsEval, 'i_stepSizeProgressBar',   2 );
    
    % ----- caching options for patches and patch responses ----
    settingsCache           = getFieldWithDefault ( settings, 'settingsCache', [] );
    b_cachePatches          = getFieldWithDefault ( settingsCache, 'b_cachePatches',          false );
    b_cacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 'b_cacheBOPFeaturesTrain', false );
    b_cacheBOPFeaturesTest  = getFieldWithDefault ( settingsCache, 'b_cacheBOPFeaturesTest',  false );    
    b_cacheScores           = getFieldWithDefault ( settingsCache, 'b_cacheScores',  false );
 
    % ----- settings for the kNN matching (query computations) ----
    settingsMatching        = getFieldWithDefault ( settings, 'settingsMatching', [] );
    % work on 20 most similar training images to perform patch discovery
    i_kNearestNeighbors     = getFieldWithDefault ( settingsMatching, 'i_kNearestNeighbors', 20 );   
    settingsMatching.i_kNearestNeighbors = i_kNearestNeighbors;
    %TODO less dependent on feature extraction for patch detection
    %please...
    settingsMatching.settingsFeat.fh_featureExtractor = settings.fh_featureExtractor;    
    
    % ----- settings for the final classification model  ----
    settingsClassification  = getFieldWithDefault ( settings, 'settingsClassification', [] );
    b_linearSVM             = getFieldWithDefault ( settingsClassification, 'b_linearSVM', true );
    
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
    
    i_numClasses       = size ( unique ( datasetCUB200.labels ),1 );
    
    i_startForLoop     = getFieldWithDefault ( settingsEval, 'i_startForLoop',   1);
    i_endForLoop       = getFieldWithDefault ( settingsEval, 'i_endForLoop', size ( datasetCUB200.testImages , 2 ) );
    
    
    % just for debugging: work on second image only...
    if ( b_debug ) 
        i_startForLoop = 1;
        i_endForLoop   = 4;    
    end    
    
%     scoresPatches  =  -inf*ones( (i_endForLoop-i_startForLoop) , i_numClasses );
    scoresPatches  =  -inf*ones( i_numClasses, (i_endForLoop-i_startForLoop+1) );
    labelsEst      =  zeros ( i_endForLoop-i_startForLoop+1, 1 );
    pdTime         =  zeros ( i_endForLoop-i_startForLoop+1, 1 );
    
    i_shift = (-i_startForLoop+1);
    
%     parfor i = i_startForLoop : i_endForLoop
    for idxTestImg = i_startForLoop : i_endForLoop

        if( rem(idxTestImg-1,i_stepSizeProgressBar)==0 )
            fprintf('%04d / %04d\n', idxTestImg, i_endForLoop );
        end        
        
        % get the training images that matches with the current query
        if ( exist( 'nnMatching', 'var' ) )
            relevantIdx = nnMatching ( 1:i_kNearestNeighbors, idxTestImg );        
        else
            relevantIdx = doNNQuery ( datasetCUB200.images ( datasetCUB200.trainImages), ... %training images
                                      datasetCUB200.images{ datasetCUB200.testImages(idxTestImg) }, ... % test image (query)
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
        
        if ( b_showMatching )
            % moderately dirty hack: we know where the flipped images are
            % located, so use them if matching tells so

     
            settingsVisDataset  = [];
            figTrainImg         = showDataset ( dataset, settingsVisDataset ) ;

            % show single test image
            figTestImg =figure;
            imshow ( datasetCUB200.images{ datasetCUB200.testImages(idxTestImg) } );

            pause
            close ( figTestImg  );
            close ( figTrainImg );
        end

        
        pdTic   = tic; % pd = patch discovery
        
        patches = findPatches ( dataset, settings ) ;
        
        pdToc   =toc (pdTic);
        
        pdTime ( idxTestImg+i_shift ) = pdToc;
        
        if ( b_verbose )            
            msgPdTime = sprintf( 'Time for patch discovery: %f', pdToc );
            disp ( msgPdTime )
        end

            
        if ( b_showDiscoveredPatches )
            disp ( 'Show patch discovery results')
            showResults ( patches , settings.settingsVisual ) ;
            pause;
        end
        
        if ( b_showRespOnTrainImg ) 
            disp ( 'Show patch responses on training images')
            settingsPatchResponses                     = [];
            settingsPatchResponses.d_maxRelBoxExtent   = 0.5;
            settingsPatchResponses.fh_featureExtractor = settings.fh_featureExtractor;            
            for idxTrImg = 1 : i_kNearestNeighbors
                showPatchResponses ( relevantImages{idxTrImg}, patches, settingsPatchResponses);
            end
            pause;
        end
        
        if ( b_showRespOnTestImg ) 
            disp ( 'Show patch responses on test image')
            settingsPatchResponses                     = [];
            settingsPatchResponses.d_maxRelBoxExtent   = 0.5;
            settingsPatchResponses.fh_featureExtractor = settings.fh_featureExtractor;            
            showPatchResponses ( datasetCUB200.images{ datasetCUB200.testImages(idxTestImg) }, patches, settingsPatchResponses);
            
            pause;  
        end
        
        if ( b_cachePatches ) 
            
            % remove computed feature vectors for every positive sample from
            % the struct in order to save memory
            %
            % the import aspects are still kept (model, bounding box, image
            % filename, ...)
            patches = removeFeatureFromPatchStructs ( patches );
            
            s_dirCachePatches = getFieldWithDefault ( settingsCache, 's_dirCachePatches', '/tmp/cache/patches/' );
            if ( ~exist(s_dirCachePatches, 'dir') )
                mkdir ( s_dirCachePatches );
            end

            % determine specific name of class and image to build a proper
            % cache title
            s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(idxTestImg) };
            idxSlash      = strfind( s_imgfn ,'/');   
            idxDot        = strfind ( s_imgfn, '.' );
            s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
            s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            
            
            s_destPatches = sprintf( '%simg_%05d_%s_%s.mat', s_dirCachePatches, idxTestImg , s_className, s_imgName );
            parsavePatches ( s_destPatches , patches );
        end
        
        
              
        
        
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
        % also store the position of best responses
        settingsBOP.b_storePos = true;
        bopFeaturesTrain = computeBoPFeatures (dataset, settingsBOP, patches);
        
        
        if ( b_showHeatmapsTrain )
            settingsHeatMapVis.b_closeImage    = true;
            settingsHeatMapVis.b_waitForInput  = true;
            settingsHeatMapVis.b_saveResults   = false;
            for idxTrImg=1:length(dataset.trainImages ) 
                computeHeatmapDetectionResponse ( dataset.images{dataset.trainImages(idxTrImg)}, bopFeaturesTrain, settingsHeatMapVis, [], idxTrImg );            
            end
        end
        
        if ( b_cacheBOPFeaturesTrain ) 
            s_dirCacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTrain', '/tmp/cache/bopTrain/' );
            if ( ~exist(s_dirCacheBOPFeaturesTrain, 'dir') )
                mkdir ( s_dirCacheBOPFeaturesTrain );
            end

            % determine specific name of class and image to build a proper
            % cache title
            s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(idxTestImg) };
            idxSlash      = strfind( s_imgfn ,'/');    
            idxDot        = strfind ( s_imgfn, '.' );
            s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
            s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            
            
            s_destBopTrain = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheBOPFeaturesTrain, idxTestImg , s_className, s_imgName );
            parsaveBOPFeaturesTrain ( s_destBopTrain , bopFeaturesTrain );
        end        
        
        % =============================
        % post-process features of training images
        % =============================
        settingsFeaturePostPro = getFieldWithDefault ( settings, 'settingsFeaturePostPro', [] );
        settingsFeaturePostPro = setupVariables_postprocessing  ( settingsFeaturePostPro );
        % map patch responses to desired interval              
        [ bopFeaturesTrain.bopFeaturesTrain, featMapping_additionalInfos] = ...
            settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTrain.bopFeaturesTrain, settingsFeaturePostPro.fh_bopFeatureMapping.settings );    
        
        % further normalization if desired, e.g., L1
        if ( ~isempty( settingsFeaturePostPro.fh_bopFeatureNormalization ) )
            bopFeaturesTrain.bopFeaturesTrain = settingsFeaturePostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTrain.bopFeaturesTrain,  settingsFeaturePostPro.fh_bopFeatureNormalization.settings);
        end        
      
        
        % embed features in higher dim. space
        bopFeaturesTrain.bopFeaturesTrain = ...
            encryptFeatures( settingsFeaturePostPro, bopFeaturesTrain.bopFeaturesTrain);        
        
        % =============================
        %       train classifier 
        % =============================
        labels   = dataset.labels;        
        
        if ( b_linearSVM )
            % use liblinear
            svmModel = liblinear_train ( labels, sparse(bopFeaturesTrain.bopFeaturesTrain), settingsClassification );
        else
            % use libsvm
            svmModel = libsvm_train ( labels, sparse(bopFeaturesTrain.bopFeaturesTrain), settingsClassification );
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
        datasetTest.images = datasetCUB200.images( datasetCUB200.testImages(idxTestImg) );
        datasetTest.testImages = 1;
        bopFeaturesTest = computeBoPFeatures (datasetTest, settingsBOP, patches); 
        
        if ( b_showHeatmapsTest )
            settingsHeatMapVis.b_closeImage    = true;
            settingsHeatMapVis.b_waitForInput  = true;
            settingsHeatMapVis.b_saveResults   = true;
            settingsHeatMapVis.s_dirResults    = sprintf('./heatmaps-k%03d/',i_kNearestNeighbors);
            computeHeatmapDetectionResponse ( datasetCUB200.images{ datasetCUB200.testImages(idxTestImg) }, bopFeaturesTest, settingsHeatMapVis );            
        end          
        
        if ( b_cacheBOPFeaturesTest ) 
            s_dirCacheBOPFeaturesTest = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTest', '/tmp/cache/bopTest/' );
            if ( ~exist(s_dirCacheBOPFeaturesTest, 'dir') )
                mkdir ( s_dirCacheBOPFeaturesTest );
            end

            % determine specific name of class and image to build a proper
            % cache title
            s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(idxTestImg) };
            idxSlash      = strfind(s_imgfn,'/');    
            idxDot        = strfind ( s_imgfn, '.' );
            s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
            s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            
            
            s_destBopTest = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheBOPFeaturesTest, idxTestImg , s_className, s_imgName );
            parsaveBOPFeaturesTest ( s_destBopTest , bopFeaturesTest );
        end
     
        
        % =============================
        % post-process features of query image
        % =============================
        % map patch responses to desired interval
        bopFeaturesTest.bopFeaturesTest = ...
            settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTest.bopFeaturesTest, featMapping_additionalInfos );    
        
        % further normalization if desired, e.g., L1
        if (  ~isempty( settingsFeaturePostPro.fh_bopFeatureNormalization ) )
            bopFeaturesTest.bopFeaturesTest = settingsFeaturePostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTest.bopFeaturesTest,  settingsFeaturePostPro.fh_bopFeatureMapping.settings);
        end      

        % embed features in higher dim. space
        bopFeaturesTest.bopFeaturesTest = ...   
            encryptFeatures( settingsFeaturePostPro, bopFeaturesTest.bopFeaturesTest);        
        
        % =============================
        % get ground truth class number of test image
        % =============================
        
        yTest = datasetCUB200.labels( datasetCUB200.testImages(idxTestImg) );        
        
        % =============================
        %     classify test image
        % =============================
        
        if ( b_linearSVM )
            % use liblinear
            [predicted_label, ~, scores] = liblinear_test( yTest, sparse(bopFeaturesTest.bopFeaturesTest), svmModel, settingsClassification );
        else
            % use libsvm
            [predicted_label, ~, scores] = libsvm_test( yTest, sparse(bopFeaturesTest.bopFeaturesTest), svmModel, settingsClassification );
        end        
        
        scoresBlownUp   =  -inf*ones( i_numClasses, 1 );
        scoresBlownUp ( unique(yRelevant) ) = scores;
        scoresPatches( :, idxTestImg+i_shift )  = scoresBlownUp;        
%         scoresPatches( unique(yRelevant), i-i_endForLoop) = scores;
        labelsEst ( idxTestImg+i_shift )                  = predicted_label;
        
        if ( b_cacheScores )
            s_dirCacheScores = getFieldWithDefault ( settingsCache, 's_dirCacheScores', '/tmp/cache/scores/' );
            if ( ~exist(s_dirCacheScores, 'dir') )
                mkdir ( s_dirCacheScores );
            end

            % determine specific name of class and image to build a proper
            % cache title
            s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(idxTestImg) };
            idxSlash      = strfind(s_imgfn,'/');    
            idxDot        = strfind ( s_imgfn, '.' );
            s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
            s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            
            
            s_destScores = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheScores, idxTestImg , s_className, s_imgName );
            parsaveScores ( s_destScores , scores );
        end
        
        
        % =============================
        % compare gt class against estimated class
        % =============================
        
        % note: evaluations are done at the very end in order to allow for
        %       parallelization        
        
        if ( b_verbose )
            msgResult = sprintf( 'GT: %3d, est: %3d', yTest, predicted_label );
            disp ( msgResult )
        end
                
    end
    
    scoresPatches = scoresPatches';
    
    pdTime = sum(pdTime) / double( i_endForLoop - i_startForLoop + 1);
    
    
    
    %% final evaluations...
    
    classLabels     = unique(datasetCUB200.labels );
    labelsTest      = datasetCUB200.labels(datasetCUB200.testImages);
    classAccuracies = zeros(length(classLabels) ,1);

    %check which samples are from which class
    for clCnt = 1:length(classLabels) 
        idxSampleOfClass = ( labelsTest == classLabels(clCnt) );
        
        % adapt index according to current szenario... ( only needed during
        % debugging or for explicitely specified start and end)
        idxSampleOfClass = idxSampleOfClass(i_startForLoop : i_endForLoop );
        
        idxSampleOfClass = find ( idxSampleOfClass );

        % count how often a sample of class i was classified correctly
        classAccuracies(clCnt) = sum(labelsEst(idxSampleOfClass)==labelsTest(idxSampleOfClass));
    end    
           
        
    numTestSamplesPerClass = accumarray (  datasetCUB200.labels( datasetCUB200.testImages) ,1 );
    classAccuracies        = classAccuracies ./ numTestSamplesPerClass;
    
    if ( nargout > 0 )
        out.meanAcc = mean( 100*classAccuracies );
        out.stdAcc  = std( 100*classAccuracies );  
        
        out.labelsEst  = labelsEst;
        out.labelsTest = labelsTest;
        
        out.classAccuracies = classAccuracies;
        out.numTestSamplesPerClass = numTestSamplesPerClass;

        out.meanPDTime      = pdTime;
        out.scoresPatches   = scoresPatches;
    end
    
    s_result = sprintf( 'Mean accuracy with %d neighbors: %f ', ...
               i_kNearestNeighbors, mean( 100*classAccuracies ) );
    disp ( s_result );    
    
end

%NOTE: several functions are only needed to have proper field names... 

% tiny save function needed to save within parfor-loops
function parsaveScores ( s_filename, scores )
    save ( s_filename, 'scores');
end
% tiny save function needed to save within parfor-loops
function parsaveBOPFeaturesTest ( s_filename, bopFeaturesTest )
    save ( s_filename, 'bopFeaturesTest');
end
% tiny save function needed to save within parfor-loops
function parsaveBOPFeaturesTrain ( s_filename, bopFeaturesTrain )
    save ( s_filename, 'bopFeaturesTrain');
end
% tiny save function needed to save within parfor-loops
function parsavePatches ( s_filename, patches )
    save ( s_filename, 'patches');
end
