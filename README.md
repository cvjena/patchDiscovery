# Source code for (un)supervised and exemplar-specific patch discovery


## COPYRIGHT

This package contains Matlab source code for patch discovery and local learning as described in:

*Alexander Freytag and Erik Rodner and Trevor Darrell and Joachim Denzler:
"Exemplar-specific Patch Features for Fine-grained Recognition".
German Conference on Pattern Recognition (GCPR), 2014*

*Alexander Freytag and Erik Rodner and Joachim Denzler:
"Birds of a Feather Flock Together - Local Learning of Mid-level Representations for Fine-grained Recognition".
ECCV Workshop on Parts and Attributes (ECCV-WS), 2014*

Please cite the appropriate paper if you are using this code!

(LGPL) copyright by Alexander Freytag and Erik Rodner and Trevor Darrell and Joachim Denzler



## SHORT DESCRIPTION
This repo contains source code for several aspects
i) (un)supervised patch discovery: seeding, bootstrapping, selection
ii) patch representations: features, feature visualizations, embeddings
iii) local learning: matching, matching visualization
iv) object detection: generic version of who
iv) misc: interfaces to libSVM, libLinear, loading of data, ...

The following four demos will guide you through the main methods and show 
you in detail how to use the source code and settings therein.



## START / SETUP


We have only a small number of dependencies to other libraries.
Mirrors for downloading libraries not yet existing in your systems are displayed.
when running 

initWorkspacePatchDiscovery

which you should adapt according to your system.

Short list of dependencies:
- Felzenszwalbs unsupervised segmentation
- the adapted who-lib for LDA models and HOG feature extraction
- libLinear and libSVM for classification
- optionally (but recommended): van de Weijers color name descriptors
- iHOG for inspecting learned HOG representations
- vlFeat for higher order embeddings of features





## DATA
You will need to adapt the data/initCUB200_2011.m script towards
the position of CUB2011 dataset in your system. 
If not available already, you can download the dataset
at [http://www.vision.caltech.edu/visipedia/CUB-200-2011.html](http://www.vision.caltech.edu/visipedia/CUB-200-2011.html)


## DEMOS

### DEMO 1 -Compute seeding points for patch detectors
```
% run the first demo showing how to perform seeding on bird images  
seedingResults = demo1_seeding;
```

### DEMO 2 - Bootstrapping of patch detectors
```
patchesBootstrapped = demo2_bootstrapping;
```


### DEMO 4 - Matching for Local Learning
```
demo4_nnMatching;
```

### DEMO 5 -Local Learning and Patch Discovery for Exemplar-specific models and representations
```
demo5_nnMatchingAndClassification
```





In case of any errors, questions, or hints feel free to contact us!