function blockProposals = convolutionFFLD ( settingsExpansionSelection, dataset, patches )  
% function blockProposals = convolutionFFLD ( settingsExpansionSelection, dataset, patches )  
% 
%  BRIEF: 
%       we call the external (FFLD) convolution solution, which should be much faster
%       additionally, we support parallelization using SLURM
% 
% author: Alexander Freytag
% date:   05-02-2014 (dd-mm-yyyy)


    %% ( 0 ) init output data
    blockProposals( length( patches ) ) = struct();
    blockProposals(1).proposals = struct ('score',{}, 'box',{} , 'imgIdx',{} , 'feature',{});



    % this is the place we write the current patch models to
    s_modelDir = settingsExpansionSelection.s_modelDir;

    % create folder for tmp model exchange if necessary
    if ( exist(s_modelDir, 'dir') == 0 )
        mkdir ( s_modelDir );
    end        
    
    b_rerun = true;
    
    if ( b_rerun )
        % remove stuff that might be in there from previous iterations
        % and/or runs
        fileWildcard = sprintf('%smodel*.txt*' ,s_modelDir);
        delete( fileWildcard );
    end


    % convert every patch model into binary format and write it on disk
    if ( b_rerun) 
        for i=1:length(patches)

            %only run convolutions for non-converged patches
            if ( patches(i).isConverged )
                continue;
            end
            modelfile = sprintf('%s/model%07d.txt', s_modelDir, i);
            convertwhomodel( patches(i).model, modelfile );
        end
    end

    % specify on which images we want to run the fast convolution
    imglist = dataset.trainImgFilelist;

    % this is the place we expect the fast conv output to be located
    s_convolutionResultDir = settingsExpansionSelection.s_convolutionResultDir;        

    b_useSLURM = settingsExpansionSelection.b_useSLURM;
    
    if ( b_useSLURM )         


        % how many batch jobs do we want to run in parallel?
        i_numberBatches = settingsExpansionSelection.i_numberBatches;

        s_excludeNodes =  settingsExpansionSelection.s_excludeNodes;
        s_partition = settingsExpansionSelection.s_partition;
        b_singleNodePerTask = settingsExpansionSelection.b_singleNodePerTask;

        % call the fast convolution
         syscall = sprintf ('sh ./clusterdetect/perform_detection_fsu.sh %s %s %s %d %s %s %d', ...
            s_modelDir, imglist , s_convolutionResultDir, i_numberBatches, s_excludeNodes, s_partition,  uint8(b_singleNodePerTask) );
%         [status, result] = system(syscall);
%         tic

        if ( b_rerun )
            system(syscall);
        end
%         toc

    else % don't use SLURM - run everything on your local machine only!

        s_detectDir = '/home/freytag/code/detection/ffld/detect';


        tic
        if ( b_rerun )           

            for i=1:length(patches)    
                %only run convolutions for non-converged patches
                if ( patches(i).isConverged )
                    continue;
                end                    

                syscall = sprintf ('%s %s/model%07d.txt %s %s/model%07d.txt.results 1 &> /dev/null', ...
                s_detectDir, s_modelDir, i, imglist , s_convolutionResultDir, i);        

                system(syscall);
                %disp( syscall )
            end
        end
        toc            

    end



    % read results from disk
    for i=1:length(patches)

        %we only ran convolutions for non-converged patches
        if ( patches(i).isConverged )
            continue;
        end             


        resultfile = sprintf('%s/model%07d.txt.results', s_convolutionResultDir, i );

        %%%% remove lines containing less or more then 7 columns (might
        %%%% occure due to writing problems in parallelization mode)
        %%%syscall = sprintf ('awk ''NF==7 {print $0}'' %s &> %sCleared', resultfile, resultfile);
        %%%system(syscall);
        %%%syscall = sprintf ('mv %sCleared %s', resultfile, resultfile);
        %%%system(syscall);            

        % read boxes with image filenames and scores ....           
        idResultsFile = fopen( resultfile );
        results = textscan(idResultsFile, '%s %s %f %d %d %d %d');
        fclose(idResultsFile);


        if ( settingsExpansionSelection.b_debug )
            for tmpIdx=1: length(results{1})

                % create new figure
                figResponse=figure; 
                % set title indicating current dimension
                s_titleResponse = sprintf('Response %d -- score %f', tmpIdx, results{3}(tmpIdx)  );
                set ( figResponse, 'name', s_titleResponse);        

                % plot tackled image 
                tmpImg = readImage( results{1}{tmpIdx} );
                if ( ndims ( tmpImg ) == 2)
                    tmpImg = repmat ( tmpImg, [1,1,3] );
                end
                imagesc( tmpImg );
                x1 = results{4}(tmpIdx);
                x2 = results{5}(tmpIdx);
                y1 = results{6}(tmpIdx);
                y2 = results{7}(tmpIdx);
                line([x1 x1 x2 x2 x1]',[y1 y2 y2 y1 y1]','Color','r','linewidth',1);



                % wait for user input 

                pause; 

                % close current figure and switch to next dimension
                close(figResponse);
            end
        end

