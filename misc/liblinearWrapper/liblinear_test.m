function [predicted_label, accuracy, scores] =liblinear_test ( labels_test, feat_test, svmmodel, settings )
%
% BRIEF
%   A simple wrapper to provide testing of 1-vs-all-classification for LIBLINEAR. 
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
% 
%
% date: 30-04-2014 ( dd-mm-yyyy )
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
    
    b_weightBalancing = getFieldWithDefault ( settings, 'b_weightBalancing', false);
    
    if ( ~b_weightBalancing )
        [predicted_label,~,scores] = predict( labels_test, feat_test, svmmodel, libsvm_options );
    else
        scores = zeros( i_numSamples, i_numClasses );
        
        % classify with everyone-against-all model    
        for k=1:i_numClasses
            yBin              = 2*double( labels_test == svmmodel{k}.uniqueLabel )-1;
            [~,~,scores(:,k)] = predict( yBin, feat_test, svmmodel{k}, libsvm_options );
            
            %Q: Why the sign of predicted labels and decision values are sometimes reversed?
            %Please see the answer in LIBSVM faq.
            %To correctly obtain decision values, you need to check the array
            %label
            %in the model.
            scores(:,k)       = scores(:,k) .* repmat( svmmodel{k}.Label(1), [i_numSamples,1] ) ;
        end 

        %# predict the class with the highest score
        [~,predicted_label] = max(scores,[],2);        
    end

    % accuracy
    accuracy = sum(predicted_label == labels_test) ./ numel(labels_test) ;   
end