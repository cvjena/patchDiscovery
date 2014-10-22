function settingsBOPfeatures = setupVariables_computeBoPFeatures( settings )
% function settingsBOPfeatures = setupVariables_computeBoPFeatures( settings )
% 
% brief:  Parse the input arguments and set unspecified ones to default values
% author: Alexander Freytag
% date:   28-03-2014 (dd-mm-yyyy)
% 

    %% (0) check input
    if ( nargin < 1)
        settings = [];
    end    

    %% (1) copy given settings
    settingsBOPfeatures = settings;
    
    %% (2) add default values here   
    

    %
    settingsBOPfeatures = addDefaultVariableSetting( settings, 's_bopFeatureDir', '/tmp/bopFeatures/', settingsBOPfeatures );
        
    %
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'b_saveFeatures', true, settingsBOPfeatures );    
    
    %
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'b_computeFeaturesTrain', true, settingsBOPfeatures );    
    
    %
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'b_computeFeaturesTest', true, settingsBOPfeatures );        
    
    %
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'b_featurePostProcessing', false, settingsBOPfeatures );        
    if ( ~isfield( settings, 'b_featurePostProcessing' ) || ( isempty(settings.b_featurePostProcessing ) ) )
        settingsBOPfeatures.b_featurePostProcessing  =  false;
    end
    
    %
    fh_featurePostProcessingStrategy = struct('name','Linear mapping to [-1+,1],', 'mfunction', @bop_postProcessing_linDetNorm);
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'fh_featurePostProcessingStrategy', fh_featurePostProcessingStrategy, settingsBOPfeatures );        
    
    
    %% convolution stuff
    
    % mask detection responses by GT segmentation annotations?
    % currently, CUB2011 is the only dataset supported
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'b_maskImages', true, settingsBOPfeatures );    
    
    % when computing the feat-pyramid, shall the response map be padded such that
    % at least a single cell of the cell array is visible? (i.e., if the
    % image could be splitted into 6x6, and the model array is of size 4x4,
    % then the resulting response is of size (3+6+3)x(3+6+3)
    % -> useful when truncated objects appear in dataset
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'b_padFeatPyramid', false, settingsBOPfeatures );  
    
    % default: boxes cover at most 50% in width and height of input image
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'd_maxRelBoxExtent', 0.5, settingsBOPfeatures );    
    
    %% image preprocessing
    
    % rescale input image to specified size? 
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'b_adaptRatio', false, settingsBOPfeatures );        
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'd_desiredRatio', 1.0, settingsBOPfeatures );        
    
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'b_scaleImage', false, settingsBOPfeatures );    
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'i_numRows', 256, settingsBOPfeatures );    
    settingsBOPfeatures = addDefaultVariableSetting( settings, 'i_numCols', 256, settingsBOPfeatures );    
    
end