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
        VLFEATDIR       = '~freytag/code/3rdParty/vlfeat/';
    elseif strcmp( getenv('USER'), 'alex')
        WHODIR          = '~/src/matlab/patchesAndStuff/whoEfficient/';
        SEGMENTATIONDIR = '~/src/matlab/patchesAndStuff/segment/';
        LIBLINEARDIR    = '~/code/thirdParty/liblinear-1.93/matlab/';
        COLORNAMESDIR   = '~/code/3rdParty/colorDescriptorCVC/';
        DISCRIMCOLORDIR = '~/code/3rdParty/ColorNaming/';
        LIBSMVDIR       = '';
        IHOGDIR         = '~/code/thirdParty/inverseHoG/';
        VLFEATDIR       = '~/code/thirdParty/vlfeat/';        
    elseif strcmp( getenv('USER'), 'freytag')
        WHODIR          = '~/code/matlab/patchesAndStuff/whoEfficient/';
        SEGMENTATIONDIR = '~/code/matlab/patchesAndStuff/segment/';
        LIBLINEARDIR    = '~/code/3rdParty/liblinear-1.93/matlab/';
        LIBSMVDIR       = '~/code/3rdParty/libsvm/matlab/';
        COLORNAMESDIR   = '~/code/3rdParty/colorDescriptorCVC/';
        DISCRIMCOLORDIR = '~/code/3rdParty/ColorNaming/';
        IHOGDIR         = '~/code/3rdParty/inverseHoG/';
        VLFEATDIR       = '~/code/3rdParty/vlfeat/';        
    else
        fprintf('Unknown user %s and unknown default settings', getenv('USER') ); 
    end

    %% add paths
    
    % stuff for variable settings
    addpath( genpath( fullfile(pwd, 'setupVariables') ) );
    
    % stuff for patch generation
    addpath('seeding');
    addpath('expansion');
    addpath('selection');
    
    % visualization and debugging stuff
    addpath( genpath( fullfile(pwd, 'visualization') ) );
    
    % prepocessing for BoP features
    addpath('bop_features_postProcessing');
    
    % everything related to feature computation, e.g., HOG computation,
    % Bag-of-part-feature generation, ...
    addpath( genpath( fullfile(pwd, 'features') ) );
    
    % exemplar aspect stuff
    addpath( genpath( fullfile(pwd, 'nnQuery') ) );
    
    % stuff, e.g., computation of intersection over union and entropy rank
    % curves
    addpath( genpath( fullfile(pwd, 'misc') ) );
    
    % a large collection of evaluation scripts
    addpath( genpath( fullfile(pwd, 'evaluation') ) );
     
    
    % data and data generation
    addpath( genpath( fullfile(pwd, 'data') ) );
    
    % some demos showing how everything works
    addpath( genpath( fullfile(pwd, 'demos') ) );
    
    % add path for fast convolution stuff
    addpath('clusterdetect');

    %% 3rd party projects, developed in our group

    % object detection code with LDA models and HOG feature extraction
    if ( isempty(WHODIR) )
        fprintf('WARNING = no WHODIR dir found on your machine. Code is available at https://github.com/cvjena/whoGeneric.git \n');
    else
        addpath(genpath(WHODIR));
    end  
    
    % segmentation (felzenszwalb)
    if ( isempty(SEGMENTATIONDIR) )
        fprintf('WARNING = no SEGMENTATIONDIR dir found on your machine. Code is available at git@dbv.inf-cv.uni-jena.de:matlab-tools/felzenszwalb-segmentation.git \n');
    else
        addpath(genpath(SEGMENTATIONDIR));
    end    
    
    
    %% 3rd party projects, untouched, developed by external groups
    if ( isempty(LIBLINEARDIR) )
        fprintf('WARNING = no LIBLINEARDIR dir found on your machine. Code is available at http://www.csie.ntu.edu.tw/~cjlin/liblinear/ \n');
    else
        addpath(genpath(LIBLINEARDIR));
    end   
    
    if ( isempty(LIBSMVDIR) )
        fprintf('WARNING = no LIBSMVDIR dir found on your machine. Code is available at https://github.com/cjlin1/libsvm/ \n');
    else
        addpath(genpath(LIBSMVDIR));
    end       
    
    

    if ( isempty(COLORNAMESDIR) )
        fprintf('WARNING = no COLORNAMESDIR dir found on your machine. Code is available at http://cat.uab.es/~joost/software.html \n');
    else
        addpath(genpath(COLORNAMESDIR));
    end
    
    if ( isempty(DISCRIMCOLORDIR) )
        fprintf('WARNING = no DISCRIMCOLORDIR dir found on your machine. Code is available at http://cat.uab.es/~joost/software.html \n');
    else
        addpath(genpath(DISCRIMCOLORDIR));
    end      
    
    
    if ( isempty(IHOGDIR) )
        fprintf('WARNING = no IHOG dir found on your machine. Code is available at https://github.com/CSAILVision/ihog \n');
    else
        addpath(genpath(IHOGDIR));
    end  


    if ( isempty(VLFEATDIR) )
        fprintf('WARNING = no VLFEATDIR dir found on your machine. Code is available at http://www.vlfeat.org/ \n');
    else
        addpath(genpath(VLFEATDIR));
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
