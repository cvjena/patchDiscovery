function [regressionScores, mse ] =liblinear_test_regression ( labels_test, feat_test, svmmodel, settings )
%
% BRIEF
%   A simple wrapper to provide testing of regression for LIBLINEAR.. 
%   No further settings are adjustable currently.
% 
% INPUT
%  labels_test   -- regression labels (#samples x 1)
%  feat_test     -- features for test images (#samples x # dimensions)
%  svmmodel      -- previously trained regression model
%  settings      -- struct for configuring the svm regression, e.g., via
%                   'b_verbose' ...
% 
% OUTPUT:
%    regressionScores
%    mse
%
% date: 15-05-2014 ( dd-mm-yyyy )
% author: Alexander Freytag

    if ( nargin < 4 ) 
        settings = [];
    end
    
    libsvm_options = '';
    
    % outputs for training
    if ( ~ getFieldWithDefault ( settings, 'b_verbose', false ) )
        libsvm_options = sprintf('%s -q', libsvm_options);
    end    
  
    i_numSamples = size( labels_test,1);
    
    [regressionScores, mse ,~] = predict( labels_test, feat_test, svmmodel, libsvm_options );

end