%  function [ normalizedFeatures, additionalInfos ] = bop_postProcessing_linDetNorm ( varargin )
%  BRIEF: 
%   linear mapping of detection responses for training images to [i_newMin, i_newMax]
%    -> normalize scores by dividing every detector output by its max
%    range, if no range is explicitely specified
%
%  NOTE: mapping to values out of [i_newMin, i_newMax] is possible for images disjoint
%       from training set. Default for [i_newMin, i_newMax] is [-1,+1].
%
%  INPUT:
%     - either struct array with optional fields  'bopFeatures',
%     'minVals', 'maxVals', 'i_newMin', 'i_newMax'
%     - 2D double array (bopFeatures) and optionally struct additionalInfos
%       including minVals and maxVals as double vectors or corresponding size
% 
%  OUTPUT:
%     - normalizedFeatures
%     - additionalInfos (optional)
% 
%  author: Alexander Freytag
%  date: 29-04-2014 ( dd-mm-yyyy, last updated )

function [ normalizedFeatures, additionalInfos ] = bop_postProcessing_linDetNorm ( varargin )
   
    myInput = parseInputs(varargin{:});
    
    if ( nargout > 1 )
        additionalInfos = [];
    end

    if ( isfield( myInput, 'bopFeatures') )
        % copy data
        bopFeatures = myInput.bopFeatures;
        
        % compute parameters if needed
        if ( ~isfield( myInput.additionalInfos, 'minVals') || ...
            ( isempty (myInput.additionalInfos.minVals) )  || ...
            ( size(myInput.additionalInfos.minVals,2) ~= size(bopFeatures,2) ) ...
           )
            [minVals, ~] = min( bopFeatures );   
        else
            minVals = myInput.additionalInfos.minVals;
        end
        
        if ( ~isfield( myInput.additionalInfos, 'maxVals') || ...
            ( isempty (myInput.additionalInfos.maxVals) )  || ...
            ( size(myInput.additionalInfos.maxVals,2) ~= size(bopFeatures,2) ) ...
           )
            [maxVals, ~] = max( bopFeatures );
        else
            maxVals = myInput.additionalInfos.maxVals;            
        end
        
        i_newMin = getFieldWithDefault ( myInput.additionalInfos, 'i_newMin', -1 );
        i_newMax = getFieldWithDefault ( myInput.additionalInfos, 'i_newMax', 1 );
        
        

        % apply post-processing
        subtrMin = bsxfun ( @minus, bopFeatures, minVals);

        % map old scores to [i_newMin, i_newMax] for every dimension
        scalingFactor = repmat( (i_newMax-i_newMin), [1,size(maxVals,2)])./(maxVals-minVals);
        bopFeatures = bsxfun ( @times,  subtrMin,  scalingFactor ) + i_newMin; 

        
        % format ouput
        normalizedFeatures = bopFeatures;
        
        if ( nargout > 1 )
            additionalInfos.minVals  = minVals;
            additionalInfos.maxVals  = maxVals; 
            additionalInfos.i_newMin = i_newMin;
            additionalInfos.i_newMax = i_newMax;             
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