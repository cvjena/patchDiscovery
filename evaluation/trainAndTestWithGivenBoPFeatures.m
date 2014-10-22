function accuracy = trainAndTestWithGivenBoPFeatures ( myInput )

    % postprocessing of BoP features
    settings        = getFieldWithDefault ( myInput, 'settings', [] );
    
    additionalInfos = getFieldWithDefault  ( myInput , 'additionalInfos', [] );

    % setup variables
    settingsPostPro = setupVariables_postprocessing  ( settings );
    
    
    if ( isfield(myInput, 'dataset') && ~isempty(myInput.dataset) )
        dataset = myInput.dataset;
    else
        disp('No dataset information found in input struct. Aborting...');
        accuracy = 0;
        return;
    end
    
    classLabels = unique(dataset.labels );
    noClasses = size(classLabels, 2 );    
        

    %%
    disp('\n \n ---- TRAIN STEP ------- \n \n ')

    disp(' (1) Compute BoP responses')
    % already done
    
    % normalize patch responses for training images
    [ bopFeaturesNormalized.bopFeaturesTrain normalization_additionalInfos ] = ...
        settingsPostPro.fh_bopFeatureNormalization.mfunction ( myInput.bopFeaturesTrain, additionalInfos );    
    
    % embed features in higher dim. space
    bopFeaturesNormalized.bopFeaturesTrain = ...
        encryptFeatures( settingsPostPro, bopFeaturesNormalized.bopFeaturesTrain');
  
    
    disp(' (2) Train SVM model')
    if ( noClasses == 2 )      % standard binary classification problem 
        % todo check whether labels are already -1 +1

        % if not, convert to {-1,+1}^n
        minClass = min(classLabels);
        maxClass = max(classLabels);
        idxTrain = [dataset.trainImages(:)];
        labels = 2*(dataset.labels(idxTrain)-minClass)/(maxClass-minClass)-1;
        
        svmModel = train ( labels', sparse(bopFeaturesNormalized.bopFeaturesTrain') );

        %cross check: number of classes should be 2
        if ( svmModel.nr_class ~= 2 )
            errorMsg = sprintf( ' problem in training: number of classes after train method is %i, expected %i', nr_class, 2);
            disp(errorMsg)
        end
        
        %TODO Parameter estimation using validation dataset? if so, run
        %train method using option '-v'
    else
        idxTrain = [dataset.trainImages(:)];
        labels = dataset.labels ( idxTrain );
        
        svmModel = train ( labels', sparse(bopFeaturesNormalized.bopFeaturesTrain') );

        %cross check: number of classes should be equal to the estimated
        %number
        if ( svmModel.nr_class ~= noClasses )
            errorMsg = sprintf( ' problem in training: number of classes after train method is %i - expected %i', nr_class, noClasses);
            disp(errorMsg)
        end        
    end    
    
    %%  
    disp('\n \n ---- TEST STEP ------- \n \n ') 

    disp(' (1) compute BoP responses test images ')    
    % already done
    
    % normalize patch responses for test images
    bopFeaturesNormalized.bopFeaturesTest = ...
        settingsPostPro.fh_bopFeatureNormalization.mfunction ( myInput.bopFeaturesTest, normalization_additionalInfos );        
    
    % embed features in higher dim. space
    bopFeaturesNormalized.bopFeaturesTest = encryptFeatures( settingsPostPro, bopFeaturesNormalized.bopFeaturesTest');
  
    
    disp(' (2) Perform prediction and evaluation')
    if ( noClasses == 2 )      % standard binary classification problem       
      
        %note auc evaluation demands [0,1] labels ... right? :)
        labelsTest = 2*(dataset.labels([dataset.testImages(:) ])-minClass)/(maxClass-minClass)-1;

        [~, ~, decision_values] = predict(double(labelsTest'), sparse(bopFeaturesNormalized.bopFeaturesTest'), svmModel );

        [tp, fp] = roc( labelsTest==-1, decision_values);
        accuracy = auroc(tp,fp);     
    else
        labelsTest = dataset.labels(dataset.testImages(:));

        [predicted_label, ~, ~] = predict(double(labelsTest'), sparse(bopFeaturesNormalized.bopFeaturesTest'), svmModel );

        overallAccuracy =  sum(predicted_label==labelsTest')/ length(predicted_label);
      
        classwiseARR = zeros(length(classLabels) ,1);
      
        %check which samples are from which class
        for i = 1:length(classLabels) 
            classIdx = find( labelsTest == classLabels(i) );
      
            %average over samples of classes separately
            classwiseARR(i) = sum(predicted_label(classIdx)==labelsTest(classIdx)')/ length(predicted_label(classIdx));
        end
      
        %average accuracy results over all classes
        averageAccuracy =  mean(classwiseARR);
      
        accuracy = averageAccuracy;
    end    
end
