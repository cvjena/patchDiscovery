function evaluateCombinationPartTransferAndPatchDiscovery ( settings ) 

    if ( nargin < 1 ) 
      settings = [];
    end
  
  
   
    
    %% (1) load the classification scores of our part transfer technique (CVPR 2014)     
    s_destScoresPartTransfer = getFieldWithDefault ( settings, 's_destScoresPartTransfer', 'scoresPartTransfer.mat');
    resultsPartTransfer = load (s_destScoresPartTransfer);
    scoresPartTransfer  = resultsPartTransfer.scores_mean;    
  
    i_numSamples        = size( scoresPartTransfer, 2);
    i_numClasses        = size( scoresPartTransfer, 1);
   
    global datasetCUB200;
    if ( isempty ( datasetCUB200 ) )
        settingsInitCUB.i_numClasses = i_numClasses;
        datasetCUB200 = initCUB200_2011 ( settingsInitCUB ) ;
    end       
  


    %% (2) try to load the classification scores for patch discovery models.
    %      if no success, compute the scores again using the cached
    %      bag-of-parts-responses for training and test images
    
    s_destScoresPatches = getFieldWithDefault ( settings, 's_destScoresPatches', 'scoresPatches.mat');
    try
        scoresPatches = load ( s_destScoresPatches );
        scoresPatches = scoresPatches.results.scoresPatches;
    catch err
        % loading of scores for patch discovery was not successful (in some
        % older code versions, we did not cache them)
        %
        % -> re-compute them based on cached bag-of-part features
        
        settingsPatchDiscovery = getFieldWithDefault ( settings, 'settingsPatchDiscovery', [] );
    
        scoresPatches     =  -inf*ones( size(scoresPartTransfer, 1), ... % #classes
                                        size(scoresPartTransfer, 2) );   % #samples    
                                    
        %% load settings and stuff like that

        % ------ settings for feature extraction and visualization ------
        settingsPatchDiscovery.settingsVisual     = getFieldWithDefault ( settingsPatchDiscovery, 'settingsVisual', [] );

        %  settingsPatchDiscovery.fh_featureExtractor = getFieldWithDefault ( settingsPatchDiscovery, 'fh_featureExtractor', ...
        %        struct('name','Compute HOG features using WHO code', 'mfunction',@computeHOGs_WHO) );
        %    settingsPatchDiscovery.fh_featureExtractor = getFieldWithDefault ( settingsPatchDiscovery, 'fh_featureExtractor', ...
        %        struct('name','Compute patch means', 'mfunction',@computePatchMeans) ); 
        %    settingsPatchDiscovery.fh_featureExtractor = getFieldWithDefault ( settingsPatchDiscovery, 'fh_featureExtractor', ...
        %        struct('name','HOG and Patch Means concatenated', 'mfunction',@computeHOGandPatchMeans) );   
        settingsPatchDiscovery.fh_featureExtractor = getFieldWithDefault ( settingsPatchDiscovery, 'fh_featureExtractor', ...
            struct('name','Color Names', 'mfunction',@computeColorNames) );       
        %    settingsPatchDiscovery.fh_featureExtractor = getFieldWithDefault ( settingsPatchDiscovery, 'fh_featureExtractor', ...
        %        struct('name','HOG and Color Names', 'mfunction',@computeHOGandColorNames) );       




        % ----- visualization options to show discovery results  ----
        settingsEval            = getFieldWithDefault ( settingsPatchDiscovery, 'settingsEval', [] );
        i_stepSizeProgressBar   = getFieldWithDefault ( settingsEval, 'i_stepSizeProgressBar',   2 );

        % ----- caching options for patches and patch responses ----
        settingsCache           = getFieldWithDefault ( settingsPatchDiscovery, 'settingsCache', [] );
        % ----- settings for the kNN matching (query computations) ----
        settingsMatching        = getFieldWithDefault ( settingsPatchDiscovery, 'settingsMatching', [] );
        % work on 20 most similar training images to perform patch discovery
        i_kNearestNeighbors     = getFieldWithDefault ( settingsMatching, 'i_kNearestNeighbors', 20 );   
        settingsMatching.i_kNearestNeighbors = i_kNearestNeighbors;
        %TODO less dependent on feature extraction for patch detection
        %please...
        settingsMatching.settingsFeat.fh_featureExtractor = settingsPatchDiscovery.fh_featureExtractor;     
        
        %% load matches between test image and training images based on global features (hog in our case)    

        global birdNNMatching;

        if ( isempty( birdNNMatching ) )
            try 
                load ( getFieldWithDefault ( settingsMatching, 's_nnMatchingFile', ...
                                    '/home/freytag/experiments/2014-03-13-nnMatchingCUB200/200/nnMatchingCUB200.mat') , ...
                                        'birdNNMatching'...
                                      );
                nnMatching  = birdNNMatching.idxSorted;
 
            catch err
                disp ( '*** No cached matching loadable - perform NN matching on the fly. *** ')
            end
        end

        if ( isempty ( datasetCUB200 ) )
            disp(' *** WARNING: NO DATASET SPECIFIED, AND NOT CACHE FOUND. ABORTING! ***')
            return
        end        
        
        
        
        %% operate on every test image...
        %NOTE for rapid computations, a parfor might be an option here...
        for i = 1 : i_numSamples

            if( rem(i-1,i_stepSizeProgressBar)==0 )
                fprintf('%d / %d\n', i, i_numSamples );
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


            relevantImages = datasetCUB200.images ( datasetCUB200.trainImages( relevantIdx ) );
            relevantImagesFlipped = datasetCUB200.images ( datasetCUB200.trainImages( relevantIdxFlipped-length(datasetCUB200.trainImages) ) );
            imgFolderNonFlipped = '_256x256/';
            imgFolderFlipped    = '_256x256_flipped/';
            relevantImagesFlipped = strrep(relevantImagesFlipped,  imgFolderNonFlipped, imgFolderFlipped);

            relevantImages = [relevantImages; relevantImagesFlipped];

            % okay, let's bring the images into 'correct' order, i.e., not
            % first all non-flipped, than all flipped, but rather sorted by
            % name/categorie/origIndex
            idxMerged = [relevantIdx;relevantIdxFlipped-length(datasetCUB200.trainImages)];
            [~,idxSort] = sort ( idxMerged, 'ascend' );
            relevantImages = relevantImages ( idxSort );

            yRelevant = datasetCUB200.labels( datasetCUB200.trainImages( idxMerged(idxSort) ) );
            dataset.images      = relevantImages;
            dataset.trainImages = 1:i_kNearestNeighbors;         
            dataset.labels      = yRelevant;

            % =============================
            %    encrypt training images
            % =============================        

            s_dirCacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTrain', '/tmp/cache/bopTrain/' );

            % determine specific name of class and image to build a proper
            % cache title
            s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(i) };
            idxSlash      = strfind( s_imgfn ,'/');    
            idxDot        = strfind ( s_imgfn, '.' );
            s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
            s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            

            s_destBopTrain = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheBOPFeaturesTrain, i , s_className, s_imgName );
            bopFeaturesTrain = load ( s_destBopTrain , 'bopFeaturesTrain' );
            bopFeaturesTrain = bopFeaturesTrain.bopFeaturesTrain;


            % =============================
            % post-process features of training images
            % =============================
            settingsPostPro = [];
            settingsPostPro = setupVariables_postprocessing  ( settingsPostPro );
            % normalize patch responses
            [ bopFeaturesTrain normalization_additionalInfos] = ...
                settingsPostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTrain );    

            % embed features in higher dim. space
            bopFeaturesTrain = ...
                encryptFeatures( settingsPostPro, bopFeaturesTrain);        

            % =============================
            %       train classifier 
            % =============================
            labels   = dataset.labels;        
            svmModel = train ( labels, sparse(bopFeaturesTrain), '-q' );


            % =============================
            %      encrypt query image
            % =============================

            s_dirCacheBOPFeaturesTest = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTest', '/tmp/cache/bopTest/' );

            % determine specific name of class and image to build a proper
            % cache title
            s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(i) };
            idxSlash      = strfind(s_imgfn,'/');    
            idxDot        = strfind ( s_imgfn, '.' );
            s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
            s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            

            s_destBopTest = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheBOPFeaturesTest, i , s_className, s_imgName );
            bopFeaturesTest = load ( s_destBopTest , 'bopFeaturesTest' );
            bopFeaturesTest = bopFeaturesTest.bopFeaturesTest;

            % =============================
            % post-process features of query image
            % =============================
            % normalize patch responses
            bopFeaturesTest = ...
                settingsPostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTest, normalization_additionalInfos );    

            % embed features in higher dim. space
            bopFeaturesTest = ...   
                encryptFeatures( settingsPostPro, bopFeaturesTest);         


            % =============================
            % get ground truth class number of test image
            % =============================

            yTest = datasetCUB200.labels( datasetCUB200.testImages(i) );

            % =============================
            %     classify test image
            % =============================

            [~, ~, scores] = predict( yTest, sparse(bopFeaturesTest), svmModel, '-q' ); 

            yAvailable = unique ( labels );

            scoresPatches ( yAvailable, i) = scores;

        end
        
        if ( exist ( 's_destScoresPatches', 'file') )
            save ( s_destScoresPatches, 'scoresPatches', '-append' );
        else
            save ( s_destScoresPatches, 'scoresPatches' );
        end
    end
    
    %% post-processing of patchDiscovery-Scores: 
    % since not all classes are among the k nearest neighbors, some classes
    % get scores -Inf
    % we map them to the min score among all classes present in the
    % k-neighborhood wrt to every test sample
    
    %% older combination
    %{
    % 1) move -Inf to +Inf (to properly get the min afterwards)
    scoresPatches( scoresPatches==-Inf ) = Inf;
    % 2) get min of every sample
    minOfSample = ( min ( scoresPatches, [] , 1)  );
    
    
    minOfSampleMat=repmat(minOfSample, [14,1]);
    % replace Inf-scores by minimum values
    scoresPatches( scoresPatches==Inf ) = minOfSampleMat ( scoresPatches==Inf );    
    %}
            
    %% combination test 2 (converting everything to probabilities)
    
    % for the patch probabilities we use a simple sigmoid style conversion
    % EVIL HACK to post-process the -Inf bug
    scoresPatches(scoresPatches == 0.0) = -inf;
    
    gamma = 10;
    scoresPatches = exp( gamma * scoresPatches );
    scoresPatches = scoresPatches ./ repmat( sum(scoresPatches), size(scoresPatches,1), 1);
       
    % and for the patch probabilities, we compute scores based on votes without weighting
    ensemble_k = 5;
    s = resultsPartTransfer.scores;
    votes = zeros( size(s{1}) );
    for k=1:ensemble_k
        sk = s{k};
        maxs = repmat(max( sk ), size(sk,1), 1);
        votes( sk == maxs ) = votes( sk == maxs ) + 1;
    end
    votes = votes ./ repmat( sum(votes), size(votes,1), 1 );
    % overwrite the scores (this an evil Saturday night quick hack from
    % erik)
    scoresPartTransfer = votes;
    
    
  
    %% evaluate accuracy for different combinations
    d_start    = 0.0;
    d_end      = 1.0;
    d_stepSize = 0.01;       
    

    
    
    
    recRates = zeros( round((d_end-d_start)/d_stepSize),1);
    
    labels_test = datasetCUB200.labels( datasetCUB200.testImages );
    
    i_cnt = 1;
    for d_weight=d_start:d_stepSize:d_end
        if ( d_weight == 0.0 )
            scoresWeighted = scoresPartTransfer;
        elseif ( d_weight == 1.0 )
            scoresWeighted = scoresPatches;
        else
            scoresWeighted = (1.0-d_weight)*scoresPartTransfer + d_weight*scoresPatches;
        end
        [~, predicted_label] = max(scoresWeighted) ;     
        
        % average recognition rate
        C = zeros(max(predicted_label), max(labels_test));
        for k=1:length(labels_test)
            C(predicted_label(k), labels_test(k)) = C(predicted_label(k), labels_test(k)) + 1;
        end
        recRates(i_cnt) = mean(diag(C) ./ sum(C,1)');
        
        % overall recognition rate
        %recRates(i_cnt) = sum(labels_test(:) == predicted_label(:)) / length(labels_test);
      
        i_cnt = i_cnt+1;
    end
    
    fprintf('First point: %f\n', recRates(1))
    fprintf('Last point: %f\n', recRates(end))
    fprintf('Maximum recognition rate: %f\n', max(recRates))
    
    
    %% move towards [%]
    recRates = 100*recRates;
    
    %% visualize the results
    figCombination = figure; 
    %
    s_titleComb = sprintf('Combination of Patch Discovery and Part Transfer');
    set ( figCombination, 'name', s_titleComb);     
    
    plot(d_start:d_stepSize:d_end, recRates);
    %
    set(findobj(gca,'Type','text'),'FontSize',16)
    xlabel('Combination weight'); 
    ylabel('Average recognition rate [%]');    
    %
    set(get(gca,'YLabel'), 'FontSize', 16);
    set(get(gca,'XLabel'), 'FontSize', 16);
    set(gca,'FontSize', 12);    
    
    
    % plot a line on level of part-transfer only
    line('XData', [d_start d_end], 'YData', [recRates(1) recRates(1)], 'LineStyle', '--',  'LineWidth', 3, 'Color','r');
    % plot a line on level of patch-discovery only
    line('XData', [d_start d_end], 'YData', [recRates(end) recRates(end)], 'LineStyle', '--',  'LineWidth', 3, 'Color','g');
    
        
    %% save images if desired
    b_saveImages = getFieldWithDefault ( settings, 'b_saveImages', false );
    
    if ( b_saveImages )
        s_destinationComb = getFieldWithDefault ( settings, 's_destinationComb', 'combinationPatchDiscoveryPartTransfer.eps' );
        print( figCombination, '-depsc', '-r300' , s_destinationComb );         
    end
  
end