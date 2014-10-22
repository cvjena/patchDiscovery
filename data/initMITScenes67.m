function dataset = initMITScenes67( settings )
         
    
    if ( nargin < 1)
        settings = [];
    end

    if ( isfield(  settings, 'noImgPerClass') && ~isempty(settings.noImgPerClass) )
        noImgPerClass = settings.noImgPerClass;
    else
        noImgPerClass = 100;
    end
      
    if ( isfield(  settings, 'noTrainImgPerClass') && ~isempty(settings.noTrainImgPerClass) )
        noTrainImgPerClass = settings.noTrainImgPerClass;
    else
        noTrainImgPerClass = 5;
    end    
    
    if ( isfield(  settings, 'noValImgPerClass') && ~isempty(settings.noValImgPerClass) )
        noValImgPerClass = settings.noValImgPerClass;
    else
        noValImgPerClass = 75;
    end  
    
    if ( isfield(  settings, 'noTestImgPerClass') && ~isempty(settings.noTestImgPerClass) )
        noTestImgPerClass = settings.noTestImgPerClass;
    else
        noTestImgPerClass = 20;
    end    
    
    

    
    if ( isfield(  settings, 'b_writeFilelists') && ~isempty(settings.b_writeFilelists) )
        b_writeFilelists = settings.b_writeFilelists;
    else
        b_writeFilelists = true;
    end    
    
    if ( isfield(  settings, 'trainImgFilelist') && ~isempty(settings.trainImgFilelist) )
        trainImgFilelist = settings.trainImgFilelist;
    else
        trainImgFilelist = 'data/MITScenes67_trainImgs.txt';
    end 
    
    if ( isfield(  settings, 'valImgFilelist') && ~isempty(settings.valImgFilelist) )
        valImgFilelist = settings.valImgFilelist;
    else
        valImgFilelist = 'data/MITScenes67_valImgs.txt';
    end 
    
    if ( isfield(  settings, 'testImgFilelist') && ~isempty(settings.testImgFilelist) )
        testImgFilelist = settings.testImgFilelist;
    else
        testImgFilelist = 'data/MITScenes67_testImgs.txt';
    end     
    
    
    if ( isfield(  settings, 'classIndicesToUse') && ~isempty(settings.classIndicesToUse) )
        classIndicesToUse = settings.classIndicesToUse;
    else
        classIndicesToUse = 1:67;
    end    
    
    
    %%%% for re-using the existing splits provided by Torralba et al.

    if ( isfield(  settings, 'b_useOfficialSplit') && ~isempty(settings.b_useOfficialSplit) )
        b_useOfficialSplit = settings.b_useOfficialSplit;
    else
        b_useOfficialSplit = true;
    end
    
    if ( isfield(  settings, 's_officialSplitTrain') && ~isempty(settings.s_officialSplitTrain) )
        s_officialSplitTrain = settings.s_officialSplitTrain;
    else
        s_officialSplitTrain = 'data/MITScenes67_trainSplit.txt';
    end
    
    if ( isfield(  settings, 's_officialSplitTest') && ~isempty(settings.s_officialSplitTest) )
        s_officialSplitTest = settings.s_officialSplitTest;
    else
        s_officialSplitTest = 'data/MITScenes67_testSplit.txt';
    end    
    
    
    dataset.images = [];
    dataset.labels = [];
    dataset.trainImages = [];
    dataset.valImages = [];
    dataset.testImages = [];

    
    if ( ~b_useOfficialSplit )
        if strcmp( getenv('USER'), 'alex')
            fileListID = fopen('data/filelists_MIT67.txt');
        elseif strcmp( getenv('USER'), 'freytag')
            fileListID = fopen('data/filelists_MIT67.txt');       
        end        
        
        fileLists = textscan(fileListID, '%s');
        fclose(fileListID);

        fileLists = fileLists{1};        

        if ( isfield(  settings, 'noClasses') && ~isempty(settings.noClasses) )
            noClasses = settings.noClasses;
        else
            noClasses = length(fileLists);
        end     
        
        try 
            for clIdx = 1:noClasses

                classFileListID = fopen( fileLists{ classIndicesToUse(clIdx) } );
                classFileList = textscan(classFileListID, '%s');
                fclose(classFileListID);

                classFileList = classFileList{1};

                % append file names of new category
                dataset.images = [ dataset.images; classFileList(1:noImgPerClass) ];

                % append class label of new category
                dataset.labels = [ dataset.labels  classIndicesToUse(clIdx)*ones(1,noImgPerClass ) ] ;

                % append img indices for train, val, and test of new category
                idxClassStart = (clIdx-1)*noImgPerClass+1;

                dataset.trainImages = [ dataset.trainImages idxClassStart:(idxClassStart+noTrainImgPerClass-1) ];
    %             dataset.valImages   = [ dataset.valImages (idxClassStart+noTrainImgPerClass):(idxClassStart+noTrainImgPerClass+noValImgPerClass-1) ];  
    %             dataset.testImages  = [ dataset.testImages (idxClassStart+noTrainImgPerClass+noValImgPerClass):(idxClassStart+noImgPerClass-1) ]; 
                dataset.valImages   = [ dataset.valImages (idxClassStart):(idxClassStart+noValImgPerClass-1) ];  
                dataset.testImages  = [ dataset.testImages (idxClassStart+noValImgPerClass):(idxClassStart+noImgPerClass-1) ]; 
            end

        catch  err
            disp('Error while reading filenames of MITScenes67 dataset - check that your filename file is up to date!');
        end
    else % re-use the existing split provided by Torralba et al.
        if ( isfield(  settings, 'noClasses') && ~isempty(settings.noClasses) )
            noClasses = settings.noClasses;
        else
            noClasses = 67;
        end        
        
        file_trainSplitID = fopen( s_officialSplitTrain );
        officialSplitTrain = textscan(file_trainSplitID, '%s');
        officialSplitTrain = officialSplitTrain{1};
        fclose(file_trainSplitID);
        
        idx = cell2mat( strfind ( [officialSplitTrain], '/' ) );
        idx = idx(:, (size(idx,2)-1):size(idx,2) );
        
        %%%%% DETERMINE CLASS NAMES
        classNames = {};
        
        for i=1:size(idx,1)
             className = officialSplitTrain{i}(idx(i,1):idx(i,2));
             classNames{i} = className;
        end
        
        classNamesUnique = unique( classNames );
        
