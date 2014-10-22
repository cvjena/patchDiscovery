function settingsPostPro = setupVariables_postprocessing  ( settings )
% function settingsPostPro = setupVariables_postprocessing  ( settings )
% 
% author: Alexander Freytag
% date: 04-02-2014 (dd-mm-yyyy)

    %% (0) check input
    if ( nargin < 1)
        settings = [];
    end   
    
    %% (1) copy given settings
    settingsPostPro = settings;
    
    %% (2) add default values here

    %  ---  feature mapping  ---
%     fh_bopFeatureMapping = struct('name','No normalization as postprocessing performed', 'mfunction',@bop_postProcessing_identity);
    fh_bopFeatureMapping = struct('name','Linear mapping to [-1,+1] wrt to training values', 'mfunction',@bop_postProcessing_linDetNorm, ...
           'settings', struct('i_newMin',-1,'i_newMax', 1) );
%     fh_bopFeatureMapping = struct('name','Non-linear mapping using a logistic fct', 'mfunction',@bop_postProcessing_logisticNormalization);

    settingsPostPro = addDefaultVariableSetting( settings, 'fh_bopFeatureMapping', fh_bopFeatureMapping, settingsPostPro );    

    %  ---  feature normalization  ---
    
    settingsPostPro = addDefaultVariableSetting( settings, 'fh_bopFeatureNormalization', [], settingsPostPro );    
    
    
    
    %  ---  feature encryption  ---
    
    % options:  'linear', 'chi-squared', 'intersection'
    settingsPostPro = addDefaultVariableSetting( settings, 's_svm_Kernel', 'linear', settingsPostPro );
    
    settingsPostPro = addDefaultVariableSetting( settings, 'i_homkermap_n', 3, settingsPostPro );

    settingsPostPro = addDefaultVariableSetting( settings, 'd_homkermap_gamma', 0.5, settingsPostPro );


    
    


end
