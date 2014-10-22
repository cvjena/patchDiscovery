function dataset = initArtMultiClass( settings )
         
    
    if ( nargin < 1)
        settings = [];
    end

    if ( isfield(  settings, 'i_noImgPerClass') && ~isempty(settings.i_noImgPerClass) )
        i_noImgPerClass = settings.i_noImg;
    else
        i_noImgPerClass = 20;
    end
      
    if ( isfield(  settings, 'i_noTrainImgPerClass') && ~isempty(settings.i_noTrainImgPerClass) )
        i_noTrainImgPerClass = settings.i_noTrainImgPerClass;
    else
        i_noTrainImgPerClass = 5;
    end    
    
    if ( isfield(  settings, 'i_noValImgPerClass') && ~isempty(settings.i_noValImgPerClass) )
        i_noValImgPerClass = settings.i_noValImg;
    else
        i_noValImgPerClass = 5;
    end  
    
    if ( isfield(  settings, 'i_noTestImgPerClass') && ~isempty(settings.i_noTestImgPerClass) )
        i_noTestImgPerClass = settings.i_noTestImg;
    else
        i_noTestImgPerClass = 10;
    end    
    
    

    
    if ( isfield(  settings, 'b_writeFilelists') && ~isempty(settings.b_writeFilelists) )
        b_writeFilelists = settings.b_writeFilelists;
    else
        b_writeFilelists = true;
    end    
    
    if ( isfield(  settings, 'trainImgFilelist') && ~isempty(settings.trainImgFilelist) )
        trainImgFilelist = settings.trainImgFilelist;
    else
        trainImgFilelist = 'data/art_mc_trainImgs.txt';
    end 
    
    if ( isfield(  settings, 'valImgFilelist') && ~isempty(settings.valImgFilelist) )
        valImgFilelist = settings.valImgFilelist;
    else
        valImgFilelist = 'data/art_mc_valImgs.txt';
    end 
    
    if ( isfield(  settings, 'testImgFilelist') && ~isempty(settings.testImgFilelist) )
        testImgFilelist = settings.testImgFilelist;
    else
        testImgFilelist = 'data/art_mc_testImgs.txt';
    end     
    
    if ( isfield(  settings, 'classIndicesToUse') && ~isempty(settings.classIndicesToUse) )
        classIndicesToUse = settings.classIndicesToUse;
    else
        classIndicesToUse = 1:5;
    end       
  
    
    
    
    
    dataset.images = [];
    dataset.labels = [];
    dataset.trainImages = [];
    dataset.valImages = [];
    dataset.testImages = [];
      

    if strcmp( getenv('USER'), 'alex')
        fileListID = fopen('data/filelist_artificialArt.txt');
    elseif strcmp( getenv('USER'), 'freytag')
        fileListID = fopen('/home/freytag/data/artificialArt/multiClass/filelistArtificalArt.txt');       
    end

    classFileList = textscan(fileListID, '%s');
    fclose(fileListID);
    fileLists = classFileList{1};

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
            
            % append file names
            dataset.images = [ dataset.images; classFileList(1:i_noImgPerClass)];

            % we have no real class labels here
            dataset.labels = [ dataset.labels  classIndicesToUse(clIdx)*ones(1,i_noImgPerClass ) ] ;

            % append img indices for train, val, and test of new category
            idxClassStart = (clIdx-1) * i_noImgPerClass + 1;

            dataset.trainImages = [ dataset.trainImages  ...
                                    idxClassStart   : ...
                                    ( idxClassStart + i_noTrainImgPerClass-1) ...
                                  ];
                              
            dataset.valImages   = [ dataset.valImages  ...
                                    ( idxClassStart ) : ...
                                    ( idxClassStart + i_noValImgPerClass-1  ) ...
                                  ];  
                              
            dataset.testImages  = [ dataset.testImages ...
                                    ( idxClassStart + i_noValImgPerClass) : ...
                                    (idxClassStart+i_noImgPerClass-1) ...
                                  ]; 
        end

    catch  err
        disp('Error while reading filenames of artificial art multi class dataset - check that your filename file is up to date!');
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
    
    
                
end