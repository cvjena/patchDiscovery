function out = computeBOPforPartOfSupervisedPatchDiscovery( settings ) 
%
% BRIEF
%   Needed during experimental section to run BOP-feature computation for
%   some patches only, and do this in parallel on several machines (running
%   all patches on all images needs both too much time and memory, the
%   latter especially with parallelization).
% 
% INPUT
%  settings      -- you know, the usual settings...
% 
% OUTPUT:
%   out          -- struct with fields 'bopFeaturesTrain', 'bopFeaturesTest',
%
% date: 05-05-2014 ( dd-mm-yyyy )
% author: Alexander Freytag

    
    if ( nargin < 1 ) 
        settings = [];
    end
    
    %% load settings and stuff like that
        
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


    
    % ----- caching options for patches and patch responses ----
    settingsCache           = getFieldWithDefault ( settings, 'settingsCache', [] );
    b_cacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 'b_cacheBOPFeaturesTrain', false );
    b_cacheBOPFeaturesTest  = getFieldWithDefault ( settingsCache, 'b_cacheBOPFeaturesTest',  false );    
  
    
    % ----- dataset settings ----
    settingsDataset         = getFieldWithDefault ( settings, 'settingsDataset', [] );
    settingsDataset         = addDefaultVariableSetting ( settingsDataset, 'i_numClasses', 14, settingsDataset);

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
    
    load ( s_destPatches , 'patches' );

    
    
    %% Use discovered representations to encrypt training images and learn a multi-class classifier
    
    % first, check whether we already performed the discovery and can
    % thereby load the patch representations
    s_dirCacheBOPFeaturesTrain = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTrain', '/tmp/cache/bopTrain/' );
    s_destBopTrain = sprintf( '%sunivPatchesBOPTrain.mat', s_dirCacheBOPFeaturesTrain );
    
    
    % if loading was not possible or not desired, let's compute the
    % bag-of-part features for training images here
   
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
        
    % not needed anymore
    clear('bopFeaturesTrain');
        
        
    
    
    
    
    
    %% Use discovered representations to encrypt test images and apply the previouly learned multi-class classifier
    
    % first, check whether we already performed the discovery and can
    % thereby load the patch representations
    s_dirCacheBOPFeaturesTest = getFieldWithDefault ( settingsCache, 's_dirCacheBOPFeaturesTest', '/tmp/cache/bopTest/' );
    s_destBopTest = sprintf( '%sunivPatchesBOPTest.mat', s_dirCacheBOPFeaturesTest );
    
    
        % =============================
        %      encrypt query image
        % =============================
        settingsBOP.b_computeFeaturesTrain = false;
        settingsBOP.b_computeFeaturesTest  = true;
        bopFeaturesTest = computeBoPFeatures (datasetCUB200, settingsBOP, patches); 
        bopFeaturesTest = bopFeaturesTest.bopFeaturesTest;
        
        if ( b_cacheBOPFeaturesTest ) 
            
            if ( ~exist(s_dirCacheBOPFeaturesTest, 'dir') )
                mkdir ( s_dirCacheBOPFeaturesTest );
            end
            
            save ( s_destBopTest , 'bopFeaturesTest' );
        end
        
        
    if ( nargout > 0 )
        out.bopFeaturesTrain = bopFeaturesTrain;
        out.bopFeaturesTest = bopFeaturesTest;
    end
        

    
end
