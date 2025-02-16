% Purpose of this script:
% The specified Excel file has a list of .mat files which store the outputs
% of the sparseness and correlation analysis from multiActivity, and a list
% of .txt files listing the original .tif files of the movies.
% This will go through all the .mat files and compile the sparseness and
% correlation results, and the stored masks for the ROIs used to calculate
% sparseness and correlation. These are then applied to the original .tif
% files to get the average dF/F time courses for each movie.

[filename, pathname] = uigetfile('*.xlsx', 'Pick Excel file specifying input');
fileList = readtable(strcat(pathname,filename));

% conditions will be in alphabetical order (e.g. control, exp)
conditions = sort(unique(fileList.condition));
numConds = length(conditions);
data = cell(numConds,1);
frameRates = cell(numConds,1);
meanResp = cell(numConds,1);
sparsenessNoThres = cell(numConds,1);
corrMatrixNoThres = cell(numConds,1);
brainNames = cell(numConds,1);
for c=1:numConds
    data{c} = {};
end

channel = 1;
preTimes = [18 20];
respTimes = [20 25];
conditionCounts = zeros(numConds,1);

% %%%%%%%%%%%
% % un-comment this code to replace the fileshare path names with a local path
% oldMatPath = ''; % fileshare path e.g. \\uosfstore.shef.ac.uk\...
% newMatPath = ''; % your local path e.g. \\C:\My Documents\...
% for i=i:height(fileList)
%     % for the .mat files
%     fileList.matFileFolder{i} = replace( fileList.matFileFolder{i}, oldMatPath, newMatPath);
% end



maxTime = 0;
% data structure will be:
% data{condition}{brain,odor}
% brains
for i=1:height(fileList)
    conditionIndex = find(matches(conditions,fileList.condition(i)));
    conditionCounts(conditionIndex) = conditionCounts(conditionIndex)+1; % keep track of which brain in this condition we're on

    load(fullfile(fileList.matFileFolder{i},fileList.matFile{i})); % the "result" struct
    sparsenessNoThres{conditionIndex}(conditionCounts(conditionIndex),:) = result.sparsenessNoThres;
    corrMatrixNoThres{conditionIndex}(conditionCounts(conditionIndex),:,:) = result.corrMatrixNoThres;
    brainNames{conditionIndex}{conditionCounts(conditionIndex)} = fileList.matFile{i};
    
    tifListFile = fullfile(fileList.tifListFileFolder{i},fileList.tifListFile{i});
    tifList = readtable(tifListFile,'Delimiter','\t');

    % %%%%%%%%%%%
    % % un-comment this code to replace the fileshare path names with a local path
    % oldTifPath = ''; % fileshare path e.g. \\uosfstore.shef.ac.uk\...
    % newTifPath = ''; % your local path e.g. \\C:\My Documents\...
    % for j=1:height(tifList)
    %     % for the tif files
    %     tifList.pathname{j} = replace( tifList.pathname{j}, oldTifPath, newTifPath);
    % end


    % movies for each brain
    for j=1:height(tifList)
        fprintf(strcat('Loading file ', tifList.pathname{j}, tifList.fileprefix{j}, '...\n'));
        [movie, SI] = readScanImageTiffLinLab(strcat(tifList.pathname{j}, tifList.fileprefix{j}));
        % readScanImageTiffLinLab returns a 5D matrix even if some of
        % these dimensions are singletons
        % It is crucial to keep the dimension order rigid and not
        % squeeze out singleton dimensions. What if you have only 1
        % z-slice and 2 channels, vs 2 z-slices and 1 channel. If you
        % squeeze out the singleton dimension, how will you know which
        % is the case?
        movie = single(movie);
        frameRate = SI.hRoiManager.scanVolumeRate;

        xmin = max(result.offsets(:,2)) + 1;
        xmax = min(size(movie,2) + result.offsets(:,2));
        ymin = max(result.offsets(:,1)) + 1;
        ymax = min(size(movie,1) + result.offsets(:,1));
        offsets = result.offsets;
        % xmin
        % xmax
        % ymin
        % ymax
        registeredMovie = movie( (ymin - offsets(j,1)):(ymax - offsets(j,1)),...
            (xmin - offsets(j,2)):(xmax - offsets(j,2)),:,:,:);
        numFrames = size(registeredMovie,5);

        F = zeros(numFrames,1);
        for t=1:numFrames
            thisFrame = registeredMovie(:,:,:,channel,t);
            F(t) = mean(thisFrame(result.mask),'all','omitnan');
        end
        F = F-tifList.bkgnd(j);
        F0 = mean(F(round(preTimes(1)*frameRate):round(preTimes(2)*frameRate)));
        dFF = (F-F0)/F0;
        data{conditionIndex}{conditionCounts(conditionIndex),j} = dFF;
        frameRates{conditionIndex}(conditionCounts(conditionIndex),j) = frameRate;
        respFrames = round(respTimes*frameRate);
        meanResp{conditionIndex}(conditionCounts(conditionIndex),j) = mean(dFF(respFrames(1):respFrames(2)));
        if maxTime < numFrames/frameRate
            maxTime = numFrames/frameRate;
        end
    end
