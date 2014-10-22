function compareClassifierSettings ( settings )

    s_cacheDir = settings.s_cacheDir;
 
    settingsEval.settingsCache.s_dirCachePatches = sprintf('%spatches/',s_cacheDir);
    settingsEval.settingsCache.s_dirCacheBOPFeaturesTrain = sprintf('%sbopTrain/',s_cacheDir);
    settingsEval.settingsCache.s_dirCacheBOPFeaturesTest = sprintf('%sbopTest/',s_cacheDir);
    
    s_evalDestDir = settings.s_evalDestDir;    
    %we do not cache scores for every sample, but instead collect them in a large struct
    settingsEval.settingsCache.b_cacheScores = false;
    
    
    % load the pre-computed nnMatching (global variable which will be used in the eval
    % script)
    global birdNNMatching;
    load ( settings.s_nnMatchingFile, 'birdNNMatching' );
    % load the dataset (global variable which will be used in the eval
    % script)
    global datasetCUB200;
    settingsInitCUB.i_numClasses = birdNNMatching.nrClasses;
    datasetCUB200 = initCUB200_2011 ( settingsInitCUB ) ;    

    
    settingsEval.settingsMatching.s_nnMatchingFile = settings.s_nnMatchingFile;
    % set number of query responses to 60
    settingsEval.settingsMatching.i_kNearestNeighbors = settings.i_kNearestNeighbors;

    settingsEval.settingsEval.b_verbose = false;
    settingsEval.settingsEval.b_debug = false;
    settingsEval.settingsEval.i_stepSizeProgressBar = 100;    
    
    %%
    settingsEval.settingsClassification.b_linearSVM = true;
    settingsEval.settingsClassification.b_addOffset = true;
    settingsEval.settingsClassification.b_weightBalancing = false;
    
    settingsEval.settingsFeaturePostPro.fh_bopFeatureMapping   = struct('name','Linear mapping to [-1,+1] wrt to training values', 'mfunction',@bop_postProcessing_linDetNorm, 'settings', struct('i_newMin',-1,'i_newMax', 1) );
    settingsEval.settingsFeaturePostPro.fh_bopFeatureNormalization = [];    
    
    settingsEval.settingsCache.s_dirCacheScores = sprintf('%s/lin-1-offset-1-balancing-0/scores/',s_evalDestDir);
    
    results = CUB200_kNN_PatchDiscovery_evaluateAccuracy( settingsEval );
    
    fprintf('Accuracy: %.2f -- lin 1, offset 1, balanced 0\n\n', results.meanAccr)
    d_destDir = sprintf('%s/lin-1-offset-1-balancing-0/',s_evalDestDir );
    
    if ( ~exist(d_destDir, 'dir') )
        mkdir ( d_destDir );
    end    
    
    save ( sprintf('%sresults.mat', d_destDir ), 'results', 'settings');

    %%
    settingsEval.settingsClassification.b_linearSVM = true;
    settingsEval.settingsClassification.b_addOffset = false;
    settingsEval.settingsClassification.b_weightBalancing = false;
    
    settingsEval.settingsFeaturePostPro.fh_bopFeatureMapping   = struct('name','Linear mapping to [-1,+1] wrt to training values', 'mfunction',@bop_postProcessing_linDetNorm, 'settings', struct('i_newMin',-1,'i_newMax', 1) );
    settingsEval.settingsFeaturePostPro.fh_bopFeatureNormalization = [];    
    
    settingsEval.settingsCache.s_dirCacheScores = sprintf('%s/lin-1-offset-0-balancing-0/scores/',s_evalDestDir);
    
    results = CUB200_kNN_PatchDiscovery_evaluateAccuracy( settingsEval );
    fprintf('Accuracy: %.2f -- lin 1, offset 0, balanced 0\n\n', results.meanAccr)
    d_destDir = sprintf('%s/lin-1-offset-0-balancing-0/',s_evalDestDir );
    
    if ( ~exist(d_destDir, 'dir') )
        mkdir ( d_destDir );
    end    
    
    save ( sprintf('%sresults.mat', d_destDir ), 'results', 'settings');

end