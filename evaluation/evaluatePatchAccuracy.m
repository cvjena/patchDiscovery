function accuracy = evaluatePatchAccuracy (dataset, settings, patches)

    %% (1) Compute Patches for nice Midlevel Representations
    %in case that no patches have been previously computed, we compute some
    %on our own
    if ( (nargin < 3) || isempty(patches) )
        patches = findPatches(dataset, settings);
    end

  
    classLabels = unique(dataset.labels );
    noClasses = size(classLabels, 2 );
    
    b_saveResults = false;


    %% (2) TRAIN STEP -- compute BoP features ...
    disp('\n \n ---- TRAIN STEP ------- \n \n ')
    startTrain = tic;

    disp(' (1) Compute BoP responses')
    bopFeaturesTrain = zeros(length(dataset.valImages), length(patches));
    
    
    fastConvolution = false;
    b_useSLURM = false;

    tStart_proposalGeneration = tic;
    
    
 
    
    
    if ( fastConvolution )        
        % 2014-03-04: not supported currently...        
    else
        % we do the convolution on our own    
        for i=1:length(dataset.trainImages)

            statusMsg=sprintf( '%i/%i\n',i,length(dataset.trainImages));
            disp(statusMsg)   
            tic

            imgfn = dataset.images{ dataset.trainImages(i) };
            currentImg  = readImage(imgfn);

            %the information used here obtained from the models are the same for all models
            pyraFeat = featPyramidGeneric( currentImg, patches(1).model, settings );

            for idxPatch = 1:length(patches)              
                boxes = detectWithGivenFeatures( pyraFeat, patches(idxPatch).model, patches(idxPatch).model.d_detectionThreshold);
                [bopFeaturesTrain(i,idxPatch), ~] = max(boxes(:,5));              
            end
            toc
        end   
    end

    % postprocessing of BoP features
    settingsPostPro = getFieldWithDefault ( settings, 'settingsPostPro', []);

    % setup variables
    settingsPostPro = setupVariables_postprocessing  ( settingsPostPro );
    
    % normalize patch responses
    [ bopFeaturesTrain normalization_additionalInfos] = ...
        settingsPostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTrain );    
    
    % embed features in higher dim. space
    bopFeaturesTrain = ...
        encryptFeatures( settingsPostPro, bopFeaturesTrain);


    % ... and train model
    disp(' (2) Train SVM model')
    if ( noClasses == 2 )      % standard binary classification problem 
        % todo check whether labels are already -1 +1

        % if not, convert to {-1,+1}^n
        minClass = min(classLabels);
        maxClass = max(classLabels);
        idxTrain = [dataset.valImages(:)];
        labels = 2*(dataset.labels(idxTrain)-minClass)/(maxClass-minClass)-1;
        
%         labels = -2*(dataset.labels([dataset.trainImages(:) ])-1)-1;
        svmModel = train ( labels', sparse(bopFeaturesTrain) );
        toc(startTrain)

        %cross check: number of classes should be 2
        if ( svmModel.nr_class ~= 2 )
            errorMsg = sprintf( ' problem in training: number of classes after train method is %i, expected %i', nr_class, 2);
            disp(errorMsg)
        end
        
        %TODO Parameter estimation using validation dataset? if so, run
        %train method using option '-v'
    else
        idxTrain = [dataset.valImages(:)];
        labels = dataset.labels ( idxTrain );
        
        svmModel = train ( labels', sparse(bopFeaturesTrain) );
        toc(startTrain)

        %cross check: number of classes should be equal to the estimated
        %number
        if ( svmModel.nr_class ~= noClasses )
            errorMsg = sprintf( ' problem in training: number of classes after train method is %i - expected %i', nr_class, noClasses);
            disp(errorMsg)
        end        
    end
  
    if ( b_saveResults ) 
        try
            destination = sprintf('%s/bopFeaturesTrain',settings.s_resultsDir);
            save ('-v7', destination, 'bopFeaturesTrain');
        catch error
            disp('Error while saving bop features for Train step')
        end
    end
  % not needed anymore
  clear('bopFeaturesTrain');
      
  %% (3) TEST STEP -- evaluate accuracy
  disp('\n \n ---- TEST STEP ------- \n \n ') 
  tic;

  disp(' (1) compute BoP responses test images ')
  bopFeaturesTest = zeros(length(dataset.testImages), length(patches));
  
   if ( fastConvolution ) 
     % 2014-03-04: not supported currently...       
   else  
      for i=1:length(dataset.testImages)

          statusMsg=sprintf( '%i/%i\n',i,length(dataset.testImages));
          disp(statusMsg)          

          imgfn = dataset.images{ dataset.testImages(i) };
          currentImg  = readImage(imgfn);

          %the information used here obtained from the models are the same for all models
          pyraFeat = featPyramidGeneric( currentImg, patches(1).model, settings );
          for idxPatch = 1:length(patches)              
            boxes = detectWithGivenFeatures( pyraFeat, patches(idxPatch).model, patches(idxPatch).model.d_detectionThreshold);
            [bopFeaturesTest(i,idxPatch), ~] = max(boxes(:,5));              
          end
      end
   end
  
  % normalize patch responses
  bopFeaturesTest = ...
      settingsPostPro.fh_bopFeatureNormalization.mfunction ( bopFeaturesTest, normalization_additionalInfos );    

  % embed features in higher dim. space
  bopFeaturesTest = ...   
      encryptFeatures( settingsPostPro, bopFeaturesTest);      

  disp(' (2) Perform prediction and evaluation')
  if ( noClasses == 2 )      % standard binary classification problem       
      
      %note auc evaluation demands [0,1] labels ... right? :)
      labelsTest = 2*(dataset.labels([dataset.testImages(:) ])-minClass)/(maxClass-minClass)-1;
%       labelsTest = -2*(dataset.labels([dataset.testImages(:) ])-1)-1;

      [~, ~, decision_values] = predict(double(labelsTest'), sparse(bopFeaturesTest), svmModel );

      
      [tp, fp] = roc( labelsTest==-1, decision_values);
      accuracy = auroc(tp,fp);     
      toc
      
  else
      labelsTest = dataset.labels(dataset.testImages(:));

      [predicted_label, ~, ~] = predict(double(labelsTest'), sparse(bopFeaturesTest), svmModel );

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
      toc
  end
  
    if ( b_saveResults )   
        try
            destination = sprintf('%s/bopFeaturesTest',settings.s_resultsDir);
            save ('-v7', destination, 'bopFeaturesTest');
        catch error
            disp('Error while saving bop features for Test step')
        end
    end
end