function runPartOfSupervisedPatchDiscovery( settings )
% function runPartOfSupervisedPatchDiscovery( settings )
% 
% author: Alexander Freytag
% date  : 03-05-2014 ( dd-mm-yyyy )
% 
% BRIEF:
%    Splits a dataset into several subsets and runs the supervised patch
%    discovery.


    % ----- dataset settings ----
    settingsDataset         = getFieldWithDefault ( settings, 'settingsDataset', [] );
    settingsDataset         = addDefaultVariableSetting ( settingsDataset, 'i_numClasses', 14, settingsDataset);


    % create the dataset struct, which will be used by
    % CUB200_PatchDiscovery.m
    global datasetCUB200;
    
    datasetCUB200 = initCUB200_2011 ( settingsDataset ) ;
    
    % which images are from classes in the specified range?
    i_classIdxStart = getFieldWithDefault ( settingsDataset, 'i_classIdxStart', 1);
    i_classIdxEnd   = getFieldWithDefault ( settingsDataset, 'i_classIdxEnd',   10);
    
    sampleIdxGood   = (datasetCUB200.labels(datasetCUB200.trainImages) >= i_classIdxStart) & (datasetCUB200.labels(datasetCUB200.trainImages) <= i_classIdxEnd);
    
    
    % adapt training set accordingly (val set and test set is not used for
    % patch discovery)
    datasetCUB200.trainImages = datasetCUB200.trainImages ( sampleIdxGood );
    
    % adapt settings for patch discovery, i.e., to abort after discovery,
    % to cache in the correct directories, ...
    
    settingsPatchDiscovery = settings.settingsPatchDiscovery;
    
    % abort after discovery, do not evaluate the accuracy on all test
    % images (since we only compute patches of a fraction of the actual
    % dataset here)
    settingsPatchDiscovery.b_onlyDiscovery = true;
    
    % adapt cache directory for discovered patches
    settingsPatchDiscovery.settingsCache.s_dirCachePatches = sprintf('%s%03d-%03d/' , settingsPatchDiscovery.settingsCache.s_dirCachePatches, i_classIdxStart, i_classIdxEnd);
    
    % splitting the data into several parts only makes sense for SUPERVISED
    % bootstrapping, i.e., convolving patches with images stemming from the
    % same class only...
    settingsPatchDiscovery.settingsExpansionSelection.b_supervisedBootstrapping = true;
    
    % now, run everything
    results = CUB200_PatchDiscovery ( settingsPatchDiscovery );
    
    if ( ~exist (settingsPatchDiscovery.settingsCache.s_dirCachePatches , 'dir' ) )
        mkdir ( settingsPatchDiscovery.settingsCache.s_dirCachePatches );
    end
    save ( sprintf('%stimeAndSettings.mat',settingsPatchDiscovery.settingsCache.s_dirCachePatches), 'results', 'settingsPatchDiscovery');
end
