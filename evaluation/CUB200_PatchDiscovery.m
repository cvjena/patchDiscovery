function out = CUB200_PatchDiscovery ( settings, patchesPreComp ) 
%
% BRIEF
%   Run patch discovery on all training images of the CUB 200 dataset (or
%   subset), encrypt the images with the learnt representations, train a
%   multi-class-SVM, and apply it to test images.
% 
% NOTE in contrast to CUB200_kNN_PatchDiscovery.m, we run the patch
%   discovery an ALL training images, and use the resulting patches as
%   universal representation for ALL test images
% 
% INPUT
%  settings      -- huge struct with several settings for patch discovery
%                   (seeding, bootstrapping, selection, low-level feature 
%                   extraction, ...), matching, caching, ...
%  patchesPreComp-- (optional), precomputed patches (useful if discovery
%                    was split on multiple runs and results were manually
%                    combined
% 
% OUTPUT:
%   out          -- struct with fields 'meanAcc', 'stdAcc',
%                   'classAccuracies', 'numTestSamplesPerClass', 
%                   'meanPDTime', 'scoresPatches'
%
% date: 28-04-2014 ( dd-mm-yyyy )
% author: Alexander Freytag

    
    if ( nargin < 1 ) 
        settings = [];
    end
    
    if ( nargin < 2 )
        patchesPreComp = [];
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
%    settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
%        struct('name','Color Names', 'mfunction',@computeColorNames) );       
   settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
       struct('name','HOG and Color Names', 'mfunction',@computeHOGandColorNames) );       
   
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
    
    % ----- caching options for patches and patch responses ----
    settingsCache           = getFieldWithDefault ( settings, 'settingsCache', [] );
    b_cachePatches          = getFieldWithDefault ( settingsCache, 'b_cachePatches',          false );
    b_cacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 'b_cacheBOPFeaturesTrain', false );
    b_cacheBOPFeaturesTest  = getFieldWithDefault ( settingsCache, 'b_cacheBOPFeaturesTest',  false );    
    b_cacheScores           = getFieldWithDefault ( settingsCache, 'b_cacheScores',  false );
 
    % ----- settings for the final classification model  ----
    settingsClassification  = getFieldWithDefault ( settings, 'settingsClassification', [] );
    b_linearSVM             = getFieldWithDefault ( settingsClassification, 'b_linearSVM', true );    
    
    % ----- dataset settings ----
    settingsDataset         = getFieldWithDefault ( settings, 'settingsDataset', [] );
    settingsDataset         = addDefaultVariableSetting ( settingsDataset, 'i_numClasses', 14, settingsDataset);
    
    % ----- execution settings ----
    b_onlyDiscovery = getFieldWithDefault ( settings, 'b_onlyDiscovery', false ) ;

    %% get the dataset
    global datasetCUB200;
    
    if ( isempty( datasetCUB200 ) )
        datasetCUB200 = initCUB200_2011 ( settingsDataset ) ;
    end
    
    if ( isempty ( datasetCUB200 ) )
        disp(' *** WARNING: NO DATASET SPECIFIED, AND NO CACHE FOUND. ABORTING! ***')
        return
    end
    
    
    %% Patch Discovery on ALL training images 
    s_dirCachePatches = getFieldWithDefault ( settingsCache, 's_dirCachePatches', '/tmp/cache/patches/' );
    s_destPatches     = sprintf( '%sunivPatches.mat', s_dirCachePatches );
    
    pdTic   = tic; % pd = patch discovery
    
    % have pre-computed patches been handed over?
    if ( ~isempty( patchesPreComp ) )
        patches = patchesPreComp;
    else        
        % no given patches - perhaps they have instead been cached on hard
        % disk...?
        
        % first, check whether we already performed the discovery and can
        % thereby load the patch representations
        b_loadSuccess = false;
        if ( b_cachePatches  && exist ( s_destPatches, 'file' ) )
            try
                load ( s_destPatches , 'patches' );
                b_loadSuccess = true;
            catch err
                disp('Error while loading pre-computed patches')
            end
        end

        % if loading was not possible or not desired, let's perform the patch
        % discovery on our own here
        if ( ~b_loadSuccess )
            patches = findPatches ( datasetCUB200, settings ) ;
        end
        pdTime  = toc (pdTic);

        if ( b_cachePatches && ~b_loadSuccess ) 

            if ( ~exist(s_dirCachePatches, 'dir') )
                mkdir ( s_dirCachePatches );
            end


            save ( s_destPatches , 'patches' );
        end        
    end
    

    
    if ( b_onlyDiscovery )
        if ( nargout > 0 )
            out.meanPDTime = pdTime;
        end
        
        return;
    end
    
    
    %% Use discovered representations to encrypt training images and learn a multi-class classifier
    
    % first, check whether we already performed the discovery and can
    % thereby load the patch representations
    s_dirCacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTrain', '/tmp/cache/bopTrain/' );
    s_destBopTrain = sprintf( '%sunivPatchesBOPTrain.mat', s_dirCacheBOPFeaturesTrain );
    
    b_loadSuccess = false;
    if ( b_cacheBOPFeaturesTrain  && exist ( s_destBopTrain, 'file' ) )
        try
            load ( s_destBopTrain , 'bopFeaturesTrain' );
            b_loadSuccess = true;
        catch err
            disp('Error while loading pre-computed bopFeaturesTrain')
        end
    end
    
    % if loading was not possible or not desired, let's compute the
    % bag-of-part features for training images here
    if ( ~b_loadSuccess )    
        % =============================
        %    encrypt training images
        % =============================
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
        bopFeaturesTrain = computeBoPFeatures (datasetCUB200, settingsBOP, patches);
        bopFeaturesTrain = bopFeaturesTrain.bopFeaturesTrain;
        
        if ( b_cacheBOPFeaturesTrain ) 
            if ( ~exist(s_dirCacheBOPFeaturesTrain, 'dir') )
                mkdir ( s_dirCacheBOPFeaturesTrain );
            end
            
            save ( s_destBopTrain , 'bopFeaturesTrain' );
        end 
    end
        
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
        bopFeaturesTrain = settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTrain,  settingsFeaturePostPro.fh_bopFeatureMapping.settings);
    end     
    
    % embed features in higher dim. space   
    bopFeaturesTrain = ...
        encryptFeatures( settingsFeaturePostPro, bopFeaturesTrain);        

    % =============================
    %       train classifier 
    % =============================
    labels   = datasetCUB200.labels ( datasetCUB200.trainImages ) ;        
    if ( b_linearSVM )
        % use liblinear
        svmModel = liblinear_train ( labels, sparse(bopFeaturesTrain), settingsClassification );
    else
        % use libsvm
        svmModel = libsvm_train ( labels, sparse(bopFeaturesTrain), settingsClassification );
    end

    % not needed anymore
    clear('bopFeaturesTrain');
        
        
    
    
    
    
    
    %% Use discovered representations to encrypt test images and apply the previouly learned multi-class classifier
    
    % first, check whether we already performed the discovery and can
    % thereby load the patch representations
    s_dirCacheBOPFeaturesTest = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTest', '/tmp/cache/bopTest/' );
    s_destBopTest = sprintf( '%sunivPatchesBOPTest.mat', s_dirCacheBOPFeaturesTest );
    
    b_loadSuccess = false;
    if ( b_cacheBOPFeaturesTest  && exist ( s_destBopTest, 'file' ) )
        try
            load ( s_destBopTest , 'bopFeaturesTest' );
            b_loadSuccess = true;
        catch err
            disp('Error while loading pre-computed bopFeaturesTest')
        end
    end    
   
    % if loading was not possible or not desired, let's compute the
    % bag-of-part features for test images here
    if ( ~b_loadSuccess )      
        % =============================
        %      encrypt query image
        % =============================
        settingsBOP.b_computeFeaturesTrain = false;
        settingsBOP.b_computeFeaturesTest  = true;
        % caching of BOP features is done outside, since we are only
        % interested in the results, and not in the surrounding settings
        % (which would be saved as well in the script)
        settingsBOP.b_saveFeatures = false;
        %todo check whether we need some settings for the convolutions...
        settingsBOP.fh_featureExtractor = settings.fh_featureExtractor;
        % working? 
        settingsBOP.d_maxRelBoxExtent   = 0.5;        
        
        % NOTE!
        % Using GT segmentations on test images is a assumption too
        % strong for praxis. Therefore, we ignore it here. Check that your
        % remaining results are consistent here...
        settingsBOP.b_maskImages = false;
        bopFeaturesTest = computeBoPFeatures (datasetCUB200, settingsBOP, patches); 
        bopFeaturesTest = bopFeaturesTest.bopFeaturesTest;
        
        if ( b_cacheBOPFeaturesTest ) 
            
            if ( ~exist(s_dirCacheBOPFeaturesTest, 'dir') )
                mkdir ( s_dirCacheBOPFeaturesTest );
            end
            
            save ( s_destBopTest , 'bopFeaturesTest' );
        end
    end
        
    % =============================
    % post-process features of query image
    % =============================
    % map patch responses to desired interval
    bopFeaturesTest = ...
        settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTest, featMapping_additionalInfos );    

    % further normalization if desired, e.g., L1
    if (  ~isempty( settingsFeaturePostPro.fh_bopFeatureNormalization ) )
        bopFeaturesTest = settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTest,  settingsFeaturePostPro.fh_bopFeatureMapping.settings);
    end
    
    % embed features in higher dim. space
    bopFeaturesTest = ...   
        encryptFeatures( settingsFeaturePostPro, bopFeaturesTest);        


    % =============================
    % get ground truth class number of test image
    % =============================

    yTest = datasetCUB200.labels( datasetCUB200.testImages );        

    % =============================
    %     classify test image
    % =============================

    if ( b_linearSVM )
        % use liblinear
        [predicted_label, ~, scoresPatches] = liblinear_test( yTest, sparse(bopFeaturesTest), svmModel, settingsClassification );
    else
        % use libsvm
        [predicted_label, ~, scoresPatches] = libsvm_test( yTest, sparse(bopFeaturesTest), svmModel, settingsClassification );
    end

    if ( b_cacheScores )
        s_dirCacheScores = getFieldWithDefault ( settingsCache, 's_dirCacheScores', '/tmp/cache/scores/' );
        if ( ~exist(s_dirCacheScores, 'dir') )
            mkdir ( s_dirCacheScores );
        end

        s_destScores = sprintf( '%sunivPatchesFinalScores.mat', s_dirCacheScores );
        save ( s_destScores , 'scoresPatches' );            
    end     
           
    
    %% final evaluations...
    
    classLabels     = unique(datasetCUB200.labels );
    labelsTest      = datasetCUB200.labels(datasetCUB200.testImages);
    classAccuracies = zeros(length(classLabels) ,1);

    %check which samples are from which class
    for i = 1:length(classLabels) 
        classIdx = find( labelsTest == classLabels(i) );

        % count how often a sample of class i was classified correctly
        classAccuracies(i) = sum(predicted_label(classIdx)==labelsTest(classIdx));
    end
    
    % divide number of per-class-images classified correctly by total number of samples per class
    numTestSamplesPerClass = accumarray (  datasetCUB200.labels( datasetCUB200.testImages) ,1 );
    classAccuracies        = classAccuracies ./ numTestSamplesPerClass;
    
    if ( nargout > 0 )
        out.meanAcc = mean( 100*classAccuracies );
        out.stdAcc  = std( 100*classAccuracies );  
        
        out.classAccuracies = classAccuracies;
        out.numTestSamplesPerClass = numTestSamplesPerClass;
        
        if ( exist('pdTime', 'var') )
            out.meanPDTime      = pdTime;
        end
        out.scoresPatches   = scoresPatches;
    end
    
    s_result = sprintf( 'Mean accuracy with universal representation: %f ', ...
               mean( 100*classAccuracies ) );
    disp ( s_result );    
    
end
