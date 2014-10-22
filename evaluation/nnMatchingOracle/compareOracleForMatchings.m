function compareOracleForMatchings ( settings )
% function compareOracleForMatchings ( settings )
% 
% author : Alexander Freytag
% date   : 03-04-2014 ( dd-mm-yyyy )
% 
%  BRIEF:
%    Compare two kNN retrieval results in a oracle classification setting.
%    See evaluateCUB200_kNN_oracle for details how to compute oracle
%    results for a single matching scheme.
% 

    
    matching1 = load ( settings.s_nnMatchingFile1 );
    matching2 = load ( settings.s_nnMatchingFile2 );
    
    if ( isfield ( settings, 's_nnMatchingClassDistFile1') )
        classDist1 = load ( settings.s_nnMatchingClassDistFile1 );
        classDist2 = load ( settings.s_nnMatchingClassDistFile2 );    
    end
    
    i_maxNumNN = size(matching1.meanAccs,1);
    
    % create new figure for plotting results...
    figOracle = figure;
    
    % ... set a title ...
    s_titleOracle = sprintf('Perfect kNN oracle');
    set ( figOracle, 'name', s_titleOracle);
    
    i_lineWidth = getFieldWithDefault ( settings, 'i_linewidth', 6 );

    % ... and plot results
    plot ( 1:i_maxNumNN, matching1.meanAccs, 'r--' , ...
        'LineWidth',i_lineWidth);
    hold on;
    plot ( 1:i_maxNumNN, matching2.meanAccs,  'rx-', ...
        'LineWidth',i_lineWidth);
    
    %legend
    legend ( 'matching 1', 'matching 2',  'Location', 'East' )          

    %%

    % if false, 'oracle' scores only if most frequ. class number is correct
    % -> simplest kNN strategy


    % create new figure for plotting results...
    figkNN = figure;
    
    % ... set a title ...
    s_titlekNN = sprintf('Standard kNN');
    set ( figkNN, 'name', s_titlekNN);

    % ... and plot results
    plot ( 1:i_maxNumNN, matching1.meanAccskNN, 'r--' , ...
        'LineWidth',i_lineWidth);
    hold on;
    plot ( 1:i_maxNumNN, matching2.meanAccskNN,  'rx' , ...
        'LineWidth',i_lineWidth);   
    
    %legend
    legend ( 'matching 1', 'matching 2',  'Location', 'East' )    


    %%
    % plot both things into a single figure
    figBoth = figure;
    hold on;

    %plot data
    plot ( 1:i_maxNumNN, matching1.meanAccs,    'r--' , ...
        'LineWidth',i_lineWidth);
    plot ( 1:i_maxNumNN, matching1.meanAccskNN, 'b--' , ...
        'LineWidth',i_lineWidth);
    
    plot ( 1:i_maxNumNN, matching2.meanAccs,    'rx-' , ...
        'LineWidth',i_lineWidth);
    plot ( 1:i_maxNumNN, matching2.meanAccskNN, 'bx-', ...
        'LineWidth',i_lineWidth);   
    
    xlim ( [0.0, (i_maxNumNN+1) ] );
    maxAM = max([matching1.meanAccs;matching1.meanAccskNN;matching2.meanAccs;matching2.meanAccskNN]);
    ylim ( [0.0, 1.05*maxAM     ] );
    

    %legend
    legend ( 'kNN oracle HOG', 'plain kNN HOG', 'kNN oracle HOG+CN', 'plain kNN HOG+CN', 'Location', 'East' )

    %title
    s_titleBoth = sprintf('kNN results');
    set ( figBoth, 'name', s_titleBoth);

    % size for ticks (and legend)
    i_fontSize = getFieldWithDefault ( settings, 'i_fontSize' , 12 );
    text_h     =findobj(gca,'type','text');  
    set(text_h,'FontSize',i_fontSize);
    set(gca, 'FontSize', i_fontSize);


    % labels of axis
    xlabel('k for kNN matching');
    ylabel('mA [%]');

    i_fontSizeAxis = getFieldWithDefault ( settings, 'i_fontSizeAxis' , 16 );
    set(get(gca,'YLabel'), 'FontSize', i_fontSizeAxis);
    set(get(gca,'XLabel'), 'FontSize', i_fontSizeAxis);
    
    %%
    %
    if ( exist( 'classDist1', 'var') )
        figClassDist = figure;
        hold on;

        %plot data
        errorbar( 1:i_maxNumNN, classDist1.meanNumClasses, classDist1.stdNumClasses, 'r--' , ...
        'LineWidth',i_lineWidth-4); 
        hold on;
        errorbar( 1:i_maxNumNN, classDist2.meanNumClasses, classDist2.stdNumClasses, 'bx-' , ...
        'LineWidth',i_lineWidth-4); 

        xlim ( [0.0, (i_maxNumNN+1) ] );
        maxNC = max([classDist1.meanNumClasses+classDist1.stdNumClasses; classDist2.meanNumClasses+classDist2.stdNumClasses]);
        ylim ( [0.0, 1.05*maxNC     ] );
        
        %legend
        legend ( 'matching 1', 'matching 2',  'Location', 'East' )        

        %title
        s_titleClassDist = sprintf('Class distribution among kNNs');
        set ( figClassDist, 'name', s_titleClassDist);

        % size for ticks (and legend)
        i_fontSize = 12;
        text_h     =findobj(gca,'type','text');  
        set(text_h,'FontSize',i_fontSize);
        set(gca, 'FontSize', i_fontSize);


        % labels of axis
        xlabel('k for kNN matching');
        ylabel('No diff. classes');

        i_fontSizeAxis = 16;
        set(get(gca,'YLabel'), 'FontSize', i_fontSizeAxis);
        set(get(gca,'XLabel'), 'FontSize', i_fontSizeAxis);
                
    end    
    
    
    %%
    % output
    
    s_destination = getFieldWithDefault ( settings, 's_destination', '' );
    

    if ( getFieldWithDefault ( settings, 'b_saveResultsImage', false ) )
        s_filename = sprintf('%skNN-oracle-comparison.eps',s_destination );
        set(figBoth,'PaperPositionMode','auto')
        print(figBoth, '-deps2c', s_filename);
    end
    
    if ( exist('figClassDist', 'var') && getFieldWithDefault ( settings, 'b_saveResultsImage', false ) )
        s_filename = sprintf('%skNN-classDistribution-comparison.eps',s_destination );
        set(figClassDist,'PaperPositionMode','auto')
        print(figClassDist, '-deps2c', s_filename);        
    end
    

end