%             imgFolderToReplace = '';
%             imgFolderReplacement = '';            
%             if ( ~isempty ( imgFolderReplacement) )
%                 %search for directory separators
%                 k = strfind(results{1}{1}, '/');
%                 
%                 % take the one before the last one
%                 endIdx = k ( length(k) - 1 );
%                 firstFile = results{1}{1};
%                 imgFolderToReplace =  firstFile(1:endIdx);
%                 
%                 % do the same for the original images
%                 k = strfind(patches(i).blocksInfo(1).box.im, '/');
%                 
%                 endIdx = k ( length(k) - 1 );
%                 firstFile = patches(i).blocksInfo(1).box.im;
%                 imgFolderReplacement =  firstFile(1:endIdx);                
%             end

        % TODO : check whether it is useful to do this, or if we could
        % do this more efficiently by just considering some indices...
        % first of all, check which of the responses have larger scores
        % than our currently used blocks
        scoreAccept = (results{3} > patches(i).minScore);

        % then copy all 7 entries accordingly
        for tmpIdx=1:7
            results{tmpIdx} = results{tmpIdx}(scoreAccept);            
        end



        % if we have more than K results, let's take the top K only,
        % that DO NOT overlap


        blockProposals(i).proposals = getTopKNotOverlappingResponsesFFLDOutput ( results, ...
                settingsExpansionSelection.i_K, ...
                settingsExpansionSelection.d_thrOverlap );

        for cnt=1:length( blockProposals(i).proposals )  
             blockProposals(i).proposals(cnt).imgIdx = ...
                  find(strcmp(dataset.images, blockProposals(i).proposals(cnt).box.im ));
        end


%             startLoop = min(length(results{1}), settingsExpansionSelection.i_K );
%             
%             % and store it in our data structure
%             for resIdx=startLoop:-1:1
%                 blockProposals(i).proposals(resIdx).score = results{3}( perm(resIdx) );
%                 
%                 box.im = results{1}{perm(resIdx) };
%                 % correct img filenames accordingly
%                 box.im = strrep(box.im, imgFolderToReplace, imgFolderReplacement);    
%                 
%                 box.x1 = results{4}(perm(resIdx) );
%                 box.y1 = results{5}(perm(resIdx) );
%                 box.x2 = results{6}(perm(resIdx) );
%                 box.y2 = results{7}(perm(resIdx) );
%                 
%                 blockProposals(i).proposals(resIdx).box = box;
%                 
%                 blockProposals(i).proposals(resIdx).imgIdx = patches(i).blocksInfo(1).imgIdx;
%                 
%                 blockProposals(i).proposals(resIdx).feature = [];
%             end
    end
end
