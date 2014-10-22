function [predicted_label, accuracy, scores] =libsvm_test ( labels_test, feat_test, svmmodel, settings )
%
% BRIEF
%   A simple wrapper to provide testing of 1-vs-all-classification for LIBSVM. 
%   No further settings are adjustable currently.
% 
% INPUT
%  labels_test   -- multi-class labels (#samples x 1)
%  feat_test     -- features for test images (#samples x # dimensions)
%  svmmodel      -- cell ( #classes x 1 ), every model entry is obtained via
%                   svmtrain of the corresponding 1-vs-all-problem
%  settings      -- struct for configuring the svm classification, e.g., via
%                   'b_verbose' ...
% 
% OUTPUT:
%    predicted_label ( note: in range [ymin, ymax], consequetively ordered.
%    Don't miss to map it to the original labels!
% 
%
% date: 28-04-2014 ( dd-mm-yyyy )
% author: Alexander Freytag

    if ( nargin < 4 ) 
        settings = [];
    end
    
    libsvm_options = '';
    
    % outputs for training
    if ( ~ getFieldWithDefault ( settings, 'b_verbose', false ) )
        libsvm_options = sprintf('%s -q', libsvm_options);
    end    
  
    i_numClasses = size ( svmmodel,1);
    i_numSamples = size( labels_test,1);
    
    scores = zeros( i_numSamples, i_numClasses );
	
    % classify with every one-against-all model    
    for k=1:i_numClasses
        yBin              = 2*double( labels_test == svmmodel{k}.uniqueLabel )-1;
        [~,~,scores(:,k)] = svmpredict( yBin, feat_test, svmmodel{k}.model, libsvm_options );
    end 
    
    %# predict the class with the highest score
    [~,predicted_label] = max(scores,[],2);
    % accuracy
    accuracy = sum(predicted_label == labels_test) ./ numel(labels_test) ;   
end