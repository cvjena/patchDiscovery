function settingsExpansionSelection = setupVariables_ExpansionSelection  ( settings )
% function settingsExpansionSelection = setupVariables_ExpansionSelection  ( settings )
% 
% author: Alexander Freytag
% last time modified: 04-02-2014 (dd-mm-yyyy)

    %% (0) check input
    if ( nargin < 1)
        settings = [];
    end    

    %% (1) copy given settings
    settingsExpansionSelection = settings;
    

    %% (2) add default values here
    
    %


    %% OUTPUT SETTINGS
    %
    % additional output ( stat bars, ... )?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_verbose', false, settingsExpansionSelection );
    
    % pretty much additional output?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_debug',   false, settingsExpansionSelection );
    
    % show intermediate results after every iteration?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_showResults', false, settingsExpansionSelection );    
    

    
        
    %% GENERAL BOOTSTRAPPING SETTINGS 
    
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'i_noIterations', 3, settingsExpansionSelection );
    %
    %add top K blocks to patch train set in every iteration
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'i_K', 3, settingsExpansionSelection );
    

    % are ALL possible locations and scales allowed for bootstrapping (i.e., convolution, -> true), or
    % do we only want to work on seeding blocks solely? ( -> false )
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_expansionByConvolution', true, settingsExpansionSelection );        
    
    % perform convolution with images of same class? Or with ALL images?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_supervisedBootstrapping', true, settingsExpansionSelection );    
    

    % after model-update in bootstrapping, multiply updated model.minScore
    % with this value. Smaller values result in more detection responses
    % possibly considered as positive samples.
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'd_relMinScore', 0.75, settingsExpansionSelection );        
    
    
    
    %% CONVOLUTION SETTINGS
    
    % do we want to run fast convolutions using FFLD ( -> true), or use
    % internal feature pyramids ( -> false) ?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_fastConvolution', false, settingsExpansionSelection );    
    
    
    % which amount of IntersectionOverUnion shall be considered as overlap?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'd_thrOverlap', 0.5, settingsExpansionSelection );
    

    % feature computation method - should be already given specified, but who knows...
    %fh_featureExtractor = struct('name','Compute HOG features using WHO code', 'mfunction',@computeHOGs_WHO);
    %fh_featureExtractor = struct('name','Compute HOG features using FFLD code', 'mfunction',@computeHOGs_FFLD);
    fh_featureExtractor = struct('name','Compute patch means', 'mfunction',@computePatchMeans);
    %fh_featureExtractor = struct('name','HOG and Patch Means concatenated', 'mfunction',@computeHOGandPatchMeans)
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'fh_featureExtractor', fh_featureExtractor, settingsExpansionSelection );
    
    % when computing the feat-pyramid, shall the response map be padded such that
    % at least a single cell of the cell array is visible? (i.e., if the
    % image could be splitted into 6x6, and the model array is of size 4x4,
    % then the resulting response is of size (3+6+3)x(3+6+3)
    % -> useful when truncated objects appear in dataset
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_padFeatPyramid', false, settingsExpansionSelection );

    
    % default: boxes cover at most 50% in width and height of input image
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'd_maxRelBoxExtent', 0.5, settingsExpansionSelection );
    
    % mask detection responses by GT segmentation annotations?
    % currently, CUB2011 is the only dataset supported
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_maskImages', true, settingsExpansionSelection );    
    
    
    % if true, no overlapping blocks are used as additional positive
    % samples during bootstrapping (supported by 
    % expandPatchesConvolution.m - convolutionByPyramids.m )
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_noOverlapInBootstrapping', true, settingsExpansionSelection );    
    
    %% SEED-BLOCK-BOOTSTRAPPING SETTINGS
    % do we want to use our fancy thresholding for estimating convergence?
    % If so, we add at most i_K new samples, if not, we add exactly i_K new
    % samples per iteration.    
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_useBootstrapThreshold', true, settingsExpansionSelection );    
    
    % should every patch detector get at maximum one positive sample per
    % image? Plausible for birds, less useful for scenes.    
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_bootstrapOnlyOnePerImg', true, settingsExpansionSelection );    
    
    
    
    %% SELECTION SETTINGS CURRENTLY UNUSED
    
    %
    % select subsets of useful detectors while bootstrapping current detectors?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_doSelectionWhileBootstrapping', false, settingsExpansionSelection );
    %
    %remove duplicate detectors?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_removeDublicates', true, settingsExpansionSelection );
    %
    % which cos sim. value is min. for being considered as a duplicate?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'd_thrRedundant', 0.5, settingsExpansionSelection );    
    
    
    %when performing selection, how many detectors per class do we want to
    %pick finally?
    %note - currently, this value is of no interest at all, since picking
    %is done by a MultiTask-L1-SVM
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'i_numPatchesPerClass', 50, settingsExpansionSelection );
            
    % how shall scores for detectors be computed to pick a useful subset of
    % them?
    %alternatively: 'entropyRank'
    settingsExpansionSelection = addDefaultVariableSetting( settings, 's_selectionScheme', 'L1-SVM', settingsExpansionSelection );
       
    % do we want to cache intermediate results?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_savePatchesInEveryIteration', false, settingsExpansionSelection );
    
    % if so, where do we want to cache intermediate results?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 's_cacheDir', '/home/freytag/experiments/patches/cache/', settingsExpansionSelection );    
    
    
    
    %% OLD SETTINGS NEEDED FOR FFLD CONVOLUTIONS
    % run FFLD code on multiple machine in parallel ( -> true )? If so, be 
    % aware that all data needs to be on all machines!
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_useSLURM', false, settingsExpansionSelection );    
        
    
    % where do we want to store our temporary models of every patch
    % detector to?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 's_modelDir', '/home/freytag/experiments/patches/model/', settingsExpansionSelection );
    
    % where do we want to store our temporary detection results of the fast
    % convolution stuff to?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 's_convolutionResultDir', '/home/freytag/experiments/patches/model/', settingsExpansionSelection );
    
    % how many jobs do we want to run in parallel?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'i_numberBatches', 40, settingsExpansionSelection );
    
    % on which partition shall we submit the jobs?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 's_partition', 'vision', settingsExpansionSelection );
    
    % which nodes of the specified partition shall we exclude?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 's_excludeNodes', 'flapjack,orange1,orange2', settingsExpansionSelection );
    
    % which nodes of the specified partition shall we exclude?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 's_includeNodes', 'argus2', settingsExpansionSelection );
    
    % to which computer do we want to ssh to?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 's_remoteHost', 'argus2', settingsExpansionSelection );
    
    % shall only a single task run on every node of our cluster?
    settingsExpansionSelection = addDefaultVariableSetting( settings, 'b_singleNodePerTask', true, settingsExpansionSelection );
    

end