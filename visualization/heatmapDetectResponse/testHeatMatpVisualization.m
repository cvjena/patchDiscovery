load ( '/home/freytag/experiments/patchDiscovery/2014-04-28-patchDiscoveryUniversalRepresentation/supervisedBootstrapping/cache/patches/univPatches.mat');


settingsDataset.i_numClasses = 14;
settingsDataset.dataBaseDir = '/home/freytag/data/finegrained/cub200_2011/';

dataset = initCUB200_2011 ( settingsDataset );

% =============================
%    encrypt training images
% =============================
settingsBOP = [];
settingsBOP.b_computeFeaturesTrain = true;
settingsBOP.b_computeFeaturesTest  = false;
% caching of BOP features is done outside, since we are only
% interested in the results, and not in the surrounding settings
% (which would be saved as well in the script)
settingsBOP.b_saveFeatures = false;
%todo check whether we need some settings for the convolutions...
settingsBOP.fh_featureExtractor = struct('name','HOG and Color Names', 'mfunction',@computeHOGandColorNames);
% working? 
settingsBOP.d_maxRelBoxExtent   = 0.5;

settingsBOP.b_storePos = true;
 % :D FIXME
settingsBOP.false = true;

settingsBOP.b_adaptRatio   = true;
settingsBOP.d_desiredRatio = 265/double(256);

settingsBOP.b_maskImages = false;

settingsHeatMapVis.b_saveResults   = true;
settingsHeatMapVis.s_dirResults    = './heatmaps/';
settingsHeatMapVis.b_waitForInput  = false;
settingsHeatMapVis.b_closeImage    = true;

settingsHeatMapVis.b_adaptRatio    = settingsBOP.b_adaptRatio;
settingsHeatMapVis.d_desiredRatio  = settingsBOP.d_desiredRatio;


for i=1:length(dataset.trainImages ) 
    
    %only work on a single image
    datasetLocal = dataset;
    datasetLocal.trainImages = datasetLocal.trainImages ( i ) ;
    
    % compute responses for current image
    bopFeaturesTrain = computeBoPFeatures (datasetLocal, settingsBOP, patches);
    
    fn_orig   = dataset.images { dataset.trainImages ( i ) };
    figHandle = figure;
    
    figHandle = computeHeatmapDetectionResponse ( fn_orig, bopFeaturesTrain, settingsHeatMapVis, figHandle );
 
    close ( figHandle );
end