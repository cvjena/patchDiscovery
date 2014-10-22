function out = demo1_seeding
    % BRIEF:
    %   A small demo visualizing the seeding step for our patch discovery
    %   technique.
    % 
    % author: Alexander Freytag
    % date  : 05-05-2014 ( dd-mm-yyyy )



    % load the settings we usually use throughout the experiments (thresholds,
    % acceptable sizes, ... )
    load ( 'demos/settings/settings.mat', 'settingsHOGandColorNames' );

    settingsSeeding = settingsHOGandColorNames.settingsSeeding;

    % ------ settings for seeding step ------
    settingsSeeding.b_verbose      = true;        
    settingsSeeding.b_debug        = false;
    settingsSeeding.b_waitForInput = true;

    settingsSeeding.b_removeDublicates = ...
                 getFieldWithDefault ( settingsSeeding, 'b_removeDublicates', false );
    settingsSeeding.d_thrRedundant     = ...
                 getFieldWithDefault ( settingsSeeding, 'd_thrRedundant', 0.95 );


    % uncomment the following line if we want to save the images showing
    % seeding results...
    %
    %settingsSeeding.b_saveSeedingImage = true;
    %settingsSeeding.s_seedingImageDestination = ...
    %    '/home/freytag/experiments/patchDiscovery/2014-05-05-patchDiscoveryStepVisualization/seeding/';

    
    % setup the small dataset
    settingsDataset.i_numClasses = 14;
    dataset = initCUB200_2011 ( settingsDataset ) ;
    
    myRandIdx = round(rand(1,size(dataset.trainImages,2))*size(dataset.trainImages,2));
    
    % just perform seeding on some images to show the idea
    i_numImg = 30;
    dataset.trainImages = dataset.trainImages( myRandIdx(1:i_numImg ) );


    % add default settings to not specified variables
    settingsSeeding = setupVariables_Seeding( settingsSeeding );    

    %%
    % run everything
    [ seedingBlocks, seedingBlockLabels ] = ...
        doSeeding_regionBased( dataset, settingsSeeding );

   
    if ( nargout > 0 )
        out.seedingBlocks      = seedingBlocks;
        out.seedingBlockLabels = seedingBlockLabels;
    end
end