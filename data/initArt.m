function dataset = initArt( settings )
         
   if strcmp( getenv('USER'), 'alex')
       fileListID = fopen('data/filelist_artificialArt.txt');
   elseif strcmp( getenv('USER'), 'freytag')
       fileListID = fopen('/users/tmp/freytag/data/artificialArt/filelist_artificialArt.txt');       
   end
    

    
    if ( nargin < 1)
        settings = [];
    end

    if ( isfield(  settings, 'i_noImg') && ~isempty(settings.i_noImg) )
        i_noImg = settings.i_noImg;
    else
        i_noImg = 100;
    end
      
    if ( isfield(  settings, 'i_noTrainImg') && ~isempty(settings.i_noTrainImg) )
        i_noTrainImg = settings.i_noTrainImg;
    else
        i_noTrainImg = 10;
    end    
    
    if ( isfield(  settings, 'i_noValImg') && ~isempty(settings.i_noValImg) )
        i_noValImg = settings.i_noValImg;
    else
        i_noValImg = 6;
    end  
    
    if ( isfield(  settings, 'i_noTestImg') && ~isempty(settings.i_noTestImg) )
        i_noTestImg = settings.i_noTestImg;
    else
        i_noTestImg = 10;
    end    
    
    

    
    if ( isfield(  settings, 'b_writeFilelists') && ~isempty(settings.b_writeFilelists) )
        b_writeFilelists = settings.b_writeFilelists;
    else
        b_writeFilelists = true;
    end    
    
    if ( isfield(  settings, 'trainImgFilelist') && ~isempty(settings.trainImgFilelist) )
        trainImgFilelist = settings.trainImgFilelist;
    else
        trainImgFilelist = 'data/art_trainImgs.txt';
    end 
    
    if ( isfield(  settings, 'valImgFilelist') && ~isempty(settings.valImgFilelist) )
        valImgFilelist = settings.valImgFilelist;
    else
        valImgFilelist = 'data/art_valImgs.txt';
    end 
    
    if ( isfield(  settings, 'testImgFilelist') && ~isempty(settings.testImgFilelist) )
        testImgFilelist = settings.testImgFilelist;
    else
        testImgFilelist = 'data/art_testImgs.txt';
    end     
  
    
    
    
    
    dataset.images = [];
    dataset.labels = [];
    dataset.trainImages = [];
    dataset.valImages = [];
    dataset.testImages = [];
      



    try 
            classFileList = textscan(fileListID, '%s');
            fclose(fileListID);

            classFileList = classFileList{1};

            % append file names
            dataset.images = classFileList(1:i_noImg);

            % we have no real class labels here
            dataset.labels = ones(1,i_noImg);

            % append img indices for train, val, and test 

            dataset.trainImages = 1:i_noTrainImg;
            dataset.valImages   = (i_noTrainImg+1):(i_noTrainImg+i_noValImg);
            dataset.testImages  = (i_noTrainImg+i_noValImg+1):(i_noTrainImg+i_noValImg+i_noTestImg);

    catch  err
        disp('Error while reading filenames of artificial art dataset - check that your filename file is up to date!');
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