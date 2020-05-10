% Written by Andrew Lin

% This script processes multiple movies all with the same odor timing,
% saves the activity maps, and calls the map-display function
% 1. Read info on which files, bkgnd signal etc. from user-created text
% file.
% 2. Call activityMap to get map
% 3. Save all the maps in an array
% save to .mat file

[filename, pathname] = uigetfile('*.txt', 'Pick txt file specifying input');
fid = fopen(strcat(pathname,filename));
% filename pathname conditions correlationthres bkgndGreen bkgndRed
C = textscan(fid, '%s %s %s %f %f %f', 'Delimiter', '\t', 'HeaderLines', 1);
fclose(fid);

% Strategy:
% Start with a text file listing the file names and locations
% Each movie will be tagged with the experimental conditions:
% - the location type (e.g., vertical lobe, horizontal lobe, calyx)
% - ATP concentration
% - is it odor, ATP alone, or odor+ATP?
% Loop through all files:
% - generate activityMap object using the same activityMapParams input
% - save the objects to a .mat file 
% - remove the objects from Matlab memory but keep in cell arrays [possibly multi-dimensional array for the different experimental conditions? - leave this feature for later]:
% 	- f0
% 	- the name/location of the .mat file
% Register the f0 images
% Average together the f0 images, display for the user to draw the mask and skeleton
% Desirable: need a metric to quantify how good the registration was so you don't have to manually check every movie. 
% - correlation? 
% Loop through all .mat files
% - add the common mask/skeleton to each activityMap object, save the .mat file
% - extract the relevant information from each Voronoi segment eg:


numFiles = length(C{1});

% pre-allocate your array with empty activityMap objects
allMaps = repmat(activityMap(),numFiles,1);

% Warning: assumes all columns in the input file were equal!
for i=1:numFiles
    
    params = activityMapParams;
    
    thisFileName = C{1}{i};
    % remove double quotes that Matlab inserts in file names with special
    % characters, like commas
    if thisFileName(1)=='"'
        thisFileName = thisFileName(2:(end-1));
    end
    params.fileName = thisFileName;
    params.pathName = C{2}{i};
    params.description = C{3}{i};
    params.corrThres = C{4}(i);
    %params.userBkgndROI = bkgndMask;
    params.bkgnd(1) = C{5}(i);
    params.bkgnd(2) = C{6}(i);

    switch params.description(3)
        case '3'
            params.preLimits = [0 15];
            params.stimLimits = [15 16.5];
        case '4'
            params.preLimits = [0 5];
            params.stimLimits = [5 6];
        case {'1', '2'}
            params.preLimits = [10 20];
            params.stimLimits = [20 22.5];
        otherwise
            error('unknown stimulus condition');
    end
    
    allMaps(i) = activityMap(params);

end

allF0s = cell(numFiles,1);
for i=1:numFiles
    allF0s{i} = allMaps(i).f0(:,:,:,1);
end
correlateImages(allF0s)

[offsets, xmin, xmax, ymin, ymax, ~] = registerImages(allF0s);
for i=1:numFiles
    allMaps(i)=allMaps(i).offsetMap(offsets(i,:), xmin, xmax, ymin, ymax);
end
regImages=cell(numFiles,1);

for i=1:numFiles
    regImages{i} = allMaps(i).f0;
end
correlateImages(regImages)

nDims = length(size(regImages{1}));
avgRegImages = mean(cat(nDims+1,regImages{:}),nDims+1);

% avgRegImages = mean(cat(nDims+1,allF0s{:}),nDims+1);

skelMask = activityMap.outlineObject(avgRegImages, 2);
disp('Step 2: Click points to define the skeleton');
commonSkel = skeleton(skelMask, allMaps(1).pixelCal);
disp('Step 3: Define the stimulation site');
commonSkel = commonSkel.defineStartingPoint(avgRegImages(:,:,:,2));
commonSkel = commonSkel.labelBranches();
commonSkel = commonSkel.createSpacedNodes(20);
commonSkel = commonSkel.createVoronoiMask();
commonSkel.drawSkeleton();

for i=1:numFiles
    allMaps(i).skel = commonSkel;
    allMaps(i) = allMaps(i).skeletonAnalysis(1);
    allMaps(i).saveMap();
end

% pull out the descriptions
allDescriptions = cell(numFiles,1);
for i=1:numFiles
    allDescriptions{i} = allMaps(i).params.description;
end



    
%%% Save allMaps using name of .txt file (need to get prefix)
fileprefix = filename(1:end-4);
save(strcat(fileprefix, '.mat'), 'allMaps', 'fileprefix', 'C');
% 
% displayMultiActivityMaps(allMaps, fileprefix, 1, 0);
