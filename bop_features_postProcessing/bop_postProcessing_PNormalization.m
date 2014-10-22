%  function [ normalizedFeatures, additionalInfos ] = bop_postProcessing_PNormalization ( varargin )
%  BRIEF: 
%   Non-linear mapping of detection responses via Lp-normalizing every feature vector. 
%   Special cases are p=2 (euclidian norm) and p=1 (sum norm)
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
% author: Alexander Freytag
% date: 29-04-2014 ( dd-mm-yyyy )

function [ normalizedFeatures, additionalInfos ] = bop_postProcessing_PNormalization ( varargin )

    % copy data to preserve all additional information which is not used
    % within this function
    
    myInput = parseInputs(varargin{:});
    
    additionalInfos = getFieldWithDefault ( myInput, 'additionalInfos', [] );
    
    d_p = getFieldWithDefault ( additionalInfos, 'd_p', 2 );

    
    if ( isfield( myInput, 'bopFeatures') )
        % copy data
        bopFeatures = myInput.bopFeatures;        
        
        bopFeatures = bopFeatures./ ...
         repmat ( nthroot(sum( power(bopFeatures,d_p), 2),d_p), [1,size(bopFeatures,2)] );
     
        % format ouput        
        normalizedFeatures = bopFeatures;        
     
        if ( nargout > 1 )
            additionalInfos.d_p = d_p;  
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