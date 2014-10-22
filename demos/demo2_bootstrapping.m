function out = demo2_bootstrapping
% BRIEF:
%   A small demo visualizing the bootstrapping of patch proposals. Demo
%   loads pre-computed proposals of a single training image, and runs the
%   patch discovery for some iterations on the CUB11 dataset.
% 
% author: Alexander Freytag
% date  : 05-05-2014 ( dd-mm-yyyy )   


    % load the settings we usually use throughout the experiments (thresholds,
    % acceptable sizes, ... )
    load ( 'demos/settings/demo2-seedingBlocks.mat', 'seedingBlocks', 'seedingBlockLabels' );


    % load the settings we usually use throughout the experiments (thresholds,
    % acceptable sizes, ... )
    load ( 'demos/settings/settings.mat', 'settingsHOGandColorNames' );

    %renaming for easy re-usage of code
    settings = settingsHOGandColorNames;

    settings.lda.b_noiseDropOut = getFieldWithDefault ( settings.lda, 'b_noiseDropOut', false );
    settings.lda.lambda         = getFieldWithDefault ( settings.lda, 'lambda', 0.01 );

    settings = setupVariables_framework  ( settings );

    settingsFeatVis = getFieldWithDefault ( settings, 'settingsFeatVis', [] );
    % just to specify how models are visualized
    settingsFeatVis.b_hardAssignment = false;
    settingsVisual.fh_featureVisualization = ...
                struct('name','Show HOG and color name weights', 'mfunction',@showWeightVectorHOGandColorNames, 'settings', settingsFeatVis );          

    % setup the dataset
    settingsDataset.i_numClasses = 14;
    dataset = initCUB200_2011 ( settingsDataset ) ;

    
    % 5 iterations
    settings.settingsExpansionSelection.i_noIterations = 5;
    % add 1 new positive example per iteration
    settings.settingsExpansionSelection.i_K            = 1;
    % which score relative to previously worst scored training sample is
    % needed for being an acceptable sample for bootstrapping?
    settings.settingsExpansionSelection.d_relMinScore  = 0.35;
    
    %
    % only run bootstrapping on images of same category
    % 1) faster
    % 2) higher accuracy
    settings.settingsExpansionSelection.b_supervisedBootstrapping = true;
    % additional output please...
    settings.settingsExpansionSelection.b_verbose                 = true;
    
    % to run everything a bit faster, we shrink the dataset towards image of
    % same category only...
    dataset.trainImages = dataset.trainImages ( ismember ( dataset.labels(dataset.trainImages), unique(seedingBlockLabels) ) );


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


        d_relMinScore = getFieldWithDefault ( settings.settingsSeeding, 'd_relMinScore', 0.5);
        % this cell structure contains vectors with indices 
        patches = initPatches( featOfBlocks, seedingBlockLabels, ldaStuff, seedingBlocks, d_relMinScore);


        settingsExpansionSelection = getFieldWithDefault ( settings, 'settingsExpansionSelection', [] );
        settingsExpansionSelection = setupVariables_ExpansionSelection  ( settingsExpansionSelection );  
        
        % -> Bootstrap on seeding blocks only? Then uncomment the following
        %    line.
        %settingsExpansionSelection.b_expansionByConvolution = false;
        
        fprintf('Show initial models')
        % -> uncomment the following lines if you want to store the model
        %    visualizations somewhere
        settingsVisual.b_savePatchImage = true;
        settingsVisual.b_saveModelImage = true;
        s_destination = '/home/freytag/experiments/patchDiscovery/2014-05-05-patchDiscoveryStepVisualization/bootstrapping/';
        settingsVisual.s_patchImageDestination = sprintf('%s/initial/',s_destination);
        
        
        % -> uncomment the following line if you do not want to click after
        %    every image
        settingsVisual.b_waitForInput = false;        

        % -> uncomment the following line if you want to visually inspect the
        %    initial models.
        showResults( patches, settingsVisual );        



        %how many iterations between expansion and selection? (note that the
        %current selection step is pretty useless, so actually, specify how
        %many bottstrappings rounds you want to execute...)    
        for idxIter=1:settingsExpansionSelection.i_noIterations

            statusMsg = sprintf( '\n====== ====== ====== ====== \n ====== Iteration %i/%i ==== \n====== ====== ====== ====== \n',idxIter,settingsExpansionSelection.i_noIterations);
            disp(statusMsg)

            % ========================================================
            %   ------------------ (2) expansion   ------------------
            %   compute similar blocks to better train patch detectors 
            % ========================================================

            if ( settingsExpansionSelection.b_expansionByConvolution )
                patches = expandPatchesConvolution(dataset, patches, ldaStuff, settingsExpansionSelection );
            else
                patches = expandPatchesOnSeedingBlocks ( patches, ldaStuff, settingsExpansionSelection, seedingBlocks, seedingBlockLabels, featOfBlocks );
            end            

            if ( sum( ~[patches.isConverged] ) == 0 )        
                % leave expansion - all patches converged already
                disp('\n *** All patches converged already - abort expansion *** \n');
                break;
            end        

            if ( getFieldWithDefault ( settingsVisual, 'b_savePatchImage', false ) )
                settingsVisual.s_patchImageDestination = sprintf('%s/iter%02d/',s_destination, idxIter);            
            end
            
            % -> Show results in every iteration? Then uncomment the following
            %    line
            showResults( patches, settingsVisual );  

        end        

    disp('\n *** Show final results of patch discovery: *** \n');    
    settingsVisual.b_savePatchImage = false;
    settingsVisual.b_saveModelImage = false;    
    showResults( patches, settingsVisual );  
    
    if ( nargout > 0 ) 
        out.patches = patches;
    end

end