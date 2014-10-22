function svmmodel = libsvm_train ( labels, feat, settings )
%
% BRIEF
%   A simple wrapper to provide training of 1-vs-all-classification for LIBSVM. No
%   further settings are adjustable currently.
% 
% INPUT
%  labels   -- multi-class labels (#sample x 1)
%  feat     -- features for training images (#samples x # dimensions)
%  settings -- struct for configuring the svm model training, e.g., via
%              'b_verbose', 's_svm_type', 's_kernel_type', 'f_svm_C', ...
% 
% OUTPUT:
%  svmmodel -- cell ( #classes x 1 ), every model entry is obtained via
%              svmtrain of the corresponding 1-vs-all-problem
%
% date: 28-04-2014 ( dd-mm-yyyy )
% author: Alexander Freytag

    if ( nargin < 3 ) 
        settings = [];
    end
%     
    
    libsvm_options = '';
    
    % outputs for training
    if ( ~ getFieldWithDefault ( settings, 'b_verbose', false ) )
        libsvm_options = sprintf('%s -q', libsvm_options);
    end
    
   
    % 	-s svm_type : set type of SVM (default 0)
	% 	0 -- C-SVC		(multi-class classification)
	% 	1 -- nu-SVC		(multi-class classification)
	% 	2 -- one-class SVM
	% 	3 -- epsilon-SVR	(regression)
	% 	4 -- nu-SVR		(regression)    
    s_svm_type = getFieldWithDefault ( settings, 's_svm_type', '0');
    libsvm_options = sprintf('%s -s %s', libsvm_options, s_svm_type);    

    %   -t kernel_type : set type of kernel function (default 2)
    % 	0 -- linear: u'*v
    % 	1 -- polynomial: (gamma*u'*v + coef0)^degree
    % 	2 -- radial basis function: exp(-gamma*|u-v|^2)
    % 	3 -- sigmoid: tanh(gamma*u'*v + coef0)        
    s_kernel_type = getFieldWithDefault ( settings, 's_kernel_type', '2');
    libsvm_options = sprintf('%s -t %s', libsvm_options, s_kernel_type);

    % cost parameter
    f_svm_C = getFieldWithDefault ( settings, 'f_svm_C', 1);
    libsvm_options = sprintf('%s -c %f', libsvm_options, f_svm_C);    
    
    % increase penalty for positive samples according to invers ratio of
    % their number, i.e., if 1/3 is ratio of positive to negative samples, then
    % impact of positives is 3 the times of negatives
    % 
    b_weightBalancing = getFieldWithDefault ( settings, 'b_weightBalancing', false);
    
    
  
    uniqueLabels = unique ( labels );
    i_numClasses = size ( uniqueLabels,1);
	
    %# train one-against-all models
    svmmodel = cell( i_numClasses,1);
    for k=1:i_numClasses
        yBin        = 2*double( labels == uniqueLabels(k) )-1;
        
        if ( b_weightBalancing )
            fraction = double(sum(yBin==1))/double(numel(yBin));
            libsvm_optionsLocal = sprintf('%s -w1 %f -w-1 1', libsvm_options, 1.0/fraction);
            svmmodel{k}.model = svmtrain( yBin, feat, libsvm_optionsLocal );
        else
            svmmodel{k}.model = svmtrain( yBin, feat, libsvm_options );
        end
        
        %store the unique class label for later evaluations.
        svmmodel{k}.uniqueLabel = uniqueLabels(k);        
    end 
  
end