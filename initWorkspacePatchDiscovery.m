function initWorkspacePatchDiscovery


    %% setup paths in use-specific manner
    
    if strcmp( getenv('USER'), 'rodner')
        WHODIR          = '~freytag/code/matlab/patchesAndStuff/whoEfficient/';
        SEGMENTATIONDIR = '~freytag/code/matlab/patchesAndStuff/segment/';
        LIBLINEARDIR    = '~freytag/code/3rdParty/liblinear-1.93/matlab/';
        LIBSMVDIR       = '~freytag/code/3rdParty/libsvm/matlab/';
        COLORNAMESDIR   = '~freytag/code/3rdParty/colorDescriptorCVC/';
        DISCRIMCOLORDIR = '~freytag/code/3rdParty/ColorNaming/';
        IHOGDIR         = '~freytag/code/3rdParty/inverseHoG/';
        VLFEATDIR       = '~freytag/code/3rdParty/vlfeat/toolbox/';
    elseif strcmp( getenv('USER'), 'alex')
        WHODIR          = '~/src/matlab/patchesAndStuff/whoEfficient/';
        SEGMENTATIONDIR = '~/src/matlab/patchesAndStuff/segment/';
        LIBLINEARDIR    = '~/code/thirdParty/liblinear-1.93/matlab/';
        COLORNAMESDIR   = '~/code/3rdParty/colorDescriptorCVC/';
        DISCRIMCOLORDIR = '~/code/3rdParty/ColorNaming/';
        LIBSMVDIR       = '';
        IHOGDIR         = '~/code/thirdParty/inverseHoG/';
        VLFEATDIR       = '~/code/thirdParty/vlfeat/toolbox/';        
    elseif strcmp( getenv('USER'), 'freytag')
        WHODIR          = '~/code/matlab/patchesAndStuff/whoEfficient/';
        SEGMENTATIONDIR = '~/code/matlab/patchesAndStuff/segment/';
        LIBLINEARDIR    = '~/code/3rdParty/liblinear-1.93/matlab/';
        LIBSMVDIR       = '~/code/3rdParty/libsvm/matlab/';
        COLORNAMESDIR   = '~/code/3rdParty/colorDescriptorCVC/';
        DISCRIMCOLORDIR = '~/code/3rdParty/ColorNaming/';
        IHOGDIR         = '~/code/3rdParty/inverseHoG/';
        VLFEATDIR       = '~/code/3rdParty/vlfeat/toolbox/';        
    else
        fprintf('Unknown user %s and unknown default settings', getenv('USER') ); 
    end

    %% add paths
    
    % add main path
    b_recursive            = false; 
    b_overwrite            = true;
    s_pathMain             = fullfile(pwd);
    addPathSafely ( s_pathMain, b_recursive, b_overwrite )
    clear ( 's_pathMain' );      
    
    % stuff for variable settings
    addpath( genpath( fullfile(pwd, 'setupVariables') ) );
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathSetupVariables    = fullfile(pwd, 'setupVariables');
    addPathSafely ( s_pathSetupVariables, b_recursive, b_overwrite )
    clear ( 's_pathSetupVariables' );     
    
    % patch proposal generation
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathPatchSeeding      = fullfile(pwd, 'seeding');
    addPathSafely ( s_pathPatchSeeding, b_recursive, b_overwrite )
    clear ( 's_pathPatchSeeding' );     

    % bootstrapping of patch detectors
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathPatchExpansion    = fullfile(pwd, 'expansion');
    addPathSafely ( s_pathPatchExpansion, b_recursive, b_overwrite )
    clear ( 's_pathPatchExpansion' );   
    
    % selection of patch detectors 
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathPatchSelection    = fullfile(pwd, 'selection');
    addPathSafely ( s_pathPatchSelection, b_recursive, b_overwrite )
    clear ( 's_pathPatchSelection' );     
    
    % visualization and debugging stuff
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathVisualizations    = fullfile(pwd, 'visualization');
    addPathSafely ( s_pathVisualizations, b_recursive, b_overwrite )
    clear ( 's_pathVisualizations' );     
    
    % prepocessing for BoP features
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathBOPpostpro        = fullfile(pwd, 'bop_features_postProcessing');
    addPathSafely ( s_pathBOPpostpro, b_recursive, b_overwrite )
    clear ( 's_pathBOPpostpro' );     
    
    % everything related to feature computation, e.g., HOG computation,
    % Bag-of-part-feature generation, ...
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathFeatures          = fullfile(pwd, 'features');
    addPathSafely ( s_pathFeatures, b_recursive, b_overwrite )
    clear ( 's_pathFeatures' );     
    
    % exemplar aspect stuff
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathExemplarAspects   = fullfile(pwd, 'nnQuery');
    addPathSafely ( s_pathExemplarAspects, b_recursive, b_overwrite )
    clear ( 's_pathExemplarAspects' );     
    
    % stuff, e.g., computation of intersection over union and entropy rank
    % curves
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathMisc              = fullfile(pwd, 'misc');
    addPathSafely ( s_pathMisc, b_recursive, b_overwrite )
    clear ( 's_pathMisc' );     
    
    % a large collection of evaluation scripts
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathEvaluations       = fullfile(pwd, 'evaluation');
    addPathSafely ( s_pathEvaluations, b_recursive, b_overwrite )
    clear ( 's_pathEvaluations' );     
     
    
    % data and data generation
    b_recursive             = false; 
    b_overwrite             = true;
    s_pathData              = fullfile(pwd, 'data');
    addPathSafely ( s_pathData, b_recursive, b_overwrite )
    clear ( 's_pathData' );     
    
    % some demos showing how everything works
    addpath( genpath( fullfile(pwd, 'demos') ) );
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathDemos             = fullfile(pwd, 'demos');
    addPathSafely ( s_pathDemos, b_recursive, b_overwrite )
    clear ( 's_pathDemos' );     
       

    %% 3rd party projects, developed in our group

    % object detection code with LDA models and HOG feature extraction
    if ( isempty(WHODIR) )
        fprintf('InitPatchDiscovery-WARNING - no WHODIR dir found on your machine. Code is available at https://github.com/cvjena/whoGeneric.git \n');
    else
        currentDir = pwd;
        cd ( WHODIR );
        initWorkspaceWHOGeneric;
        cd ( currentDir );          
    end  
    
    % segmentation (felzenszwalb)
    if ( isempty(SEGMENTATIONDIR) )
        fprintf('InitPatchDiscovery-WARNING -  no SEGMENTATIONDIR dir found on your machine. Code is available at git@dbv.inf-cv.uni-jena.de:matlab-tools/felzenszwalb-segmentation.git \n');
    else
        currentDir = pwd;
        cd ( SEGMENTATIONDIR );
        initWorkspaceSegmentation;
        cd ( currentDir );         
    end    
    
    
    %% 3rd party projects, untouched, developed by external groups
    if ( isempty(LIBLINEARDIR) )
        fprintf('InitPatchDiscovery-WARNING - no LIBLINEARDIR dir found on your machine. Code is available at http://www.csie.ntu.edu.tw/~cjlin/liblinear/ \n');
    else
        b_recursive             = true; 
        b_overwrite             = true;
        addPathSafely ( LIBLINEARDIR, b_recursive, b_overwrite );        
    end   
    
    if ( isempty(LIBSMVDIR) )
        fprintf('InitPatchDiscovery-WARNING - no LIBSMVDIR dir found on your machine. Code is available at https://github.com/cjlin1/libsvm/ \n');
    else
        b_recursive             = true; 
        b_overwrite             = true;
        addPathSafely ( LIBSMVDIR, b_recursive, b_overwrite );        
    end       
    
    

    if ( isempty(COLORNAMESDIR) )
        fprintf('InitPatchDiscovery-WARNING - no COLORNAMESDIR dir found on your machine. Code is available at http://cat.uab.es/~joost/software.html \n');
    else
        b_recursive             = true; 
        b_overwrite             = true;
        addPathSafely ( COLORNAMESDIR, b_recursive, b_overwrite );           
    end
    
    if ( isempty(DISCRIMCOLORDIR) )
        fprintf('InitPatchDiscovery-WARNING - no DISCRIMCOLORDIR dir found on your machine. Code is available at http://cat.uab.es/~joost/software.html \n');
    else
        b_recursive             = true; 
        b_overwrite             = true;
        addPathSafely ( DISCRIMCOLORDIR, b_recursive, b_overwrite );          
    end      
    
    
    if ( isempty(IHOGDIR) )
        fprintf('InitPatchDiscovery-WARNING - no IHOG dir found on your machine. Code is available at https://github.com/CSAILVision/ihog \n');
    else
        b_recursive             = true; 
        b_overwrite             = true;
        addPathSafely ( IHOGDIR, b_recursive, b_overwrite );        
    end  


    if ( isempty(VLFEATDIR) )
        fprintf('InitPatchDiscovery-WARNING - no VLFEATDIR dir found on your machine. Code is available at http://www.vlfeat.org/ \n');
    else
        currentDir = pwd;
        cd ( VLFEATDIR );
        try
            vl_setup;
        catch err
            % we got an error and abort, but go to our initial directory
            % before
            cd ( currentDir );
            assert ( false, 'InitPatchDiscovery-WARNING -- error during vl_setup, aborting...');
        end
        cd ( currentDir );
    end      
    
    %% clean up
    
    clear( 'WHODIR' );
    clear( 'SEGMENTATIONDIR' );
    clear( 'LIBLINEARDIR' );
    clear( 'LIBSMVDIR' );
    clear( 'COLORNAMESDIR' );
    clear( 'DISCRIMCOLORDIR' );
    clear( 'IHOGDIR' );
    clear( 'VLFEATDIR' );
    
end


function addPathSafely ( s_path, b_recursive, b_overwrite )
    if ( ~isempty(strfind(path, [s_path , pathsep])) )
        if ( b_overwrite )
            if ( b_recursive )
                rmpath( genpath( s_path ) );
            else
                rmpath( s_path );
            end
        else
            fprintf('InitPatchDiscovery - %s already in your path but overwriting de-activated.\n', s_path);
            return;
        end
    end
    
    if ( b_recursive )
        addpath( genpath( s_path ) );
    else
        addpath( s_path );
    end
end
