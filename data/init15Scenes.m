function dataset = init15Scenes( settings )
         
   if strcmp( getenv('USER'), 'alex')
       fileListID = fopen('data/15Scenes.txt');
   elseif strcmp( getenv('USER'), 'freytag')
       fileListID = fopen('data/15ScenesPollux.txt');       
   end
    
    fileLists = textscan(fileListID, '%s');
    fclose(fileListID);

    fileLists = fileLists{1};
    
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
        noTrainImgPerClass = 64;
    end    
    
    if ( isfield(  settings, 'noValImgPerClass') && ~isempty(settings.noValImgPerClass) )
        noValImgPerClass = settings.noValImgPerClass;
    else
        noValImgPerClass = 16;
    end  
    
    
    if ( isfield(  settings, 'noClasses') && ~isempty(settings.noClasses) )
        noClasses = settings.noClasses;
    else
        noClasses = length(fileLists);
    end 
    
    if ( isfield(  settings, 'b_writeFilelists') && ~isempty(settings.b_writeFilelists) )
        b_writeFilelists = settings.b_writeFilelists;
    else
        b_writeFilelists = true;
    end    
    
    if ( isfield(  settings, 'trainImgFilelist') && ~isempty(settings.trainImgFilelist) )
        trainImgFilelist = settings.trainImgFilelist;
    else
        trainImgFilelist = 'data/15Scenes_trainImgs.txt';
    end 
    
    if ( isfield(  settings, 'valImgFilelist') && ~isempty(settings.valImgFilelist) )
        valImgFilelist = settings.valImgFilelist;
    else
        valImgFilelist = 'data/15Scenes_valImgs.txt';
    end 
    
    if ( isfield(  settings, 'testImgFilelist') && ~isempty(settings.testImgFilelist) )
        testImgFilelist = settings.testImgFilelist;
    else
        testImgFilelist = 'data/15Scenes_testImgs.txt';
    end     
    
    
    if ( isfield(  settings, 'classIndicesToUse') && ~isempty(settings.classIndicesToUse) )
        classIndicesToUse = settings.classIndicesToUse;
    else
        classIndicesToUse = 1:15;
    end    
    
    
    dataset.images = [];
    dataset.labels = [];
    dataset.trainImages = [];
    dataset.valImages = [];
    dataset.testImages = [];

    
    
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
        
    catch  err
        disp('Error while reading filenames of 15 Scenes dataset - check that your filename file is up to date!');
    end
    
    
    % add a mapping between filenames and img idx
    keySet = dataset.images;
    valueSet = 1:length(dataset.images);
    mapObj = containers.Map(keySet,valueSet);
    dataset.map_fnToIdx = mapObj;
                
end