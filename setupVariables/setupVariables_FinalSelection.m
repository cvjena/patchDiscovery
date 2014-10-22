function settingsFinalSelection = setupVariables_FinalSelection  ( settings )
% function settingsSeeding = setupVariables_Seeding  ( settings )
% 
% author: Alexander Freytag
% last time modified: 04-02-2014 (dd-mm-yyyy)

    %% (0) check input
    if ( nargin < 1)
        settings = [];
    end   
    
    %% (1) copy given settings
    settingsFinalSelection = settings;
    
    %% (2) add default values here
    
    
    %% REMOVE NON-REPRESENTATIVE PATCHES
        
    % remove patches which do not have at least a minimum number of positive
    % blocks?
    settingsFinalSelection = addDefaultVariableSetting( settings, 'b_removeUnrepresentativePatches', true, settingsFinalSelection );
    
     % -> remove patches with only a single positive block    
    settingsFinalSelection = addDefaultVariableSetting( settings, 'i_minNoPos', 2, settingsFinalSelection );    
    
    
    %% SELECT DISCRIMINATIVE PATCHES
    % pick patches which are discriminative wrt to a separate validation
    % set? 
    settingsFinalSelection = addDefaultVariableSetting( settings, 'b_selectDiscriminativePatches', false, settingsFinalSelection );
    
    % how shall scores for detectors be computed to pick a useful subset of
    % them?
    %alternatively: 'L1-SVM'
    settingsFinalSelection = addDefaultVariableSetting( settings, 's_selectionScheme', 'entropyRank', settingsFinalSelection );    
    
    %when performing selection, how many detectors per class do we want to
    %pick finally?
    %note - currently, this value is of no interest at all, since picking
    %is done by a MultiTask-L1-SVM
    settingsFinalSelection = addDefaultVariableSetting( settings, 'i_numPatchesPerClass', 50, settingsFinalSelection );    
    
    %% REMOVE REDUNDANT PATChES
        
    % remove patches which do not have at least a minimum number of positive
    % blocks?
    settingsFinalSelection = addDefaultVariableSetting( settings, 'b_removeRedundantPatches', true, settingsFinalSelection );
    
    %
    % which cos sim. value is min. for being considered as a duplicate?
    settingsFinalSelection = addDefaultVariableSetting( settings, 'd_thrRedundant', 0.5, settingsFinalSelection );        

end