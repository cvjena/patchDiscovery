function hogFeature = computeHOGs_FFLD  ( img, settings )
%%TODO docu

    %% (1) check input
    if ( ( nargin < 2 ) || ...
         ( isempty (settings) ) || ...
         ( ~isstruct ( settings ) ) || ...
         ( ~isfield(settings, 'numHOGCells')  )...
       )
        numHOGCells = 8;
    else
        numHOGCells = settings.numHOGCells;
    end
    
    %% (2) compute features
    [height,~,~] = size ( img );
    if ( ndims(img) == 3 )
        hogFeature = hog_features_ffld( repmat(img,[1,1,3]), 1, height/numHOGCells );
    else
        hogFeature = hog_features_ffld( img, 1, height/numHOGCells );
    end  

%     n = length(blocks);
%        
%     for i=n:-1:1 
%         [height,~,~] = size ( blocks{i} );
%         
%         if ( length(size(blocks{i})) == 2)
%             feature = hog_features_ffld(repmat(blocks{i},[1,1,3]), 1, height/8);
%         else
%             feature = hog_features_ffld(blocks{i}, 1, height/8);
%         end
%         hogFeatures(i).feature = feature;
%     end
end