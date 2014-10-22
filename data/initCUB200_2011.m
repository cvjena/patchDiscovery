function dataset = initCUB200_2011( settings )
         
%     if strcmp( getenv('USER'), 'alex')
%         fileListID = fopen('data/filelists_cub200_2011.txt');
%     elseif strcmp( getenv('USER'), 'freytag')
%         fileListID = fopen('/users/tmp/freytag/data/finegrained/cub200_2011/cropped_256x256/images/filelists_cub200_2011.txt');       
%     end
    
   
    if ( nargin < 1)
        settings = [];
    end

    %i_noTrainImgPerClass = getFieldWithDefault ( settings, 'noTrainImgPerClass', 30 );
    %i_noTestImgPerClass  = getFieldWithDefault ( settings, 'i_noTestImgPerClass', 30 );
    
    
    dataBaseDir = getFieldWithDefault ( settings, 'dataBaseDir', ...
                  '/home/freytag/data/finegrained/cub200_2011/cropped_enlarged_256x256/' ) ;
                  %'/users/tmp/freytag/data/finegrained/cub200_2011/cropped_enlarged_256x256/' ) ;
    %dataBaseDir = [setts.dataset_cub200_2011 '/'];

    train_test_split = load([ dataBaseDir '/train_test_split.txt' ]);
    train_test_split = train_test_split(:,2);

    labels = load([ dataBaseDir '/image_class_labels.txt' ]);
    labels = labels(:,2);
        
    labels_train = labels(train_test_split == 1);
    labels_test  = labels(train_test_split == 0);


    fid = fopen([ dataBaseDir '/images.txt' ]);
    images = textscan(fid, '%s %s');
    fclose(fid);
    images = images{2};
            
    images = strcat([dataBaseDir 'images/'],images);
    
    dataset.images = [];
    dataset.images = images;
    %
    dataset.labels = [];
    dataset.labels = labels;
    %
    dataset.trainImages = find(train_test_split == 1);
    dataset.valImages   = [];
    dataset.testImages  = find(train_test_split == 0);
    
    
    i_numClasses = getFieldWithDefault ( settings, 'i_numClasses', 200 );

    if (i_numClasses == 14)
        classesnr  = [36 151 152 153 154 155 156 157 187 188 189 190 191 192];
        train_idxs = ismember(labels_train, classesnr);
        test_idxs  = ismember(labels_test, classesnr);

        dataset.images = [dataset.images(dataset.trainImages(train_idxs)); ...
                          dataset.images(dataset.testImages(test_idxs))...
                         ];

        
        labels_train = labels_train(train_idxs);
        labels_test  = labels_test(test_idxs);
        
        dataset.trainImages = 1:length(labels_train);
        dataset.testImages  = (length(labels_train)+1):(length(labels_train)+length(labels_test));        
        
        %remap labels to make them continous
        labelmap(classesnr) = 1:length(classesnr);
        %dataset.labels      = 
        labels_train = labelmap(labels_train)';
        labels_test = labelmap(labels_test)';
        
        dataset.labels = [ labels_train; labels_test ];
        
    elseif (i_numClasses == 3)
        classesnr  = [1 2 3];
        train_idxs = ismember(labels_train, classesnr);
        test_idxs  = ismember(labels_test, classesnr);

        dataset.images = [dataset.images(dataset.trainImages(train_idxs)); ...
                          dataset.images(dataset.testImages(test_idxs))...
                         ];
                     
        labels_train = labels_train(train_idxs);
        labels_test  = labels_test(test_idxs);
        
        dataset.trainImages = 1:length(labels_train);
        dataset.testImages  = (length(labels_train)+1):(length(labels_train)+length(labels_test));        
        
        %remap labels to make them continous
        labelmap(classesnr) = 1:length(classesnr);
        %dataset.labels      = 
        labels_train = labelmap(labels_train)';
        labels_test = labelmap(labels_test)';
        
        dataset.labels = [ labels_train; labels_test ];
    elseif (i_numClasses == 200)
        %nothing serious to do here...
        
        % only adapt size of idx vectors (stupid, but necessary)
        dataset.trainImages = dataset.trainImages';
        dataset.testImages  = dataset.testImages';
    else
        assert(false, 'size not implemented')            
    end    
    
    
    
    


%     fileLists = textscan(fileListID, '%s');
%     fclose(fileListID);
% 
%     fileLists = fileLists{1};        

%     if ( isfield(  settings, 'noClasses') && ~isempty(settings.noClasses) )
%         noClasses = settings.noClasses;
%     else
%         noClasses = length(fileLists);
%     end     


%     try 
%         for clIdx = 1:length(classIndicesToUse)
% 
%             classFileListID = fopen( fileLists{ classIndicesToUse(clIdx) } );
%             classFileList = textscan(classFileListID, '%s');
%             fclose(classFileListID);
% 
%             classFileList = classFileList{1};
% 
%             % append file names of new category
%             dataset.images = [ dataset.images; classFileList(1:noImgPerClass) ];
% 
%             % append class label of new category
%             dataset.labels = [ dataset.labels  classIndicesToUse(clIdx)*ones(1,noImgPerClass ) ] ;
% 
%             % append img indices for train, val, and test of new category
%             idxClassStart = (clIdx-1)*noImgPerClass+1;
% 
%             dataset.trainImages = [ dataset.trainImages idxClassStart:(idxClassStart+noTrainImgPerClass-1) ];
% %             dataset.valImages   = [ dataset.valImages (idxClassStart+noTrainImgPerClass):(idxClassStart+noTrainImgPerClass+noValImgPerClass-1) ];  
% %             dataset.testImages  = [ dataset.testImages (idxClassStart+noTrainImgPerClass+noValImgPerClass):(idxClassStart+noImgPerClass-1) ]; 
%             dataset.valImages   = [ dataset.valImages (idxClassStart):(idxClassStart+noValImgPerClass-1) ];  
%             dataset.testImages  = [ dataset.testImages (idxClassStart+noValImgPerClass):(idxClassStart+noImgPerClass-1) ]; 
%         end
% 
%     catch  err
%         disp('Error while reading filenames of CUB 200 birds 2011 dataset - check that your filename file is up to date!');
%     end
% 
% 
%     if ( b_writeFilelists ) 
%         try
%             trainFile = fopen(trainImgFilelist,'w');
%             fprintf(trainFile,'%s\n', dataset.images{ dataset.trainImages } );
%             fclose(trainFile);  
%             dataset.trainImgFilelist = trainImgFilelist;
% 
%             valFile = fopen(valImgFilelist,'w');
%             fprintf(valFile,'%s\n', dataset.images{ dataset.valImages } );
%             fclose(valFile);  
%             dataset.valImgFilelist = valImgFilelist;
% 
%             testFile = fopen(testImgFilelist,'w');
%             fprintf(testFile,'%s\n', dataset.images{ dataset.testImages } );
%             fclose(testFile);  
%             dataset.testImgFilelist = testImgFilelist;
% 
%         catch err
%             disp('Unable to write filelists for train, val, and test images - sry.');
%         end
%     end    
    
    
                
end