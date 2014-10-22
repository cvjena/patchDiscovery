function out = CUB200_kNN_PatchDiscovery_evaluateAccuracy ( settings ) 
% NOTE Here, we assume that the patch discovery is already done and both
%   training and test images as encrypted via patch responses in an
%   exemplar-specific manner
% 
%   The remaining thing is correct encription + training and test on the query image, 
%   This is done for all test images. 
%   -> This script serves to easily compare different classification techniques (e.g., linear and
%   non-linear SVM ), or post-processing settings (e.g., balanced learning,
%   C-parameters, feature normalization, ... )
% 
%   author: Alexander Freytag
%   date  : 30-04-2014 ( dd-m-yyyy )
    
    if ( nargin < 1 ) 
        settings = [];
    end
    
    %% load settings and stuff like that
    
 
    % ----- caching options for patches and patch responses ----
    settingsCache           = getFieldWithDefault ( settings, 'settingsCache', [] );
    b_cacheScores           = getFieldWithDefault ( settingsCache, 'b_cacheScores', false );
 
    % ----- settings for the kNN matching (query computations) ----
    settingsMatching        = getFieldWithDefault ( settings, 'settingsMatching', [] );
    % work on 20 most similar training images to perform patch discovery
    i_kNearestNeighbors     = getFieldWithDefault ( settingsMatching, 'i_kNearestNeighbors', 20 );   
    settingsMatching.i_kNearestNeighbors = i_kNearestNeighbors;
    %TODO less dependent on feature extraction for patch detection
    %please...
    settings.fh_featureExtractor = getFieldWithDefault ( settings, 'fh_featureExtractor', ...
       struct('name','HOG and Color Names', 'mfunction',@computeHOGandColorNames) );   
    settingsMatching.settingsFeat.fh_featureExtractor = settings.fh_featureExtractor; 
    
    % ----- visualization options to show discovery results  ----
    settingsEval            = getFieldWithDefault ( settings, 'settingsEval', [] );
    b_verbose               = getFieldWithDefault ( settingsEval, 'b_verbose',               true  );
    b_debug                 = getFieldWithDefault ( settingsEval, 'b_debug',                 false );
    i_stepSizeProgressBar   = getFieldWithDefault ( settingsEval, 'i_stepSizeProgressBar',   2 );    
    b_showHeatmapsTest      = getFieldWithDefault ( settingsEval, 'b_showHeatmapsTest',      true  );    
    
    % ----- settings for the final classification model  ----
    settingsClassification  = getFieldWithDefault ( settings, 'settingsClassification', [] );
    b_linearSVM             = getFieldWithDefault ( settingsClassification, 'b_linearSVM', true );    
    
   
    %% load matches between test image and training images based on global features (hog in our case)    
    
    global birdNNMatching;
    global datasetCUB200;
    
    if ( isempty( birdNNMatching ) )
        try 
            load ( getFieldWithDefault ( settingsMatching, 's_nnMatchingFile', ...
                                '/home/freytag/experiments/2014-03-13-nnMatchingCUB200/200/nnMatchingCUB200.mat') , ...
                                    'birdNNMatching'...
                                  );
            nnMatching  = birdNNMatching.idxSorted;
            nrClasses   = birdNNMatching.nrClasses;
    %     
        
            if ( isempty ( datasetCUB200 ) )
                settingsInitCUB.i_numClasses = nrClasses;
                datasetCUB200 = initCUB200_2011 ( settingsInitCUB ) ;
            end       
        catch err
            disp ( '*** No cached matching loadable - perform NN matching on the fly. *** ')
        end
    else
        nnMatching  = birdNNMatching.idxSorted;
    end
    
    if ( isempty ( datasetCUB200 ) )
        disp(' *** WARNING: NO DATASET SPECIFIED, AND NOT CACHE FOUND. ABORTING! ***')
        return
    end

    
    
    % loop over all test images
    i_numClasses = size ( unique ( datasetCUB200.labels ),1 );
    classAccuracies = zeros ( i_numClasses , 1);
    confMat         = zeros ( i_numClasses , i_numClasses);
    
    i_startForLoop     = getFieldWithDefault ( settingsEval, 'i_startForLoop',   1);
    i_endForLoop       = getFieldWithDefault ( settingsEval, 'i_endForLoop', size ( datasetCUB200.testImages , 2 ) );    
    
    % just for debugging: work on second image only...
    if ( b_debug ) 
        i_startForLoop = 2;
        i_endForLoop   = 2;    
    end
   

    
    
     
    

    
    %% operate on every test image...
    
    scoresPatches =  -inf*ones( i_numClasses, (i_endForLoop-i_startForLoop+1) );    
    labelsEst     =  zeros ( i_endForLoop-i_startForLoop+1, 1 );
    
    pdTime = 0.0;
    i_shift = (-i_startForLoop+1);    
    
    for i = i_startForLoop : i_endForLoop
        
        if( rem(i-1,i_stepSizeProgressBar)==0 )
            fprintf('%d / %d\n', i, i_endForLoop );
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
        dataset.images      = relevantImages;
        dataset.trainImages = 1:i_kNearestNeighbors;         
        dataset.labels      = yRelevant;
        
        % =============================
        % get ground truth class number of test image
        % =============================

        yTest = datasetCUB200.labels( datasetCUB200.testImages(i) );        
  
        if ( b_cacheScores )
            s_dirCacheScores = getFieldWithDefault ( settingsCache, 's_dirCacheScores', '/tmp/cache/scores/' );
            if ( ~exist(s_dirCacheScores, 'dir') )
                mkdir ( s_dirCacheScores );
            end

            % determine specific name of class and image to build a proper
            % cache title
            s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(i) };
            idxSlash      = strfind(s_imgfn,'/');    
            idxDot        = strfind ( s_imgfn, '.' );
            s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
            s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            
            
            s_destScores = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheScores, i , s_className, s_imgName );
            if ( exist(s_destScores, 'file') )
                load ( s_destScores, 'scores');
                b_loadScoresSuccess = true;
            else
                b_loadScoresSuccess = false;
            end
        end   
        
    
        if ( ~b_loadScoresSuccess )
            %% Use discovered representations to encrypt training images and learn a multi-class classifier

            s_dirCacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTrain', '/tmp/cache/bopTrain/' );
                % determine specific name of class and image to build a proper
                % cache title
                s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(i) };
                idxSlash      = strfind( s_imgfn ,'/');    
                idxDot        = strfind ( s_imgfn, '.' );
                s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
                s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            

                s_destBopTrain = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheBOPFeaturesTrain, i , s_className, s_imgName );    
                
            myLoadRes = load ( s_destBopTrain );
            if ( isfield(myLoadRes, 'bopFeaturesTrain' )  )           
                bopFeaturesTrain = myLoadRes.bopFeaturesTrain;
            elseif ( isfield(myLoadRes, 'variable' )  )
                bopFeaturesTrain = myLoadRes.variable;
            end

            % for backward compatibility, set the field name properly
            if ( ~isfield ( bopFeaturesTrain, 'bopFeaturesTrain' ) )
                bopFeaturesTrain.bopFeaturesTrain = bopFeaturesTrain;
            end         

            % =============================
            % post-process features of training images
            % =============================
            settingsFeaturePostPro = getFieldWithDefault ( settings, 'settingsFeaturePostPro', [] );
            settingsFeaturePostPro = setupVariables_postprocessing  ( settingsFeaturePostPro );
            % map patch responses to desired interval      
            [ bopFeaturesTrain.bopFeaturesTrain featMapping_additionalInfos] = ...
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
            clear('bopFeaturesTrain');

            %% Use discovered representations to encrypt test images and apply the previouly learned multi-class classifier
            s_dirCacheBOPFeaturesTest = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTest', '/tmp/cache/bopTest/' );
                % determine specific name of class and image to build a proper
                % cache title
                s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(i) };
                idxSlash      = strfind(s_imgfn,'/');    
                idxDot        = strfind ( s_imgfn, '.' );
                s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
                s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            

                s_destBopTest = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheBOPFeaturesTest, i , s_className, s_imgName );

            myLoadRes = load ( s_destBopTest );
            if ( isfield(myLoadRes, 'bopFeaturesTest' )  )
                bopFeaturesTest = myLoadRes.bopFeaturesTest;            
            elseif ( isfield(myLoadRes, 'variable' )  )
                bopFeaturesTest = myLoadRes.variable;
            end

            % for backward compatibility, set the field name properly
            if ( ~isfield ( bopFeaturesTest, 'bopFeaturesTest' ) )
                bopFeaturesTest.bopFeaturesTest = bopFeaturesTest;
            end 

            if ( b_showHeatmapsTest )
                settingsHeatMapVis.b_closeImage    = true;
                settingsHeatMapVis.b_waitForInput  = true;
                settingsHeatMapVis.b_saveResults   = true;
                settingsHeatMapVis.s_dirResults    = sprintf('./heatmaps-k%03d/',i_kNearestNeighbors);
                computeHeatmapDetectionResponse ( datasetCUB200.images{ datasetCUB200.testImages(i) }, bopFeaturesTest, settingsHeatMapVis );            
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
            %     classify test image
            % =============================


            if ( b_linearSVM )
                % use liblinear
                [predicted_label, ~, scores] = liblinear_test( yTest, sparse(bopFeaturesTest.bopFeaturesTest), svmModel, settingsClassification );
            else
                % use libsvm
                [predicted_label, ~, scores] = libsvm_test( yTest, sparse(bopFeaturesTest.bopFeaturesTest), svmModel, settingsClassification );
            end 
        end
        
        scoresBlownUp   =  -inf*ones( i_numClasses, 1 );
        scoresBlownUp ( unique(yRelevant) ) = scores;
        scoresPatches( :, i+i_shift )  = scoresBlownUp;        
