function dataset = initToyExample()

    % old really small toy example with only one image per class 
    % in train and val
%     images = cell(4,1);
% 
%     images{1} = 'toyData/cows.png';
%     images{2} = 'toyData/cowsVal.png';
%     images{3} = 'toyData/sheep.png';
%     images{4} = 'toyData/sheepVal.png';
%     dataset.images = images;
%     dataset.labels = [1 1 2 2];
%     dataset.valImages = [1 3];
%     dataset.trainImages  = [2 4];
     
    %larger toy example with 16 validation images and a single
    %training image per class 
    imagesTrain = textread('toyData/filesTrain.txt', '%s');
    imagesVal = textread('toyData/filesVal.txt', '%s');
    dataset.images = [imagesTrain; imagesVal];
    
    dataset.labels = ones(1,34);
    dataset.labels(2) = 2; % our training img
    dataset.labels(4) = 2; %our val img of second class which is used in debugging
    dataset.labels(20:34) = 2;
    
%     dataset.valImages = 3:34;
    dataset.valImages = [10:19 25:34];
    dataset.trainImages  = [1:4 5:9 20:24 ];    
    
end