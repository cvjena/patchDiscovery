function runComputeBOPforPartOfSupervisedPatchDiscovery ( settings, i_classIdxStart, i_classIdxEnd, i_singleClassNum )


    % built destination patches discovered on the specified part of the dataset
    %s_dest = '/home/freytag/experiments/patchDiscovery/2014-05-03-patchDiscoveryCUB200-universalRep/supervised/cache/patches/';
%
   % s_filename = sprintf( '%s%03d-%03d/', s_dest, i_start, i_end  );
   
   if ( nargin > 3 )
       settings.b_patchesFromSingleClass = true;
       settings.i_singleClassNum         = i_singleClassNum;
   else
       settings.b_patchesFromSingleClass = false;
   end


    settings.settingsDataset.i_numClasses = 200;


    %settings.settingsCache.s_dirCachePatches = s_filename;

    % adapt cache directory for discovered patches
    settings.settingsCache.s_dirCachePatches = sprintf('%s%03d-%03d/' , settings.settingsCache.s_dirCachePatches, i_classIdxStart, i_classIdxEnd);

    % adapt cache directory for bop features of itrain images
    settings.settingsCache.b_cacheBOPFeaturesTrain = true;
    settings.settingsCache.s_dirCacheBOPFeaturesTrain = sprintf('%s%03d-%03d/' , settings.settingsCache.s_dirCacheBOPFeaturesTrain, i_classIdxStart, i_classIdxEnd);
    if ( settings.b_patchesFromSingleClass )
        settings.settingsCache.s_dirCacheBOPFeaturesTrain = sprintf('%s%03d/' , settings.settingsCache.s_dirCacheBOPFeaturesTrain, i_singleClassNum);
    end

    % adapt cache directory for bop features of test images
    settings.settingsCache.b_cacheBOPFeaturesTest = true;
    settings.settingsCache.s_dirCacheBOPFeaturesTest = sprintf('%s%03d-%03d/' , settings.settingsCache.s_dirCacheBOPFeaturesTest, i_classIdxStart, i_classIdxEnd);
    if ( settings.b_patchesFromSingleClass )
        settings.settingsCache.s_dirCacheBOPFeaturesTest = sprintf('%s%03d/' , settings.settingsCache.s_dirCacheBOPFeaturesTest, i_singleClassNum);
    end    

    % show how far we already got
    settings.settingsBOP.b_verbose = true;
    
    

    %run it
    computeBOPforPartOfSupervisedPatchDiscovery ( settings );
end

