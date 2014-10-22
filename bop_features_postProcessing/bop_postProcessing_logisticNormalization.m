%  function [ normalizedFeatures, additionalInfos ] = bop_postProcessing_logisticNormalization ( varargin )
%  BRIEF: 
%   non-linear mapping of detection responses for training images to [0, +1]
%    -> normalize scores by applying a logistic function:
%         x' = 1 / ( 1 + exp ( sigma * x ) )
%
%
%  INPUT:
%     - either struct array with optional fields  'bopFeatures', 'additionalInfos'
%                  or 
%     - 2D double array (bopFeatures) and optionally additionalInfos
% 
%  OUTPUT:
%     - normalizedFeatures
%     - additionalInfos (optional)
% 
%  author: Alexander Freytag
%  date: 29-04-2014 ( dd-mm-yyyy, last updated )

function [ normalizedFeatures, additionalInfos ] = bop_postProcessing_logisticNormalization ( varargin )

    % copy data to preserve all additional information which is not used
    % within this function
    
    myInput = parseInputs(varargin{:});
    
    additionalInfos = getFieldWithDefault ( myInput, 'additionalInfos', [] );
    
    d_sigma = getFieldWithDefault ( additionalInfos, 'd_sigma', 0.2 );

    if ( isfield( myInput, 'bopFeatures') )
        
        % copy data
        bopFeatures = myInput.bopFeatures;

        % apply post-processing
        bopFeatures = 1.0 ./ ( 1 + exp(-d_sigma .*bopFeatures) );
        
        % format ouput        
        normalizedFeatures = bopFeatures;   
        
        if ( nargout > 1 )
            additionalInfos.d_sigma = d_sigma;  
        end        
        
    else
        disp ( 'PostProcessing not possible, since no BoP-Features have been computed.')
    end
end

function myInput = parseInputs(varargin)

    if ( isstruct( varargin{1} ) )
        myInput = varargin{1};  
    elseif ( isfloat( varargin{1} ) )
        if ( nargin >= 2 )
            myInput.bopFeatures     = varargin{1};
            myInput.additionalInfos = varargin{2};
        else
            myInput.bopFeatures = varargin{1};
        end
    else
        disp('wrong number of input arguments specified!')
    end
end