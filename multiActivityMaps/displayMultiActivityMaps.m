function [] = displayMultiActivityMaps(allMaps, fileprefix, registerF0)
% displayMultiActivityMaps:
% Usage:
% displayMultiActivityMaps(allMaps, fileprefix, registerF0)
% allMaps is an array of activityMap objects
% Will display 2 figures:
% 1. All the maps in allMaps, one per row.
%    Each row will be an 1 X N montage (N = number of slices)
%    'Hot' false color (dF/F) overlaid on grayscale (F0)
%    Each map is labeled by the 'description' field in the activityMap
%    object, e.g. 'mch' or 'oct' or other odor
% 2. A plot of the correlations over time of each movie, to let you decide
%    want to set a correlation threshold to exclude frames where the fly
%    moved too much
% Written by Andrew Lin



maxFixed = 0;
currentMax = 0;
absoluteMax = 2; % this is the maximum value for dF/F
F0thres = 5;
grayscaleMax = 90; % this is the maximum value for the grayscale

numFiles = size(allMaps,1);

% % Use this code if you want to smooth the activity map
% h = fspecial('gaussian',3,2);
% for i=1:numFiles
%     % It's okay to change allMaps, because this is inside a function
%     allMaps{i,mapNum} = imfilter(allMaps{i,mapNum},h);
% %     Uncomment if you want to display the Off or Non-thresholded responses
% %     allMaps{i,2} = imfilter(allMaps{i,2},h);
% %     allMaps{i,3} = imfilter(allMaps{i,3},h);
% end

if (maxFixed == 0)
    for i=1:numFiles
        maxOn = max(reshape(allMaps(i).dff,numel(allMaps(i).dff),1));
        if (absoluteMax)
            maxOn = min([maxOn absoluteMax]);
        end
        currentMax = max([currentMax maxOn]);
    end
end

newMax = max([maxFixed currentMax]);
newMax = max([newMax 0.1]);

displayRange=[0 newMax]

% if (numFiles <= 9)
%     height = round(sqrt(numFiles));
%     width = ceil(sqrt(numFiles));
% else
%     height = 3;
%     width = 3;
% end

F0s = {allMaps.f0}';
dFFs = {allMaps.dff}';
if registerF0
    [offsets, xmin, xmax, ymin, ymax, ~] = registerImages(F0s);
    % offsets
    for i=1:numFiles
        dFFs{i} = dFFs{i}((ymin - offsets(i,1)):(ymax - offsets(i,1)), ...
            (xmin - offsets(i,2)):(xmax - offsets(i,2)),:); 
        F0s{i} = F0s{i}((ymin - offsets(i,1)):(ymax - offsets(i,1)), ...
            (xmin - offsets(i,2)):(xmax - offsets(i,2)),:); 
    end
end

% Draw the activity maps as 'hot' color map overlaid on a grayscale image
% of the baseline fluorescence
figure('Name',strcat('Hot/grayscale multiMap for ', fileprefix), 'NumberTitle', 'off', 'Color', 'white');
h = tight_subplot(numFiles,1,[0.05 0.05],[0.02 0.01],[0.03 0.01]);
for i=1:numFiles
    axes(h(i));
    overlayimage = overlayColorOnGrayscale(permute(dFFs{i}, [2 1 3 4]), ...
        permute(F0s{i}, [2 1 3 4]), displayRange, 0); %displayRange, [0 grayscaleMax]);
    % size(overlayimage)
    montage(overlayimage, 'Size', [1 size(overlayimage,4)]);
%     imwrite(overlayimagenooutline,strcat(fileprefix, '-', allMaps{i,5}, ...
%         '-', num2str(mapNum), 'overlay.tif'), ...
%         'tif', 'Compression', 'lzw');
    axis equal, axis tight;
    title(allMaps(i).params.description);
    set(gca,'xtick',[]);
    set(gca,'ytick',[]);
end


% plot the correlation traces in as many colors as possible - this is
% useful if you have lots of movies
colorset = varycolor(numFiles);
figure('Name','Correlation traces in varying colors');
frameRates = [allMaps.frameRate];
if range(frameRates)==0 % if all movies have the same frame rate
    [~, timeAxis] = allMaps(1).dualXaxes();
    ylabel(timeAxis,'Correlation of each frame to F0');
end

for i=1:numFiles
    frameSeries = 1:allMaps(i).nFrames;
    timeSeries = frameSeries/allMaps(i).frameRate;
    plot(timeSeries,allMaps(i).correlations, 'Color', colorset(i,:));
    hold all;
end

paramsObjects = [allMaps.params];
legend({paramsObjects.description});

           
end