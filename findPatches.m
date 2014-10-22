function [ patches, timesPatchDiscovery] = findPatches(dataset, settings)
% function [ patches, timesPatchDiscovery] = findPatches(dataset, settings)
% 
%  BRIEF: 
%     Given a set of images, we learn detectors trained from
%     re-occuring blocks within the images. Those detectors can serve as
%     mid-level features by indicating where specific object parts are
%     present in a specified image.
%
%  INPUT:
%     dataset  -- struct, contains at least the following fields: 
%      images       -- cell array containing file names
%      labels       -- double array with labels
%      trainImages  -- double array with indices specifying which of .images
%                      serve as training examples
% 
%     settings -- (optional) struct, main configuration object for almost
%                 all parts of the code, unspecified settings are set to
%                 default values, see folder 'setupVariables' and files
%                 therein
% 
%  OUTPUT: 
%     patches 
%     timesPatchDiscovery 
% 
%  author:        Alexander Freytag
%  last update:   26-02-2014 ( dd-mm-yyyy )

  %% set up standard parameters
  
  b_verbose          = getFieldWithDefault ( settings, 'b_verbose', true );
  
  b_debug            = getFieldWithDefault ( settings, 'b_debug', false );
  
  b_showResults      = getFieldWithDefault ( settings, 'b_showResults', false );
  
  b_saveFinalPatches = getFieldWithDefault ( settings, 'b_saveFinalPatches', false );
  
  settingsVisual     = getFieldWithDefault ( settings, 'settingsVisual', [] );
  
    
    %%
    % ========================================================
    %   --------------- (0) initialization  ---------------
    % ========================================================    
    
    settings = setupVariables_framework  ( settings );
    
    
    %%
    % ========================================================
    %   ------------------ (1.1) seeding   ------------------
    %           results in a list of image blocks
    % ========================================================
    
    timeStampSeeding = tic;
    
    
    % set specifications for behaviour of seeding part
    settingsSeeding = getFieldWithDefault( settings, 'settingsSeeding', [] ) ;
    settingsSeeding = setupVariables_Seeding( settingsSeeding );    
    
    %   
    % do the actual seeding 
    [ seedingBlocks, seedingBlockLabels ] = settings.fh_doSeeding.mfunction(dataset,settingsSeeding);
    if ( b_verbose )
        statusMsg = sprintf( 'number of seeding blocks: %d', length(seedingBlocks));
        disp(statusMsg)    
    end
    
    %%
    % ========================================================
    %   ---------- (1.2) model initialization  ------------
    %          results in a first list of patches
    % ========================================================    
    
    % how many dimensions does our feature has?
    % compute a feature for a small,  empty image to fetch the number of
    % dimensions every cell-feature has
    i_numImgChannels = size ( readImage( dataset.images{1}),3);
    i_numDim = size( settings.fh_featureExtractor.mfunction ( zeros([3 3 i_numImgChannels]) ),3 );    
    modeltemplate = initmodel_static( settings, i_numDim );
    
        
    % modeltemplate needs to contain a model.w of appropiate size 
    % (only the first 2 dimensions matter) and
    % modeltemplate.i_numCells
    %
    % a warped block is simply a block (subimg) brought to a standard size
    warpedTrainBlocks = warpBlocksToStandardSize( modeltemplate, seedingBlocks, settings.fh_featureExtractor );
    
    % pre-compute features from the seeding blocks (size normalized)
    featOfBlocks = computeFeaturesForBlocks( warpedTrainBlocks, settings);
    
    % not needed anymore
    clear('warped');
    
    % pre-compute LDA variables, i.e., cov. matrix and mean of neg. data
    [ny,nx,~] = size( featOfBlocks(1).feature );    
 
    %setup lda specific variables
    ldaStuff = initLDAStuff( ny, nx, modeltemplate);
    
    %in rare cases of DPM HOG like features, where the last dimension is
    %only used for truncation, we explicitely note this here.
    %Ricks code: td = model.features.truncation_dim;
    if ( strcmp ( settings.fh_featureExtractor.name, 'Compute HOG features using WHO code' ) || ...
         strcmp ( settings.fh_featureExtractor.name, 'HOG and Patch Means concatenated' ) || ...
         strcmp ( settings.fh_featureExtractor.name, 'HOG and Color Names' )...
       )  
        ldaStuff.i_truncDim = 32;
    else
        % no truncation for all other known feature types
        ldaStuff.i_truncDim = 0;
    end
    
    
    d_relMinScore = getFieldWithDefault ( settingsSeeding, 'd_relMinScore', 0.5);
    % this cell structure contains vectors with indices 
    patches = initPatches( featOfBlocks, seedingBlockLabels, ldaStuff, seedingBlocks, d_relMinScore);
    
    % not needed anymore
    clear('features');
    
    %do a very first clean up
    if ( settingsSeeding.b_removeDublicates )
        d_thrRedundant = getFieldWithDefault ( settingsSeeding, 'd_thrRedundant', 0.5 ) ;

        if ( b_debug )        
            statusMsg  = sprintf( 'number of seeding patches before removal of redundant ones: %d', length(patches));
            disp(statusMsg) 
        end
        
        patches = mergeRedundantPatches(patches, d_thrRedundant, ldaStuff, settingsSeeding );
        
        if ( b_debug )
            statusMsg = sprintf( 'number of seeding patches after removal of redundant ones: %d', length(patches));
            disp(statusMsg) 
        end
    end
    
    if ( b_debug )
        showResults( patches, settingsVisual );        
    end
    
    timeSeeding=toc(timeStampSeeding);
    
    %% Iterate between expansion and selection   

 
    settingsExpansionSelection = getFieldWithDefault ( settings, 'settingsExpansionSelection', [] );
    settingsExpansionSelection = setupVariables_ExpansionSelection  ( settingsExpansionSelection );
    
    timesExpansion = zeros(settingsExpansionSelection.i_noIterations,1);    

    %how many iterations between expansion and selection? (note that the
    %current selection step is pretty useless, so actually, specify how
    %many bottstrappings rounds you want to execute...)    
    for idxIter=1:settingsExpansionSelection.i_noIterations
        
        if ( b_verbose )
            statusMsg = sprintf( '\n====== ====== ====== ====== \n ====== Iteration %i/%i ==== \n====== ====== ====== ====== \n',idxIter,settingsExpansionSelection.i_noIterations);
            disp(statusMsg)
        end
    
        % ========================================================
        %   ------------------ (2) expansion   ------------------
        %   compute similar blocks to better train patch detectors 
        % ========================================================
        
        timeStampExpansion = tic;

        if ( settingsExpansionSelection.b_expansionByConvolution )
            patches = expandPatchesConvolution(dataset, patches, ldaStuff, settingsExpansionSelection );
        else
            patches = expandPatchesOnSeedingBlocks ( patches, ldaStuff, settingsExpansionSelection, seedingBlocks, seedingBlockLabels, featOfBlocks );
        end
        
        if ( b_debug )
            showResults( patches, settingsVisual );
        end        

        % ========================================================
        %   ------------------ (3) selection   ------------------
        %         get rid of uninformative/redundant patches
        % ======================================================== 
        
        if ( settingsExpansionSelection.b_doSelectionWhileBootstrapping )
            % true selection
