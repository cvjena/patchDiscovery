function  discriminativeness = computeDiscriminativeness ( patches, dataset, settings )
%function discriminativeness = computeDiscriminativeness ( patches, dataset, settings )
%
% BRIEF: computeDiscriminativeness 
%
%   The function accepts the following options:
%   INPUT: 
%        patches    --   our current set of patches (with models), we now want to figure
%                        out which of them are the discriminative ones
%        dataset    --   the dataset containing a training set (previously: val set)
%        settings   --   settings used: 
%                        'fh_featureExtractor', 's_selectionScheme'
%
%   OUTPUT: 
%        discriminativeness --  scores for every patch stating how discriminative
%                               the patch is estimated to be
%
%  author: Alexander Freytag
%  date:   14-05-2014 9 dd-mm-yyyy )

    

    %%
    % ==========================================================
    %    compute detector responses on  training images
    % ==========================================================
    settingsBOP = [];
    settingsBOP.b_computeFeaturesTrain = true;
    settingsBOP.b_computeFeaturesTest  = false;
    % caching of BOP features is done outside, since we are only
    % interested in the results, and not in the surrounding settings
    % (which would be saved as well in the script)
    settingsBOP.b_saveFeatures = false;
    %todo check whether we need some settings for the convolutions...
    settingsBOP.fh_featureExtractor = settings.fh_featureExtractor;
    % working? 
    settingsBOP.d_maxRelBoxExtent   = 0.5;
    % also store the position of best responses
    settingsBOP.b_storePos = false;
    bopFeaturesTrain = computeBoPFeatures (dataset, settingsBOP, patches);
    bopFeaturesTrain = bopFeaturesTrain.bopFeaturesTrain;
        
    %%
    % ==========================================================
    %               compute selection criterion
    % ==========================================================    

    numPatches = length(patches);
    
    discriminativeness = zeros ( numPatches, 1 );
    
    if ( strcmp( settings.s_selectionScheme, 'entropyRank' ) )
        % compute area under the entropy rank curve etc.
        maxRank = length(dataset.trainImages);
        for i=numPatches:-1:1
            [discriminativeness(i), ~] = computeEntropyRankCurve( bopFeaturesTrain(:,i), dataset.labels(dataset.trainImages), maxRank );
        end
        
        % sort to select the r patches with smallest auc scores 
        %[~,perm] = sort( discriminativeness,'ascend');
    elseif ( strcmp( settings.s_selectionScheme, 'L1-SVM' ) )
        
        labels = 2*(dataset.labels([dataset.trainImages(:) ])-1)-1;
        svmModel = train ( labels', sparse(bopFeaturesTrain'), '-s 5' ); %L1 regularizer
        discriminativeness = abs(svmModel.w);
        
        % sort to select the r patches with largest impact on SVM decision
        % scores
        %[~,perm] = sort( discriminativeness ,'descend');
    else
        %no scoring at all
        discriminativeness = zeros(numPatches,1);
        %perm=1:discriminativeness;
    end
    
end