function settingsExpanded = setupVariables_framework  ( settings )
% function settingsExpanded = setupVariables_framework  ( settings )
% 
% author: Alexander Freytag
% last time modified: 04-02-2014 (dd-mm-yyyy)

    %% (0) check input
    if ( nargin < 1)
        settings = [];
    end   
    
    %% (1) copy given settings
    settingsExpanded = settings;
    
    %% (2) add default values here
    
    %  ---  lda stuff  ---
    
    lda = [];
    
    settingsExpanded = addDefaultVariableSetting( settings, 'lda', lda, settingsExpanded );
    
    % this additionally adds a drop-out noise model 
    settingsExpanded.lda = addDefaultVariableSetting( settingsExpanded.lda, 'b_noiseDropOut', true, settingsExpanded.lda );

    settingsExpanded.lda = addDefaultVariableSetting( settingsExpanded.lda, 'd_dropOutProb', 0.5, settingsExpanded.lda );    
    
    % this adds noise on the main diagonal of the covariance matrix
    %previously: 0.5
    settingsExpanded.lda = addDefaultVariableSetting( settingsExpanded.lda, 'lambda', 0.1, settingsExpanded.lda );
    
    %threshold to reject detection with score lower than that
    settingsExpanded.lda = addDefaultVariableSetting( settingsExpanded.lda, 'd_detectionThreshold', 0, settingsExpanded.lda );    
    
    % learned things for lda model: negative mean, correlation matrix
    % NOTE: for hog features, we could use the precomputed variables from who: load('bg11.mat');
    settingsExpanded.lda = addDefaultVariableSetting( settingsExpanded.lda, 'bg', [], settingsExpanded.lda );    
    
    
   % options: @doSeeding_regionBased, @doSeeding_groundTruthParts, @doSeeding_Manually
    fh_doSeeding = struct('name','do seeding using unsupervised segmentation results', 'mfunction',@doSeeding_regionBased);
%     fh_doSeeding = struct('name','do seeding using  ground truth annotations', 'mfunction',@doSeeding_groundTruthParts);
%     fh_doSeeding = struct('name','do seeding using manual (interactive) annotations', 'mfunction',@doSeeding_Manually);
    settingsExpanded = addDefaultVariableSetting( settings, 'fh_doSeeding', fh_doSeeding, settingsExpanded );
    
    % feature computation method
%     fh_featureExtractor = struct('name','Compute HOG features using WHO code', 'mfunction',@computeHOGs_WHO);
%     fh_featureExtractor = struct('name','Compute HOG features using FFLD code', 'mfunction',@computeHOGs_FFLD);
    fh_featureExtractor = struct('name','Compute patch means', 'mfunction',@computePatchMeans);
    settingsExpanded = addDefaultVariableSetting( settings, 'fh_featureExtractor', fh_featureExtractor, settingsExpanded );
    
    % make feature extraction methods also known in subroutines
    settingsExpansionSelection = [];
    settingsExpanded = addDefaultVariableSetting( settings, 'settingsExpansionSelection', settingsExpansionSelection, settingsExpanded );
    settingsExpanded.settingsExpansionSelection = addDefaultVariableSetting( settingsExpanded, 'fh_featureExtractor', fh_featureExtractor, settingsExpanded.settingsExpansionSelection );
    
    

end