%             [ patches additionalInfos] = selectDiscriminativePatches ( patches, dataset, settingsExpansionSelection );   
            % only remove redundant ones
            % [ patches ~ ] = removeRedundantPatches(patches, settingsExpansionSelection.d_thrRedundant);
            % merge redundant ones
            patches = mergeRedundantPatches(patches, settingsExpansionSelection.d_thrRedundant, ldaStuff, settingsExpansionSelection);
            

            % show intermediate results?
            % (4) show the results
            if ( settingsExpansionSelection.b_showResults )
                s_dest = getFieldWithDefault ( settingsVisual, 's_patchImageDestination' , '' ) ;
                settingsVisual.s_patchImageDestination = sprintf('%siter%d/',s_dest, idxIter);
                
                showResults( patches, settingsVisual );
            end                      
        else
            % show intermediate results?
            % (4) show the results
            if ( settingsExpansionSelection.b_showResults )
                s_dest = getFieldWithDefault ( settingsVisual, 's_patchImageDestination' , '' ) ;                  
                settingsVisual.s_patchImageDestination = sprintf('%siter%d/',s_dest, idxIter);
                
                showResults( patches, settingsVisual );
            end                                  
        end
        
        if ( settingsExpansionSelection.b_savePatchesInEveryIteration ) 
            s_cacheDir = settingsExpansionSelection.s_cacheDir;
            if ( exist(s_cacheDir, 'dir') == 0 )
                mkdir ( s_cacheDir );
            end
            s_destination = sprintf ('%s/patches_it_%03d', s_cacheDir ,idxIter);
            save ( s_destination, 'patches' );
        end
        
    
        timesExpansion(idxIter) = toc( timeStampExpansion );
        
        if ( sum( ~[patches.isConverged] ) == 0 )        
            % leave expansion - all patches converged already
            if ( b_verbose )
                disp('\n *** All patches converged already - abort expansion *** \n');
            end
            break;
        end
    end
    
    %% Final selection -- dimensionality reduction
    % ==============================================================
    %   ------------------ (4) final selection   ------------------
    %         perform a smart dimensionality reduction
    % ==============================================================
    
    timeStampSelection = tic;
    
    settingsFinalSelection = getFieldWithDefault ( settings, 'settingsFinalSelection', [] );
    settingsFinalSelection = setupVariables_FinalSelection  ( settingsFinalSelection );
    settingsFinalSelection.fh_featureExtractor = settings.fh_featureExtractor;

    % remove patch detectors with too few positive samples
    if ( settingsFinalSelection.b_removeUnrepresentativePatches )
        patches = removeUnrepresentativePatches ( patches, settingsFinalSelection );   
    end
    
    % compute discriminativeness for patch detectors to take the top ones
    if ( settingsFinalSelection.b_selectDiscriminativePatches )
        
        
        discriminativeness = computeDiscriminativeness ( patches, dataset, settingsFinalSelection );   
        
        % note that a possible removal of redundant patch detectors is incorporated in
        % the selection process
        patches = selectDiscriminativePatches ( patches, dataset, settingsFinalSelection, discriminativeness );   
    else
        % remove too similar detectors, without looking on their
        % discriminativeness
        if ( settingsFinalSelection.b_removeRedundantPatches )
            patches = removeRedundantPatches ( patches, settingsFinalSelection );   
        end         
    end
    
   
    
    timeSelection = toc( timeStampSelection );
    
    
    
    
    %% Prepare output variables, possibly show results, than we're done here...
    clear ( 'seedingBlocks' );
    
    if ( ( nargout > 1) || b_saveFinalPatches )
        timesPatchDiscovery.seeding   = timeSeeding;
        timesPatchDiscovery.expansion = timesExpansion;
        timesPatchDiscovery.selection = timeSelection;
    end
        
    % (4) show the results
    if ( b_showResults )
        showResults( patches, settingsVisual )
    end
    
    if ( b_saveFinalPatches ) 
        s_resultsDir = settings.s_resultsDir;
        if ( exist(s_resultsDir, 'dir') == 0 )
            mkdir ( s_resultsDir );
        end
        s_destinationResults = sprintf ('%s/final_patches', s_resultsDir);
        save ( s_destinationResults, 'patches', 'timesPatchDiscovery', 'settings', 'settingsSeeding', 'settingsExpansionSelection', 'settingsFinalSelection' );
    end    
   
end