function plotTimes_patchDiscovery ( results, additionalInfos )

    if ( nargin < 2 )
        additionalInfos = [];
    end

    %% INPUT PARSING

    %%% INTERACTION OPTIONS
  
    if ( ( ~isfield(additionalInfos,'b_closeImg'))  || isempty(additionalInfos.b_closeImg) )
        b_closeImg = true;
    else
        b_closeImg = additionalInfos.b_closeImg;
    end    
    
    if ( ( ~isfield(additionalInfos,'b_doPause'))  || isempty(additionalInfos.b_doPause) )
        b_doPause = true;
    else
        b_doPause = additionalInfos.b_doPause;
    end
    
    %%% PRINT FIGURE TO FILE OPTIONS
    if ( ( ~isfield(additionalInfos,'b_printEPS'))  || isempty(additionalInfos.b_printEPS) )
        b_printEPS = true;
    else
        b_printEPS = additionalInfos.b_printEPS;
    end  
    
    if ( ( ~isfield(additionalInfos,'b_printFIG'))  || isempty(additionalInfos.b_printFIG) )
        b_printFIG = true;
    else
        b_printFIG = additionalInfos.b_printFIG;
    end
    
    if ( ( ~isfield(additionalInfos,'b_printPNG'))  || isempty(additionalInfos.b_printPNG) )
        b_printPNG = true;
    else
        b_printPNG = additionalInfos.b_printPNG;
    end
    
    if ( ( ~isfield(additionalInfos,'s_destination'))  || isempty(additionalInfos.s_destination) )
        s_destination = 'times';
    else
        s_destination = additionalInfos.s_destination;
    end
    
    
    %%% FIGURE SPECIFICATIONS
    if ( ( ~isfield(additionalInfos,'s_title'))  || isempty(additionalInfos.s_title) )
        s_title = 'Time for patch discovery';
    else
        s_title = additionalInfos.s_title;
    end    
    
    %% MAIN PLOTTING STUFF
    
    timeFig = figure ( );
    set ( timeFig, 'name', s_title);
    
    title( s_title ); 
    
    hold on;    
  
    
    c{1} = 'r';
    c{2} = 'g';
    c{3} = 'b';
    
    N = length(results.timesPatchDiscovery.expansion)+2;

    % Seeding
    h = bar ( 1, results.timesPatchDiscovery.seeding, c{1});
    
    % Expansion
    h = bar ( 2:(length(results.timesPatchDiscovery.expansion)+1), results.timesPatchDiscovery.expansion, c{2} );
    
    %Selection
    h = bar ( N, results.timesPatchDiscovery.selection, c{3});

    xlim([0 N+1]);
    if ( ( isfield(additionalInfos,'ylim'))  && ~isempty(additionalInfos.ylim) )
        ylim( additionalInfos.ylim );
    end
    
    names { 2 }  = 'Seeding';
    names { round(N/2)+1 }  = 'Expansion';    
    names { N+1 }  = 'Selection';
    set(gca, 'XTickLabel', names)  
    
    
    
    
    %% POST-PROCESSING
    
    %wait for user response and close everything before
    %continuing
    if ( b_doPause )
        pause;
    end
    
    if ( b_printEPS )
        print( timeFig, '-depsc2', s_destination);
    end
    
    if ( b_printFIG )
        saveas(  timeFig, s_destination, 'fig')
    end    
    
    if ( b_printPNG )
        saveas(  timeFig, s_destination, 'png')
    end     
    
    if ( b_closeImg )
        close(timeFig);
    end

end