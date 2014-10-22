function computedFeatures = computeBoPFeatures (dataset, settings, patches)
% function computedFeatures = computeBoPFeatures (dataset, settings, patches)
%
%   BRIEF: 
%        Given discovered patch detectors, run them on training or test
%        images, take the top response for every detector in every image (max-pooling),
%        and thereby build a feature vector for every image.
%
%   INPUT: 
%        dataset    --   struct, at least with fields 'trainImages', and
%                        'testImages'
%        settings   --   struct, at least with fields 'b_verbose',
%                        'i_stepSizeProgressBar', 'b_storePos', 
%                        'b_computeFeaturesTrain', 'b_computeFeaturesTest',
%                        'b_maskImages'
%                        -> fields not given are set to default values (see
%                        setupVariables_computeBoPFeatures.m)
%                        
%        patches    --   struct, (optional), settings used: i_numPatchesPerClass,
%                        d_thrRedundant, b_debug b_removeDublicates,
%                        b_heavyDebug
%
%   OUTPUT: 
%        computedFeatures -- struct, depending on settings the following
%                            fields can be contained: 
%                            'bopFeaturesTrain' (double, #patches x #train images),
%                            'time_bopComputationTrain' (double scalar),
%                            'posOfBoxTrain', (int, #patches x #train images x 4 -- [x1 y1 x2 y2] )
%                            'bopFeaturesTest' (double, #patches x #test images),
%                            'time_bopComputationTest' (double scalar),
%                            'posOfBoxTest', (int, #patches x #test images x 4 -- [x1 y1 x2 y2] )
%
%   author: Alexander Freytag
%   date  : 15-05-2014 ( dd-mm-yyyy, last modified)

    settingsBOP     = setupVariables_computeBoPFeatures( settings );
    
    fastConvolution = false;

    b_verbose                = getFieldWithDefault ( settingsBOP, 'b_verbose', false );
    i_stepSizeProgressBar    = getFieldWithDefault ( settingsBOP, 'i_stepSizeProgressBar', 100 );
    
    b_storePos               = getFieldWithDefault ( settingsBOP, 'b_storePos', false );
    
    b_adaptRatio             = settingsBOP.b_adaptRatio;
    d_desiredRatio           = settingsBOP.d_desiredRatio;

    
    %% (1) compute responses for train images
    if ( settingsBOP.b_computeFeaturesTrain )
        
        bopFeaturesTrain = zeros( length(patches), length(dataset.trainImages) );
        
        if ( b_storePos )
            posOfBox = zeros( length(patches), length(dataset.trainImages), 4 );
        end
        
        tStart_bopComputationTrain = tic;        

        if ( fastConvolution )  
            % 2014-03-04: not supported currently...      
        else
            % we do the convolution on our own    
            for i=1:length(dataset.trainImages)

            if ( b_verbose )
                    if( rem(i-1,i_stepSizeProgressBar)==0 )
                        fprintf('%04d / %04d\n', i, length(dataset.trainImages) );
                    end 
            end


                imgfn = dataset.images{ dataset.trainImages(i) };
                currentImg  = readImage(imgfn);
                
                if ( b_adaptRatio ) 
                    d_ratioIs   = size(currentImg,1) / double(size(currentImg,2) );
                    
                    if( d_ratioIs < d_desiredRatio )
                        % orig image is 'flater' than desired aspect ratio
                        % -> scale y axis larger, or x axis smaller
                        
                        % we scale x axis smaller, since removing
                        % information is easier then hallucinating new info
                        
                        i_numRows = size(currentImg,1);
                        i_numCols = round ( d_ratioIs/d_desiredRatio * size(currentImg,2) );
                        
                    else
                        % orig image is 'higher' than desired aspect ratio
                        % -> scale y axis smaller, or x axis higher
                        
                        % we scale y axis smaller, since removing
                        % information is easier then hallucinating new info
                        
                        i_numRows = round ( d_desiredRatio/d_ratioIs * size(currentImg,1) );
                        i_numCols = size(currentImg,2);
                    end
                    
                    currentImg = imresize ( currentImg, [i_numRows i_numCols] );
                end
                
                %the information used here obtained from the models are the same for all models
                pyraFeat = featPyramidGeneric( currentImg, patches(1).model, settingsBOP );
                
                % if masking is needed, we load the mask image already here and use
                % it for all patches.
                % In addition, the integral image can be pre-computed here.
                if ( settingsBOP.b_maskImages )
                    mask           = readMask( imgfn );
                    maskIntegral   = cumsum(cumsum(mask,2),1);
                end                

                for idxPatch = 1:length(patches)   
                    
                    boxes = detectWithGivenFeatures( pyraFeat, patches(idxPatch).model, patches(idxPatch).model.d_detectionThreshold);                  
                    
                    
                    if ( settingsBOP.b_maskImages )                     
                        % BRING BOXES TO INT-VALUES, NEEDED FOR PROPER INDEXING
                        boxes(:,1:4)    = round ( boxes(:,1:4) );
                        
                        %%% SECOND VERSION -- CHECK THAT >=1 px OF BOX ARE IN
                        %%% MASK
                        % efficient version with integral images
                        p_lu = [max(1,boxes(:,1)),            max(1,boxes(:,2)) ];%left upper
                        p_ll = [max(1,boxes(:,1)),            min(size(mask,2),boxes(:,4))];%left lower
                        p_ru = [min(size(mask,1),boxes(:,3)), max(1,boxes(:,2))];%right upper
                        p_rl = [min(size(mask,1),boxes(:,3)), min(size(mask,2),boxes(:,4))];%right lower

                        lu_cumsum = maskIntegral (  sub2ind ( size ( mask), p_lu(:,2), p_lu ( :,1) ) );
                        ll_cumsum = maskIntegral (  sub2ind ( size ( mask), p_ll(:,2), p_ll ( :,1) ) );
                        ru_cumsum = maskIntegral (  sub2ind ( size ( mask), p_ru(:,2), p_ru ( :,1) ) );
                        rl_cumsum = maskIntegral (  sub2ind ( size ( mask), p_rl(:,2), p_rl ( :,1) ) );

                        % compute resulting number of foreground pixel
                        % covered by current box
                        numPxFG = lu_cumsum + rl_cumsum - ll_cumsum - ru_cumsum;
                        boxes = boxes ( numPxFG > 0, : );                          
                    end
                    
                    
                    if ( isempty ( boxes ) )
                        bopFeaturesTrain(idxPatch,i)      = patches(idxPatch).model.d_detectionThreshold;
                        if ( b_storePos )
                            posOfBox( idxPatch, i, : ) = [1,1,size(currentImg,2),size(currentImg,1)];
                        end                        
                    else
                        [bopFeaturesTrain(idxPatch,i), maxIdx] = max(boxes(:,5));
                        if ( b_storePos )
                            posOfBox( idxPatch, i, : ) = boxes(maxIdx,1:4);
                        end
                    end
                    
                end % for-loop over patch detectors

            end % for-loop over images of train set
        end % if-case fastConvolution
        bopFeaturesTrain = bopFeaturesTrain';

        time_bopComputationTrain = toc(tStart_bopComputationTrain);
        
        % format output data
        computedFeatures.bopFeaturesTrain = bopFeaturesTrain;
        computedFeatures.time_bopComputationTrain = time_bopComputationTrain;
        if ( b_storePos )
            computedFeatures.posOfBoxTrain = round( posOfBox );
        end
    end
    
    %% (2) compute responses for test images
    
    if ( settingsBOP.b_computeFeaturesTest )
        
        tStart_bopComputationTest = tic;        
        bopFeaturesTest = zeros(length(dataset.testImages), length(patches));
        
        if ( b_storePos )
            posOfBox = zeros( length(patches), length(dataset.testImages), 4 );
        end
        
        if ( fastConvolution )   
            % 2014-03-04: not supported currently... 
        else
            % we do the convolution on our own    
            for i=1:length(dataset.testImages)
                if ( b_verbose )
                    if( rem(i-1,i_stepSizeProgressBar)==0 )
                        fprintf('%04d / %04d\n', i, length(dataset.testImages) );
                    end 
                end

                imgfn = dataset.images{ dataset.testImages(i) };
                currentImg  = readImage(imgfn);
                
                
                if ( b_adaptRatio ) 
                    d_ratioIs   = size(currentImg,1) / double(size(currentImg,2) );
                    
                    if( d_ratioIs < d_desiredRatio )
                        % orig image is 'flater' than desired aspect ratio
                        % -> scale y axis larger, or x axis smaller
                        
                        % we scale x axis smaller, since removing
                        % information is easier then hallucinating new info
                        
                        i_numRows = size(currentImg,1);
                        i_numCols = round ( d_ratioIs/d_desiredRatio * size(currentImg,2) );
                        
                    else
                        % orig image is 'higher' than desired aspect ratio
                        % -> scale y axis smaller, or x axis higher
                        
                        % we scale y axis smaller, since removing
                        % information is easier then hallucinating new info
                        
                        i_numRows = round ( d_desiredRatio/d_ratioIs * size(currentImg,1) );
                        i_numCols = size(currentImg,2);
                    end
                    
                    currentImg = imresize ( currentImg, [i_numRows i_numCols] );
                end                

                %the information used here obtained from the models are the same for all models
                pyraFeat = featPyramidGeneric( currentImg, patches(1).model, settingsBOP );

                for idxPatch = 1:length(patches)              
                    boxes = detectWithGivenFeatures( pyraFeat, patches(idxPatch).model, patches(idxPatch).model.d_detectionThreshold);
                    if ( isempty ( boxes ) )
                        bopFeaturesTest(i,idxPatch)           = patches(idxPatch).model.d_detectionThreshold;
                        if ( b_storePos )
                            posOfBox( idxPatch, i, : )        = [1,1,size(currentImg,2),size(currentImg,1)];
                        end                             
                    else
                        [bopFeaturesTest(i,idxPatch), maxIdx] = max(boxes(:,5));
                        if ( b_storePos )
                            posOfBox( idxPatch, i, : )        = boxes(maxIdx,1:4);
                        end                        
                    end                    
                end % for-loop over patch detectors
                
            end % for-loop over images of train set
        end % if-case fastConvolution    

        time_bopComputationTest = toc(tStart_bopComputationTest);
        
        % format output data
        computedFeatures.bopFeaturesTest = bopFeaturesTest;
        computedFeatures.time_bopComputationTest = time_bopComputationTest;
        if ( b_storePos )
            computedFeatures.posOfBoxTest = ( posOfBox );
        end        
    end
        
    %% save if desired
    
    s_destination = sprintf( '%s/bopFeatures.mat', settingsBOP.s_bopFeatureDir );
    
    if ( settingsBOP.b_saveFeatures )
        if ( exist(settingsBOP.s_bopFeatureDir, 'dir') == 0 )
            mkdir ( settingsBOP.s_bopFeatureDir );
        end        
        save ( s_destination, 'computedFeatures', 'settings', 'dataset');
    end

    
end
