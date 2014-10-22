%  function output = bop_postProcessing_identity ( varargin )
%  BRIEF: 
%   don't do anything at all - default solution
%
%
%  INPUT:
%     - either struct array with optional fields  'bopFeatures',
%     'minVals', 'maxVals'
%     - 2D double array (bopFeatures) and optionally struct additionalInfos
%       including minVals and maxVals as double vectors or corresponding size
% 
%  OUTPUT:
%     - normalizedFeatures
%     - additionalInfos (optional)
% 

function [ normalizedFeatures, additionalInfos ] = bop_postProcessing_identity ( varargin )
    
    myInput = parseInputs(varargin{:});
    
    % nothing to do...
    normalizedFeatures = myInput.bopFeatures;
    if ( nargout > 1 )
        additionalInfos = myInput.additionalInfos;
    end    
end

function myInput = parseInputs(varargin)

    if ( isstruct( varargin{1} ) )
        myInput = varargin{1};
    elseif ( isfloat( varargin{1} ) )
        if ( nargin >= 2 )
            myInput.bopFeatures = varargin{1};
            myInput.additionalInfos = varargin{2};
        else
            myInput.bopFeatures = varargin{1};
            myInput.additionalInfos = [];
        end
    else
        disp('wrong number of input arguments specified!')
    end
end