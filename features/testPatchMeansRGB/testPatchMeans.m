function testPatchMeans ( img )
% function testPatchMeans ( img )
% 
% author: Alexander Freytag
% date  : 11-02-2014 (dd-mm-yyyy)
% 
% BRIEF :
%   Computes patchMean features for a given image using several block
%   sizes. Computations are performed for both possible strategies and
%   runtimes are averaged over 100 repetitions. Resulting runtimes are
%   visualized in a bar plot.
% 
% INPUT :
%    img           --  uint8 gray or color image
% 

    %% (1) check input
    i_numCells = [2,4,8,12,16,20,32,64];
    
    i_numRepetitions = 100;
    
    timesConv  = zeros ( length(i_numCells), 1);
    timesBlock = zeros ( length(i_numCells), 1);
    
    %% (2) compute features    
    
    %default to pre-allocate memory
    settings.i_numCells     = 1;
    settings.b_convolution  = true;
    
    for i = 1:length(i_numCells)
        
        msgIter = sprintf('i_numCells : %f\n', i_numCells(i) );
        disp ( msgIter )
        
        % run mean computation using filtering techniques (convolutions)
        
        settings.b_convolution = true;
        tic;
        for repIdx=1:i_numRepetitions
            settings.i_numCells = i_numCells(i);
            [~] = computePatchMeans ( img, settings );
        end
        
        timesConv(i) = toc()/100;
        
        % now do the same thing for the grid computation solution
        
        settings.b_convolution = false;
        tic;
        for repIdx=1:i_numRepetitions
            settings.i_numCells = i_numCells(i);
            [~] = computePatchMeans ( img, settings );
        end
       
        timesBlock(i) = toc()/100;
        
    end
    
    %% (4) visualize results    
    timesFig = figure;
    s_title = sprintf('Evaluation of PatchMean Computation' );            
    set ( timesFig, 'name', s_title); 
    
    
    times = [ timesConv, timesBlock];
    bar ( i_numCells, times )
    
    xlabel('Number of blocks per dimension');
    ylabel('Runtime');   

    i_fontSizeAxis = 16;
    set(get(gca,'XLabel'), 'FontSize', i_fontSizeAxis);
    set(get(gca,'YLabel'), 'FontSize', i_fontSizeAxis);  
    
    hleg = legend('Convolution','Mean+Reshape', ...
              'Location','North');
    % Make the text of the legend italic and color it brown
    set(hleg,'FontAngle','italic','TextColor',[.3,.2,.1])   
    
    

    %% (5) wait for user input    
    pause
    close ( timesFig );
    

    
    
end