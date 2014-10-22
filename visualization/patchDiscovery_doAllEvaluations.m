function patchDiscovery_doAllEvaluations ( additionalInfos )

    if ( nargin < 1 )
        additionalInfosTmp = [];
    else
        additionalInfosTmp = additionalInfos;
    end
   
    %% LOAD RESULTS
    %
    results_p0 = load( '/home/freytag/experiments/patches/results/dropOut0.00/final_patches.mat');
    %
    results_p0_25 = load( '/home/freytag/experiments/patches/results/dropOut0.25/final_patches.mat');
    %
    results_p0_5 = load( '/home/freytag/experiments/patches/results/dropOut0.50/final_patches.mat');
    %
    results_p0_75 = load( '/home/freytag/experiments/patches/results/dropOut0.75/final_patches.mat');

    
    %% SET DEFAULT VALUES
    % no pause while creating the plots
    if ( ( ~isfield(additionalInfosTmp,'b_doPause'))  || isempty(additionalInfosTmp.b_doPause) )
        additionalInfosTmp.b_doPause = false;
    end


    %% EVALUTE TIMES
    % 
    additionalInfosTmp.s_title = 'Time for patch discover - p=0.0';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.00/times_0_0';
    plotTimes_patchDiscovery ( results_p0, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'Time for patch discover - p=0.25';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.25/times_0_25';
    plotTimes_patchDiscovery ( results_p0_25, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'Time for patch discover - p=0.5';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.50/times_0_5';
    plotTimes_patchDiscovery ( results_p0_5, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'Time for patch discover - p=0.75';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.75/times_0_75';
    plotTimes_patchDiscovery ( results_p0_75, additionalInfosTmp );

    %% EVALUTE NUMBER OF BLOCKS PER DETECTOR
    % 
    additionalInfosTmp.s_title = 'No. of Blocks per Patch -  p=0.0';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.00/noBlocksPerPatch_0_0';
    plotNoBlocksPerPatch_patchDiscovery ( results_p0, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'No. of Blocks per Patch -  p=0.25';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.25/noBlocksPerPatch_0_25';
    plotNoBlocksPerPatch_patchDiscovery ( results_p0_25, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'No. of Blocks per Patch -  p=0.5';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.50/noBlocksPerPatch_0_5';
    plotNoBlocksPerPatch_patchDiscovery ( results_p0_5, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'No. of Blocks per Patch -  p=0.75';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.75/noBlocksPerPatch_0_75';
    plotNoBlocksPerPatch_patchDiscovery ( results_p0_75, additionalInfosTmp );
    
    %% EVALUTE NUMBER OF BLOCKS PER DETECTOR 
    %
    additionalInfosTmp.s_title = 'No. of Classes per Patch -  p=0.0';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.00/noClassesPerPatch_0_0';
    plotNoClassesPerPatch_patchDiscovery ( results_p0, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'No. of Classes per Patch -  p=0.25';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.25/noClassesPerPatch_0_25';
    plotNoClassesPerPatch_patchDiscovery ( results_p0_25, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'No. of Classes per Patch -  p=0.5';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.50/noClassesPerPatch_0_5';
    plotNoClassesPerPatch_patchDiscovery ( results_p0_5, additionalInfosTmp );
    % 
    additionalInfosTmp.s_title = 'No. of Classes per Patch -  p=0.75';
    additionalInfosTmp.s_destination = '/home/freytag/experiments/patches/results/dropOut0.75/noClassesPerPatch_0_75';
    plotNoClassesPerPatch_patchDiscovery ( results_p0_75, additionalInfosTmp );
    

end