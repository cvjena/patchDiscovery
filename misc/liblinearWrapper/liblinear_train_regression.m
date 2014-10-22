function svmmodel = liblinear_train_regression ( labels, feat, settings )
%
% BRIEF
%   A simple wrapper to provide training of regression for LIBLINEAR. No
%   further settings are adjustable currently.
% 
% INPUT
%  labels   -- labels (#sample x 1)
%  feat     -- features for training images (#samples x # dimensions)
%  settings -- struct for configuring the svm model training, e.g., via
%              'b_verbose', 'f_svm_C', ...
% 
% OUTPUT:
%  svmmodel -- resulting model
%
% date: 30-04-2014 ( dd-mm-yyyy )
% author: Alexander Freytag

    if ( nargin < 3 ) 
        settings = [];
    end
    
    
    libsvm_options = '';
    
    % outputs for training
    if ( ~ getFieldWithDefault ( settings, 'b_verbose', false ) )
        libsvm_options = sprintf('%s -q', libsvm_options);
    end
    
    % cost parameter
    f_svm_C = getFieldWithDefault ( settings, 'f_svm_C', 1);
    libsvm_options = sprintf('%s -c %f', libsvm_options, f_svm_C);    
    
    % do we want to use an offset for the hyperplane?
    if ( getFieldWithDefault ( settings, 'b_addOffset', false) )
        libsvm_options = sprintf('%s -B 1', libsvm_options);    
    end
    
    % which solver to use
    % copied from the liblinear manual:
%        for regression
%             11 -- L2-regularized L2-loss support vector regression (primal)
%             12 -- L2-regularized L2-loss support vector regression (dual)
%             13 -- L2-regularized L1-loss support vector regression (dual)   
    i_svmSolver = getFieldWithDefault ( settings, 'i_svmSolver', 11);
    libsvm_options = sprintf('%s -s %d', libsvm_options, i_svmSolver);  

    %# train regression model
    
    svmmodel = train( labels, feat, libsvm_options );
    
end