%         scoresPatches( unique(yRelevant), i-i_endForLoop) = scores;        
%         scoresPatches( unique(yRelevant), i)    = scores;
        if ( b_loadScoresSuccess )
            [~,predicted_label] = max ( scoresBlownUp );
        end
        labelsEst ( i+i_shift )                  = predicted_label;        
        
        if ( b_cacheScores && ~b_loadScoresSuccess )
            s_dirCacheScores = getFieldWithDefault ( settingsCache, 's_dirCacheScores', '/tmp/cache/scores/' );
            if ( ~exist(s_dirCacheScores, 'dir') )
                mkdir ( s_dirCacheScores );
            end

            % determine specific name of class and image to build a proper
            % cache title
            s_imgfn       = datasetCUB200.images{ datasetCUB200.testImages(i) };
            idxSlash      = strfind(s_imgfn,'/');    
            idxDot        = strfind ( s_imgfn, '.' );
            s_imgName     = s_imgfn( (idxSlash( (size(idxSlash,2)))+1): idxDot(size(idxDot,2))-1 );
            s_className   = s_imgfn( (idxSlash( (size(idxSlash,2)-1))+1):(idxSlash(size(idxSlash,2))-1) );            
            
            s_destScores = sprintf( '%simg_%05d_%s_%s.mat', s_dirCacheScores, i , s_className, s_imgName );
            save ( s_destScores , 'scores');            
        end
        
        
        % =============================
        % compare gt class against estimated class
        % =============================
        
        % evaluation for linear classification
        oracleSucc = ( predicted_label == yTest );
        confMat ( predicted_label, yTest ) = confMat ( predicted_label, yTest ) +1 ;
        
        if ( oracleSucc )
            classAccuracies ( yTest ) = classAccuracies ( yTest ) + 1;
        end
        
        
        if ( b_verbose )
            msgResult = sprintf( 'GT: %3d, est-lin: %3d', yTest, predicted_label );
            disp ( msgResult )
        end
        
                
    end
    
    scoresPatches = scoresPatches';
    
    pdTime = pdTime / double( i_endForLoop - i_startForLoop);
    
    
    %% final evaluations...
    classLabels     = unique(datasetCUB200.labels );
    labelsTest      = datasetCUB200.labels(datasetCUB200.testImages);
    classAccuracies = zeros(length(classLabels) ,1);

    %check which samples are from which class
    for i = 1:length(classLabels) 
        classIdx = ( labelsTest == classLabels(i) );
        
        % adapt index according to current szenario... ( only needed during
        % debugging or for explicitely specified start and end)
        classIdx = classIdx(i_startForLoop : i_endForLoop );
        
        classIdx = find ( classIdx );

        % count how often a sample of class i was classified correctly
        classAccuracies(i) = sum(labelsEst(classIdx)==labelsTest(classIdx));
    end       
    
    numTestSamplesPerClass = accumarray (  datasetCUB200.labels( datasetCUB200.testImages) ,1 );
    classAccuracies  = classAccuracies ./ numTestSamplesPerClass;

    if ( nargout > 0 )
        out.meanAccr = mean( 100*classAccuracies );
        out.stdAcc  = std( 100*classAccuracies);          
        
        out.labelsEst     = labelsEst;
        out.labelsTest    = labelsTest;          
        
        out.classAccuracies = classAccuracies;
        out.numTestSamplesPerClass = numTestSamplesPerClass;
        out.confMat                = confMat;
        
        out.meanPDTime      = pdTime;
        out.scoresPatches   = scoresPatches;
    end  
    
end
