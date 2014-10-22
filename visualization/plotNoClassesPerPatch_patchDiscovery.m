function plotNoClassesPerPatch_patchDiscovery ( results, additionalInfos )

    if ( nargin < 2 )
        additionalInfos = [];
    end

    %% INPUT PARSING
    
    if ( ( ~isfield(results,'patches'))  || isempty(results.patches) )
        patches = [results];
    else
        patches = results.patches;
    end     

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
        s_destination = 'noClassesPerPatch';
    else
        s_destination = additionalInfos.s_destination;
    end    
    
    
    %%% FIGURE SPECIFICATIONS
    if ( ( ~isfield(additionalInfos,'s_title'))  || isempty(additionalInfos.s_title) )
        s_title = 'No. of Classes per Patch';
    else
        s_title = additionalInfos.s_title;
    end    
    
    
    %% MAIN PLOTTING STUFF
    blockDistrFig = figure ( );
    set ( blockDistrFig, 'name', s_title);
    
    title( s_title ); 
    
    hold on;    
    
    maxNumber = 0;
    
    for idx=1:length(patches)
        number = length(patches(idx).label);
        
        if ( number > maxNumber ) 
            maxNumber = number;
        end
    end    
    
    numbers = zeros(maxNumber,1);
    
    for idx=1:length(patches)
        number = length(patches(idx).label);
        numbers(number) = numbers(number)+1;
    end
  
     bar ( numbers );
    
    %% POST-PROCESSING
    
    %wait for user response and close everything before
    %continuing
    if ( b_doPause )
        pause;
    end
    
    if ( b_printEPS )
        print( blockDistrFig, '-depsc2', s_destination);
    end
    
    if ( b_printFIG )
        saveas(  blockDistrFig, s_destination, 'fig')
    end    
    
    if ( b_printPNG )
        saveas(  blockDistrFig, s_destination, 'png')
    end    
    
    
    
    if ( b_closeImg )
        close(blockDistrFig);
    end

end