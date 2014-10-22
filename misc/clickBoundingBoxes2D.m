function [X1,Y1,X2,Y2]=clickBoundingBoxes2D( i_maxNoBBs )
% function [X,Y]=clickBoundingBoxes2D( i_maxNoBBs )
% 
% date: 04-02-2014 (dd-mm-yyyy)
% author: Alexander Freytag
    
    %% check inputs and default arguments
    
    if ( nargin < 1 )
        i_maxNoBBs = Inf;
    end

    X1 = [];
    Y1 = [];
    X2 = [];
    Y2 = [];
    
    keydown = 0;
    
    %% start clicking
    
    statusMsg = sprintf( ' --- Start clicking bounding box points! ---' );
    disp(statusMsg);      
    while ( size( X1, 1 ) < i_maxNoBBs ), 
        
       
        [X12,Y12, b_success]=clickPoints2D( 2 ); % we need two points for a bounding box
        

        
        % check whether input is valid
        if ( b_success )
            
            xl = min ( X12(1,1) , X12(2,1) );
            xr = max ( X12(1,1) , X12(2,1) );
            width  = xr - xl;
            
            yl = min ( Y12(1,1) , Y12(2,1) );
            yr = max ( Y12(1,1) , Y12(2,1) );
            height = yr - yl;
            
            % we currently only accept squared regions, so we take the
            % small size
            smallDim = min ( width, height);
            xr = xl + smallDim;
            yr = yl + smallDim;
            
            X1 = [ X1; xl ];
            Y1 = [ Y1; yl ];
            X2 = [ X2; xr ];
            Y2 = [ Y2; yr ];            
            
            hold on;
            line([xl xl xr  xr  xl]',[yl yr yr yl yl]','color','r','linewidth',5);
            hold off;         
        else
            % break clicking loop
            break;
        end
        
    end
end