%         % add a mapping between classnames and class numbers
%         keySet = classNamesUnique;
%         valueSet = 1:length(classNamesUnique);
%         mapObj = containers.Map(keySet,valueSet);
%         dataset.map_cnToClIdx = mapObj;        
%         
%         keySet = 1:length(classNamesUnique);
%         valueSet = classNamesUnique;
%         mapObj = containers.Map(keySet,valueSet);
%         dataset.map_clIdxToCn = mapObj;  
        
        % fixed values for the given split
        noValImgPerClass = 80;
        noTestImgPerClass = 20;
        
        file_testSplitID = fopen( s_officialSplitTest );
        officialSplitTest = textscan(file_testSplitID, '%s');
        officialSplitTest = officialSplitTest{1};
        fclose(file_testSplitID);        
        
        for clIdx = 1:noClasses
            
            classMemberTrain = ~cellfun(@isempty, strfind(officialSplitTrain,classNamesUnique{clIdx}) );
            classMemberTest = ~cellfun(@isempty, strfind(officialSplitTest,classNamesUnique{clIdx}) );
            
            % append file names of new category
            dataset.images = [ dataset.images; officialSplitTrain(classMemberTrain); officialSplitTest(classMemberTest) ];
            
            % append class label of new category
            dataset.labels = [ dataset.labels  classIndicesToUse(clIdx)*ones(1,noValImgPerClass+noTestImgPerClass ) ] ;

            % append img indices for train, val, and test of new category
            idxClassStart = (clIdx-1)*noImgPerClass+1;

            dataset.trainImages = [ dataset.trainImages idxClassStart:(idxClassStart+noTrainImgPerClass-1) ];
            dataset.valImages   = [ dataset.valImages (idxClassStart):(idxClassStart+noValImgPerClass-1) ];
            dataset.testImages  = [ dataset.testImages (idxClassStart+noValImgPerClass):(idxClassStart+noValImgPerClass+noTestImgPerClass-1) ];                     
            
        end
        

            
            
        
        
    end
    
            if ( b_writeFilelists ) 
                try
                    trainFile = fopen(trainImgFilelist,'w');
                    fprintf(trainFile,'%s\n', dataset.images{ dataset.trainImages } );
                    fclose(trainFile);  
                    dataset.trainImgFilelist = trainImgFilelist;

                    valFile = fopen(valImgFilelist,'w');
                    fprintf(valFile,'%s\n', dataset.images{ dataset.valImages } );
                    fclose(valFile);  
                    dataset.valImgFilelist = valImgFilelist;

                    testFile = fopen(testImgFilelist,'w');
                    fprintf(testFile,'%s\n', dataset.images{ dataset.testImages } );
                    fclose(testFile);  
                    dataset.testImgFilelist = testImgFilelist;

                catch err
                    disp('Unable to write filelists for train, val, and test images - sry.');
                end
            end    
    
    
    % add a mapping between filenames and img idx
%     dataset.map_fnToIdx.im = dataset.images;
%     dataset.map_fnToIdx.idx = 1:length(dataset.images);
    
%     keySet = dataset.images;
%     valueSet = 1:length(dataset.images);
%     
%     mapObj = containers.Map(keySet',valueSet);
%     dataset.map_fnToIdx = mapObj;
%     structCell = [keySet valueSet]';
                
end