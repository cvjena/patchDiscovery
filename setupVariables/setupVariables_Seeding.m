function settingsSeeding = setupVariables_Seeding  ( settings )
% function settingsSeeding = setupVariables_Seeding  ( settings )
% 
% author: Alexander Freytag
% last time modified: 15-05-2014 (dd-mm-yyyy)

    %% (0) check input
    if ( nargin < 1)
        settings = [];
    end    

    %% (1) copy given settings
    settingsSeeding = settings;

    
    %% (2) add default values here
    
    %%  OUTPUT RELATED SETTINGS
    
    % show as many intermediate outputs as possible
    settingsSeeding = addDefaultVariableSetting( settings, 'b_debug', false, settingsSeeding );    
    % show final seeding results
    settingsSeeding = addDefaultVariableSetting( settings, 'b_verbose', false, settingsSeeding );
    % when displaying results, should we wait for keyboard response?
    settingsSeeding = addDefaultVariableSetting( settings, 'b_waitForInput', false, settingsSeeding );    
    
    
    %% HOW TO OPERATE ON IMAGES - MULTIPLE SCALE
    
    % run seeding on multiple scales of image?
    settingsSeeding = addDefaultVariableSetting( settings, 'scales', [0 1 2 3], settingsSeeding );
    
    % how many seeding results PER SCALE do we at least want to have?
    % note: if we set this to zero, we enfore no minimum number at all
    settingsSeeding = addDefaultVariableSetting( settings, 'i_minNoBlocks', 1, settingsSeeding );
    
    % throw away seeding blocks computed on SAME scale if overlapping more
    % then this threshold (intersection over union)
    settingsSeeding = addDefaultVariableSetting( settings, 'd_overlapThr_sameScale', 0.1, settingsSeeding );
    
    % throw away seeding blocks computed on DIFFERENT scales if overlapping more
    % then this threshold (intersection over union)    
    settingsSeeding = addDefaultVariableSetting( settings, 'd_overlapThr_diffScale', 0.5, settingsSeeding );    
    
    %% CONTROL UNSUPERVISED SEGMENTATION
    
    % mask image information by GT segmentation annotations?
    % currently, CUB2011 is the only dataset supported
    settingsSeeding = addDefaultVariableSetting( settings, 'b_maskImages', true, settingsSeeding );     
    
    %previously:  k + 500, minSize = 50; right now
    % we could follow the sugg. of the paper blocks-paper: k=300,
    % minSize=20, sigma=0.5
    
    % "a larger k causes a preference for larger components" (Huttenlocher
    % & Felzenszwalb)
    settingsSeeding = addDefaultVariableSetting( settings, 'k', 500, settingsSeeding );
    % Huttenlocher-post-processing: connect two adjacent components if one of them has an
    % area smaller than minSize
    settingsSeeding = addDefaultVariableSetting( settings, 'minSize', 60, settingsSeeding );
    
    % smoothing factor for input images
    settingsSeeding = addDefaultVariableSetting( settings, 'sigma', 0.5, settingsSeeding );

    
    %% SELECTION OF VALID SEGMENTS FOR SEEDING    
    
    
    % reject region size based on absolute values or relative wrt. to the
    % original image size?
    settingsSeeding = addDefaultVariableSetting( settings, 'postProRelSize', true, settingsSeeding );

    if ( settingsSeeding.postProRelSize == false )
        % min size for not reject, either relative or absolute pixel number
        settingsSeeding = addDefaultVariableSetting( settings, 'postProMinSize', 500, settingsSeeding );
        % max size for not reject, either relative or absolute pixel number
        settingsSeeding = addDefaultVariableSetting( settings, 'postProMaxSize', 1500, settingsSeeding );
    else
        % min size for not reject, either relative or absolute pixel number
        % 1.0000e-03 equals 500 px for img of size 0.5 Mpx
        settingsSeeding = addDefaultVariableSetting( settings, 'postProMinSize', 1.0000e-03, settingsSeeding );
        
        % max size for not reject, either relative or absolute pixel number
        % 0.015 equals 1500 px for img of size 0.5 Mpx  
        settingsSeeding = addDefaultVariableSetting( settings, 'postProMaxSize', 0.015, settingsSeeding );
    end
    
    
    %arbitrary value, chose a better one!
    settingsSeeding = addDefaultVariableSetting( settings, 'postProMinGrad', 0.06, settingsSeeding );

    
    
    
    %% LAYOUT OF SEEDING RESULTS

    % use actual bounding boxes of regions (true) or only bounding boxes
    % with specified size centered at region centroid (false) ?
    settingsSeeding = addDefaultVariableSetting( settings, 'b_useRegionBBs', false, settingsSeeding );
    
    % if b_useRegionBBs == false, offset specifies half of width and height
    % of the resulting bounding box
    settingsSeeding = addDefaultVariableSetting( settings, 'offset', 32, settingsSeeding );    
    
       
   

    %% POST-SELECTION OF SIMILAR SEEDS 
    
    %remove duplicate seeding blocks before starting Bootstrapping?
    settingsSeeding = addDefaultVariableSetting( settings, 'b_removeDublicates', true, settingsSeeding );

    % which cos sim. value is min. for being considered as a duplicate?
    settingsSeeding = addDefaultVariableSetting( settings, 'd_thrRedundant', 0.1, settingsSeeding );
    

end