end

%% interpolate
interpFrameRate = 10;
numInterpFrames = ceil(maxTime*interpFrameRate);
interpData = cell(numConds,1);
numOdors = 7;
for c=1:numConds
    numSamples = size(data{c},1);
    interpData{c} = zeros(numSamples,numOdors,numInterpFrames);
    for s=1:numSamples
        for o=1:numOdors
            frameRate = frameRates{c}(s,o);
            numFrames = size(data{c}{s,o},1);
            interpData{c}(s,o,:) = interp1((1:numFrames)/frameRate,data{c}{s,o},(1:numInterpFrames)/interpFrameRate);
        end
    end
end

save(strcat(filename,'-summary.mat'),'data','frameRates','meanResp','conditions','brainNames','sparsenessNoThres','corrMatrixNoThres')

%% average together across flies
interpDataMeanOverOdors = cell(numConds,1);

meanTraces = zeros(numConds,numOdors,numInterpFrames);
semTraces = zeros(numConds,numOdors,numInterpFrames);
meanTracesOverOdors = zeros(numConds,numInterpFrames);
semTracesOverOdors = zeros(numConds,numInterpFrames);

for c=1:numConds
    interpDataMeanOverOdors{c} = mean(interpData{c},2);
    meanTraces(c,:,:) = mean(interpData{c},1);
    semTraces(c,:,:) = std(interpData{c},0,1)/sqrt(size(interpData{c},1));
    meanTracesOverOdors(c,:) = mean(interpDataMeanOverOdors{c},1);
    semTracesOverOdors(c,:) = std(interpDataMeanOverOdors{c},1)/sqrt(size(interpDataMeanOverOdors{c},1));
end

%% graphs
timePoints = (1:numInterpFrames)/interpFrameRate;
figure
hold on
colors = {'k','r'};
for c=1:numConds
    shadedErrorBar(timePoints,meanTracesOverOdors(c,:),semTracesOverOdors(c,:),'lineprops',colors{c})
end
yl = ylim;
line([20 25], [yl(1) yl(1)],'lineWidth',2,'Color','k')
xlim([15 35])

set(gca,'Units','centimeters')
currentPos = get(gca,'Position');
set(gca,'Position',[currentPos(1) currentPos(2) 1.5 2.5])

% %% separate odors
% figure
% for o=1:numOdors
%     subplot(1,numOdors,o);
%     hold on
%     colors = {'k','r'};
%     for c=1:numConds
%         shadedErrorBar(timePoints,meanTraces(c,o,:),semTraces(c,o,:),'lineprops',colors{c})
%     end
% 
% end

