function evaluateCUB200_kNN_oracle ( settings, meanAccs, meanAccskNN )
% function evaluateCUB200_kNN_oracle ( settings )
% 
% author : Alexander Freytag
% date   : 14-03-2014 ( dd-mm-yyyy )
% 
%  BRIEF:
%    Evaluate exemplar-aspect for fine-grained recognition
% 
%    For different sizes of kNN retrieval, evaluate classification accuracy
%    if i) at least one images has the correct number, and ii) the majority
%    class is correct. 
% 
%    In addition, distribution of classes among retrieval results are 
%    visualized optionally.
% 

    if ( nargin < 1 )
        settings = 0;
    end
    
    % evaluate accuracy for up to 150 neighbors to chose from
    i_maxNumNN = getFieldWithDefault ( settings, 'i_maxNumNN', 150 );
    
    % plot x axis in log scale? Might be useful for larger numbers of K
    b_plotXLog = getFieldWithDefault ( settings, 'b_plotXLog', false );

    
    b_computeClassDistributions = getFieldWithDefault ( settings, 'b_computeClassDistributions', false );
    
    if ( nargin > 1 ) 
        i_maxX = min(i_maxNumNN, size(meanAccs,1) );    
    else
        i_maxX = i_maxNumNN;    
    end
    
    if ( b_computeClassDistributions )
        % class distributions of kNNs
        meanNumClasses = zeros ( i_maxX , 1 );
        stdNumClasses  = zeros ( i_maxX , 1 );
    end
    
    settingsEval.b_computeClassDistributions = b_computeClassDistributions;

    % no visualization meanwhile
    settingsEval.b_showMatching = false;
    
    %%
    % load global variables
    global birdNNMatching;
    if ( isempty( birdNNMatching ) )
        load ( getFieldWithDefault ( settings, 's_nnMatchingFile', ...
                                    '/home/freytag/experiments/2014-03-13-nnMatchingCUB200/200/nnMatchingCUB200.mat'), ...
                                    'birdNNMatching'...
                                  );                       
    end
    
    nrClasses      = birdNNMatching.nrClasses;         
  
    
     
    global datasetCUB200;
    if ( isempty ( datasetCUB200 ) )
        settingsInitCUB.i_numClasses = nrClasses;
        datasetCUB200 = initCUB200_2011 ( settingsInitCUB ) ;
    end
    

    
    %%
    % 
    % if true, oracle scores if at least a single among kNN results is correct
    settingsEval.b_perfectOracle = true;

    % compute results for perfect oracle
    if ( ( nargin < 2 ) || isempty ( meanAccs ) )
        meanAccs = zeros ( i_maxNumNN , 1 );
        for i=1:i_maxNumNN
            settingsEval.i_kNearestNeighbors = i;
            out = CUB200_kNN_oracle ( settingsEval ) ;
            meanAccs(i) = out.meanAcc;
            if ( b_computeClassDistributions )
                meanNumClasses( i ) = out.meanNumClasses;
                stdNumClasses( i )  = out.stdNumClasses;
            end
        end
    end

    % create new figure for plotting results...
    figOracle = figure;

    % ... set a title ...
    s_titleOracle = sprintf('Perfect kNN oracle');
    set ( figOracle, 'name', s_titleOracle);
    
    i_lineWidth = getFieldWithDefault ( settings, 'i_linewidth', 6 );

    % ... and plot results
    plot (    1:i_maxX, meanAccs(1:i_maxX), ...
              'LineWidth',i_lineWidth);
              
    if ( b_plotXLog )
        set(gca,'XScale','log');
    end

    %%

    % if false, 'oracle' scores only if most frequ. class number is correct
    % -> simplest kNN strategy
    settingsEval.b_perfectOracle = false;
    % already done, or not needed anyway
    settingsEval.b_computeClassDistributions = false;

    
    % compute results for majority vote
    if ( ( nargin < 3 ) || isempty ( meanAccskNN ) )
        meanAccskNN = zeros ( i_maxNumNN , 1 );
        
        for i=1:i_maxNumNN
            settingsEval.i_kNearestNeighbors = i;
            out = CUB200_kNN_oracle ( settingsEval ) ;
            meanAccskNN(i) = out.meanAcc;    
        end
    end

    % create new figure for plotting results...
    figkNN = figure;

    % ... set a title ...
    s_titlekNN = sprintf('Standard kNN');
    set ( figkNN, 'name', s_titlekNN);

    % ... and plot results
    plot (      1:i_maxX, meanAccskNN(1:i_maxX), ...
                'LineWidth',i_lineWidth);
            
    if ( b_plotXLog )
        set(gca,'XScale','log');
    end

    %%
    % plot both things into a single figure
    figBoth = figure;
    hold on;

    %plot data
    plot (     1:i_maxX, meanAccs(1:i_maxX),  'r-',  ...
               'LineWidth',i_lineWidth);
    
    
    xlim ( [0.0, (i_maxX+1) ] );
    maxAM = max([meanAccs;meanAccskNN]);
    ylim ( [0.0, 1.05*maxAM     ] );
    
    
    if ( isfield(settings, 'resultsBaseline') )
        % color is magenta
       h_line = line ( [1, i_maxX], [settings.resultsBaseline.value, settings.resultsBaseline.value], 'Color',  [1 0 1], ...
                'LineWidth',i_lineWidth/2, 'LineStyle', '--');
       % bring line to background
       % note: unfortunately, this also effects the order of the legend.
       %uistack(h_line,'bottom') ;
    end       
    
    if ( isfield(settings, 'results') )
        colors = { 'g-','m-' };
        
        for i=1:length(settings.results) 
            plot (      settings.results(i).x, settings.results(i).y,    colors{i}, ...
                        'LineWidth',i_lineWidth);            
        end
    end
    
    plot (    1:i_maxX, meanAccskNN(1:i_maxX),  'b-',  ...
              'LineWidth',i_lineWidth);
    
    if ( b_plotXLog )
        set(gca,'XScale','log');
    end

    

    %% legend
    
    s_legend = {};
    
    
    s_legend = [ s_legend, 'kNN oracle (HOG+CN)' ];
    
    
    if ( isfield(settings, 'resultsBaseline') )        
       s_legend = [ s_legend, settings.resultsBaseline.name ];
    end      
    
    if ( isfield(settings, 'results') )        
        for i=1:length(settings.results)
                s_legend = [ s_legend, settings.results(i).name ];
        end        
    end
        

    
    s_legend = [ s_legend, 'kNN (HOG+CN)' ];
    
    legend ( s_legend', 'Location', 'NorthEast' )

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
    ylabel('ARR [%]');

    i_fontSizeAxis = getFieldWithDefault ( settings, 'i_fontSizeAxis' , 12 );
    set(get(gca,'YLabel'), 'FontSize', i_fontSizeAxis);
    set(get(gca,'XLabel'), 'FontSize', i_fontSizeAxis);
    
    %%
    %
    if ( b_computeClassDistributions )
        figClassDist = figure;
        hold on;

        %plot data
        errorbar( 1:i_maxX, meanNumClasses, stdNumClasses, 'b-' , ...
        'LineWidth',i_lineWidth );

        xlim ( [0.0, (i_maxX+1) ] );
        maxNC = max(meanNumClasses+stdNumClasses);
        ylim ( [0.0, 1.05*maxNC     ] );

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
    
    set(figBoth, 'Position', [1 1 600 450])
    
    s_destination = getFieldWithDefault ( settings, 's_destination', '' );
    
    if ( getFieldWithDefault ( settings, 'b_saveAccuracies', true ) )
        s_filename = sprintf('%saccuracies.mat',s_destination );
        save ( s_filename, 'meanAccs', 'meanAccskNN' );
    end

    if ( getFieldWithDefault ( settings, 'b_saveResultsImage', false ) )
        s_filename = sprintf('%skNN-oracle.eps',s_destination );
        set(figBoth,'PaperPositionMode','auto')
        print(figBoth, '-deps2c', s_filename);
    end
    
    %%%%%%%%%%
    if ( b_computeClassDistributions && ...
         getFieldWithDefault ( settings, 'b_saveAccuracies', true ) ...
        )
        s_filename = sprintf('%sclassDistribution.mat',s_destination );
        save ( s_filename, 'meanNumClasses', 'stdNumClasses' );
    end       
    
    if ( b_computeClassDistributions && ...
         getFieldWithDefault ( settings, 'b_saveResultsImage', false ) ...
        )
        s_filename = sprintf('%skNN-classDistribution.eps',s_destination );
        set(figClassDist,'PaperPositionMode','auto')
        print(figClassDist, '-deps2c', s_filename);
    end
    
 

end


