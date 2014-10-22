function [X,Y,b_success]=clickPoints2D( i_maxNoClicks, style )
% function [X,Y,b_success]=clickPoints2D( i_maxNoClicks, style )
% 
% date: 04-02-2014 (dd-mm-yyyy)
% author: Alexander Freytag
    
    %% check inputs and default arguments
    if ( nargin < 1 )
        i_maxNoClicks = Inf;
    end
    
    if ( nargin < 2 )
        % default for plotting clicked points
        style='bx'; 
    end    

    XY=[];
    keydown = 0;
    
    if ( nargout > 2 )
        b_success = true;
    end
    
    %% start clicking
    while ( size( XY, 1 ) < i_maxNoClicks ), 
        % grep point from current figure by clicking
        p=ginput(1); 
        
        % check whether input is valid
        if keydown==0 && ~isempty(p)
            
            % append point to point list
            XY = [XY; p(1),p(2)];
            
            % plot point to figure
            hold on ;
            plot(p(1),p(2),style,'MarkerSize',8,'LineWidth',1); 
            hold off ;
        else
            % break clicking loop
            if ( nargout > 2 )
                b_success = false;
            end
            
            break;
        end; 
    end
    
    %% final formatting of outputs
    if ( ~isempty( XY ) ) 
        X=XY(:,1);
        Y=XY(:,2);
    else
        X = [];
        Y = [];
    end
end