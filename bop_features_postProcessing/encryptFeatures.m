function encryptedFeatures = encryptFeatures ( settings, features )    
% function encryptedFeatures = encryptFeatures ( settings, features )    
%
% brief:  embed features in higher dim. space approximating possible
%         kernels (see homogenous kernel maps by Vedaldi et al.), uses vlfeat
% author: Alexander Freytag
% date:   04-02-2014 (dd-mm-yyyy)

    if strcmp( settings.s_svm_Kernel , 'linear')
        encryptedFeatures = features;
    elseif strcmp( settings.s_svm_Kernel , 'intersection')
        encryptedFeatures = vl_homkermap(features', settings.i_homkermap_n, 'kinters', 'gamma', settings.d_homkermap_gamma) ;
        encryptedFeatures = encryptedFeatures';
    elseif strcmp( settings.s_svm_Kernel , 'chi-squared')      
        encryptedFeatures = vl_homkermap(features', settings.i_homkermap_n, 'kchi2', 'gamma', settings.d_homkermap_gamma) ;
        encryptedFeatures = encryptedFeatures';
    else
        error('invalid kernel, kernel %s is not impelemented',settings.s_svm_Kernel);
    end 
    
end