function out = CUB200_PatchDiscovery_evaluateAccuracy ( settings ) 
% NOTE Here, we assume that the patch discovery is already done and both
%   training and test images as encrypted via patch responses
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
        
    % ----- caching options for patches and patch responses ----
    settingsCache           = getFieldWithDefault ( settings, 'settingsCache', [] );
    b_cacheScores           = getFieldWithDefault (settingsCache, 'b_cacheScores', false );
    b_cacheModel            = getFieldWithDefault (settingsCache, 'b_cacheModel', true );
 
    % ----- dataset settings ----
    settingsDataset         = getFieldWithDefault ( settings, 'settingsDataset', [] );
    settingsDataset         = addDefaultVariableSetting ( settingsDataset, 'i_numClasses', 14, settingsDataset);
    
    % ----- settings for the final classification model  ----
    settingsClassification  = getFieldWithDefault ( settings, 'settingsClassification', [] );
    b_linearSVM             = getFieldWithDefault ( settingsClassification, 'b_linearSVM', true );        

    %% get the dataset
    global datasetCUB200;
    
    if ( isempty( datasetCUB200 ) )
        datasetCUB200 = initCUB200_2011 ( settingsDataset ) ;
    end
    
    if ( isempty ( datasetCUB200 ) )
        disp(' *** WARNING: NO DATASET SPECIFIED, AND NO CACHE FOUND. ABORTING! ***')
        return
    end
    
    
    
    
    %% Use discovered representations to encrypt training images and learn a multi-class classifier
    
    disp ('load train bops features ' );
    
    s_dirCacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTrain', '/tmp/cache/bopTrain/' );
    s_destBopTrain = sprintf( '%sunivPatchesBOPTrain.mat', s_dirCacheBOPFeaturesTrain );
    load ( s_destBopTrain, 'bopFeaturesTrain' );
    
    % for backward compatibility, set the field name properly
    if ( ~isfield ( bopFeaturesTrain, 'bopFeaturesTrain' ) )
        bopFeaturesTrain.bopFeaturesTrain = bopFeaturesTrain;
    end
    
    disp ('train bops features loaded - start mapping' );
     
        
        % =============================
        % post-process features of training images
        % =============================
        settingsFeaturePostPro = getFieldWithDefault ( settings, 'settingsFeaturePostPro', [] );
        settingsFeaturePostPro = setupVariables_postprocessing  ( settingsFeaturePostPro );
        
        % map patch responses to desired interval      
        [ bopFeaturesTrain.bopFeaturesTrain featMapping_additionalInfos] = ...
            settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTrain.bopFeaturesTrain, settingsFeaturePostPro.fh_bopFeatureMapping.settings );    

   disp ('train bops features mapped - start normalization' );        
        
        % further normalization if desired, e.g., L1
        if ( ~isempty( settingsFeaturePostPro.fh_bopFeatureNormalization ) )
            bopFeaturesTrain.bopFeaturesTrain = settingsFeaturePostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTrain.bopFeaturesTrain,  settingsFeaturePostPro.fh_bopFeatureNormalization.settings);
        end 
        
   disp ('train bops features normalized - start encryption' );        
    
        % embed features in higher dim. space
        bopFeaturesTrain.bopFeaturesTrain = ...
            encryptFeatures( settingsFeaturePostPro, bopFeaturesTrain.bopFeaturesTrain);        
        
        % =============================
        %       train classifier 
        % =============================
        labels   = datasetCUB200.labels ( datasetCUB200.trainImages ) ;        
        
  disp ('train bops features encrypted - start mnodel training' );         
        
        if ( b_linearSVM )
            % use liblinear
            svmModel = liblinear_train ( labels, sparse(bopFeaturesTrain.bopFeaturesTrain), settingsClassification );
        else
            % use libsvm
            svmModel = libsvm_train ( labels, sparse(bopFeaturesTrain.bopFeaturesTrain), settingsClassification );
        end  
        
        % not needed anymore
        clear('bopFeaturesTrain');        
        
        
        if ( b_cacheModel )
            s_dirCacheModel = getFieldWithDefault ( settingsCache, 's_dirCacheModel', '/tmp/cache/model/' );
            if ( ~exist(s_dirCacheModel, 'dir') )
                mkdir ( s_dirCacheModel );
            end
            
            s_destModel = sprintf( '%ssvmModel.mat', s_dirCacheModel );
            save ( s_destModel, 'svmModel') ;
        end  
        
        
    
    
    
    
    
    %% Use discovered representations to encrypt test images and apply the previouly learned multi-class classifier
    
    disp ('load test bops features ' );
    
    s_dirCacheBOPFeaturesTest = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTest', '/tmp/cache/bopTest/' );
    s_destBopTest = sprintf( '%sunivPatchesBOPTest.mat', s_dirCacheBOPFeaturesTest );
    load ( s_destBopTest, 'bopFeaturesTest' ); 
    
    % for backward compatibility, set the field name properly
    if ( ~isfield ( bopFeaturesTest, 'bopFeaturesTest' ) )
        bopFeaturesTest.bopFeaturesTest = bopFeaturesTest;
    end    
    
    disp ('test bops features loaded - start mapping' );    
   
        
        % =============================
        % post-process features of query image
        % =============================
        % map patch responses to desired interval
        bopFeaturesTest.bopFeaturesTest = ...
            settingsFeaturePostPro.fh_bopFeatureMapping.mfunction ( bopFeaturesTest.bopFeaturesTest, featMapping_additionalInfos );    
        
    disp ('test bops features mapped - start normalization' );           
        
        % further normalization if desired, e.g., L1
        if (  ~isempty( settingsFeaturePostPro.fh_bopFeatureNormalization ) )
            bopFeaturesTest.bopFeaturesTest = settingsFeaturePostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTest.bopFeaturesTest,  settingsFeaturePostPro.fh_bopFeatureMapping.settings);
        end     
        
    disp ('test bops features normalized - start encryption' );            
        
        % embed features in higher dim. space
        bopFeaturesTest.bopFeaturesTest = ...   
            encryptFeatures( settingsFeaturePostPro, bopFeaturesTest.bopFeaturesTest);        
        
        % =============================
        % get ground truth class number of test image
        % =============================
        
        yTest = datasetCUB200.labels( datasetCUB200.testImages );        
        
        % =============================
        %     classify test image
        % =============================
        
        disp ('test bops features encrypted - start classification' );  
        
        if ( b_linearSVM )
            % use liblinear
            [predicted_label, ~, scores] = liblinear_test( yTest, sparse(bopFeaturesTest.bopFeaturesTest), svmModel, settingsClassification );
        else
            % use libsvm
            [predicted_label, ~, scores] = libsvm_test( yTest, sparse(bopFeaturesTest.bopFeaturesTest), svmModel, settingsClassification );
        end 
        
        if ( b_cacheScores )
            s_dirCacheScores = getFieldWithDefault ( settingsCache, 's_dirCacheScores', '/tmp/cache/scores/' );
            if ( ~exist(s_dirCacheScores, 'dir') )
                mkdir ( s_dirCacheScores );
            end
            
            s_destScores = sprintf( '%sunivPatchesFinalScores.mat', s_dirCacheScores );
            save ( s_destScores , 'scores'  );            
        end     
           
    
    %% final evaluations...
    
    classLabels     = unique(datasetCUB200.labels );
    labelsTest      = datasetCUB200.labels( datasetCUB200.testImages(:) );
    classAccuracies = zeros(length(classLabels) ,1);

    %check which samples are from which class
    for i = 1:length(classLabels) 
        classIdx = find( labelsTest == classLabels(i) );

        % count how often a sample of class i was classified correctly
        classAccuracies(i) = sum(predicted_label(classIdx)==labelsTest(classIdx));
    end
    
    % divide number of per-class-images classified correctly by total number of samples per class
    numTestSamplesPerClass = accumarray (  datasetCUB200.labels( datasetCUB200.testImages) ,1 );
    classAccuracies  = classAccuracies ./ numTestSamplesPerClass;
    
    if ( nargout > 0 )
        out.meanAcc = mean( 100*classAccuracies );
        out.stdAcc  = std( 100*classAccuracies );          
        out.classAccuracies = classAccuracies;
        
        out.numTestSamplesPerClass = numTestSamplesPerClass;
        
        out.scoresPatches   = scores;
    end
    
end
