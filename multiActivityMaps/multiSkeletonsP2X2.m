% nodestdThresh. This is the standard deviation threshold for exclusion of
% skeleton nodes based on prePeriod activity
nodestdThresh = 2;

[textFileName, textFilePathName] = uigetfile('*.txt', 'Pick txt file specifying input');
fid = fopen(strcat(textFilePathName,textFileName));
% filename pathname conditions 
textFileInput = textscan(fid, '%s %s %s %s', 'Delimiter', '\t', 'HeaderLines', 1);
fclose(fid);

numFiles = length(textFileInput{1});
fullPathFileNames = cell(numFiles,1);
for i=1:numFiles
    thisFileName = textFileInput{1}{i};
    % remove double quotes that Matlab inserts in file names with special
    % characters, like commas
    if thisFileName(1)=='"'
        thisFileName = thisFileName(2:(end-1));
    end
    % concatenate pathname with filename
    fullPathFileNames{i} = strcat(textFileInput{2}{i}, thisFileName);
end
fileNames = textFileInput{1};
pathNames = textFileInput{2};
ATPconc = textFileInput{4};

%filenames is now a cell aray with the full path of each .mat file

spacing = 20;
% normalizeSkeletons will read in each .mat file to get its skeleton, then
% stretch or squish the spaced nodes so they will all line up together
normalizedSkeletons = normalizeSkeletons(fullPathFileNames, spacing);
% Cludge - we want the code to assign the junction to be on the same branch
% for all mat files, but for some mat files it assigns the junction to
% different branches. This sets the first node to be on branch 1.
for p=1:length(normalizedSkeletons)
    normalizedSkeletons(p).spacedNodes(1).branchNumber=1;
end
% store the results in compositeResults
% we'll start with this format:
% file (.mat file) x [v, h, c] x spacedNodes
compositeResults = zeros(numFiles, 3, length(normalizedSkeletons(1).spacedNodes));
compositeResultsATP = zeros(numFiles, 3, length(normalizedSkeletons(1).spacedNodes));
% Hopefully all the normalized skeletons have the same # of spacedNodes???
% 
for i=1:numFiles
    % load the allMaps for one file
    % (note, to avoid overloading the system, don't try to store all the
    % allMaps arrays for every .mat files you read in)
    load(fullPathFileNames{i});
    % for every activityMap object in allMaps,
    for j=1:length(allMaps)
        % set the skeleton to the matching normalized skeleton
        allMaps(j).skel = normalizedSkeletons(i);
        allMaps(j) = allMaps(j).skeletonAnalysis(1); % re-run skeleton analysis on channel 1
    end
    % save the allMaps array with new analysis as "-normalizedSkeleton.mat"
    fileprefix = fileNames{i}(1:end-4);
    save(strcat(strcat(pathNames{i},fileprefix), '-normalizedSkeleton.mat'), 'allMaps', 'fileprefix');

    % make the composites to do the (vx2 - vx1)/vx1 
    % use string pattern matching to find the matching pairs vx2, vx1
    
    % get the descriptions into a single array
    descriptions = strings(length(allMaps),1);
    for j=1:length(allMaps)
        descriptions(j) = string(allMaps(j).params.description);
    end
        
    % find all descriptions that have '2' in the last position
    odorATPmaps = regexp(descriptions,'..2','forceCellOutput');
    odorATPmaps = ~cellfun(@isempty,odorATPmaps);
    odorATPmapIndices = find(odorATPmaps);
    % find all descriptions that have '1' in the last position
    odorAlonemaps = regexp(descriptions,'..1','forceCellOutput');
    odorAlonemaps = ~cellfun(@isempty,odorAlonemaps);
    odorAlonemapIndices = find(odorAlonemaps);
    % find all descriptions that have '3' in the last position
    ATPmaps = regexp(descriptions,'..3','forceCellOutput');
    ATPmaps = ~cellfun(@isempty,ATPmaps);
    ATPmapIndices = find(ATPmaps);
    % loop through the descriptions that have '2' in the last position
    for j=1:length(odorATPmapIndices)
        firstChar = descriptions{odorATPmapIndices(j)}(1);
        stdNodes=std(allMaps(odorATPmapIndices(j)).voronoiTimeSeries(:,allMaps(j).prePeriod),0,2);
        indexNodes=find(stdNodes>nodestdThresh);
        % find the matching description with the same firstChar but with
        % '1' in the last position
        for k=1:length(odorAlonemapIndices)
            
            if firstChar==descriptions{odorAlonemapIndices(k)}(1)
                % ie (odor alone - odor+ATP) / (odor alone max for each segment)
                % (avg-avg)/max
                normDiff = (allMaps(odorAlonemapIndices(k)).voronoiMeanResp - ...
                    allMaps(odorATPmapIndices(j)).voronoiMeanResp) ./ ...
                    allMaps(odorAlonemapIndices(k)).voronoiMaxResp;
                switch firstChar
                    case 'v'
                        compositeResults(i,1,:) = normDiff;
                    case 'h'
                        compositeResults(i,2,:) = normDiff;
                    case 'c'
                        compositeResults(i,3,:) = normDiff;
                end
            end
        end
    end
    % Loop through the descriptions that have '3' in last position
    for y=1:length(ATPmapIndices)
        firstCharac = descriptions{ATPmapIndices(y)}(1);
        % Check the sd of the response of each node during the prePeriod. If
        % this exceeds nodestdThreshold, set the voronoiMeanResp of that node to NaN
        stdNodes=std(allMaps(ATPmapIndices(y)).voronoiTimeSeries(:,allMaps(y).prePeriod),0,2);
        indexNodes=find(stdNodes>nodestdThresh);
        if firstCharac==descriptions{ATPmapIndices(y)}(1)
            ATPavg = allMaps(ATPmapIndices(y)).voronoiMeanResp;
            switch firstCharac
                case 'v'
                    compositeResultsATP(i,1,:) = ATPavg;
                case 'h'
                    compositeResultsATP(i,2,:) = ATPavg;
                case 'c'
                    compositeResultsATP(i,3,:) = ATPavg;
            end
        end
    end
end


% split branches into a cell matrix. Each cell contains an nx1 array
% dimensions are: ['v' 'h' 'c'], numFiles, branch number (vertical,
% peduncle, horizontal)
compositeResultsSplit = cell(3, numFiles, normalizedSkeletons(1).numBranches);
for i=1:numFiles
    branchNumbers = [normalizedSkeletons(i).spacedNodes.branchNumber];
    for j=1:size(compositeResultsSplit,1)
        for k=1:size(compositeResultsSplit,3)
            compositeResultsSplit{j,i,k} = squeeze(compositeResults(i,j,branchNumbers==k));
        end
    end
end
% Repeat for ATP only data
compositeResultsSplitATP = cell(3, numFiles, normalizedSkeletons(1).numBranches);
for i=1:numFiles
    branchNumbers = [normalizedSkeletons(i).spacedNodes.branchNumber];
    for j=1:size(compositeResultsSplitATP,1)
        for k=1:size(compositeResultsSplitATP,3)
            compositeResultsSplitATP{j,i,k} = squeeze(compositeResultsATP(i,j,branchNumbers==k));
        end
    end
end


% merge the branches so it goes calyx-->vertical tip, calyx-->horizontal
% tip
compositeResultsMergeBranches = cell(3, numFiles, 2);
for i=1:size(compositeResultsSplit,1)
    for j=1:size(compositeResultsSplit,2)
        % 1: calyx-->vertical (branch 2 inverted, then 1)
        compositeResultsMergeBranches{i,j,1} = [flipud(compositeResultsSplit{i,j,2}); ...
            compositeResultsSplit{i,j,1}];
        % 2: calyx-->horizontal (branch 2 inverted, then first element of branch 1 (the junction), then branch 3)
        compositeResultsMergeBranches{i,j,2} = [flipud(compositeResultsSplit{i,j,2}); ...
            compositeResultsSplit{i,j,1}(1); ...
            compositeResultsSplit{i,j,3}];
    end
end

% Repeat for ATP only recordings
compositeResultsMergeBranchesATP = cell(3, numFiles, 2);
for i=1:size(compositeResultsSplitATP,1)
    for j=1:size(compositeResultsSplitATP,2)
        % 1: calyx-->vertical (branch 2 inverted, then 1)
        compositeResultsMergeBranchesATP{i,j,1} = [flipud(compositeResultsSplitATP{i,j,2}); ...
            compositeResultsSplitATP{i,j,1}];
        % 2: calyx-->horizontal (branch 2 inverted, then first element of branch 1 (the junction), then branch 3)
        compositeResultsMergeBranchesATP{i,j,2} = [flipud(compositeResultsSplitATP{i,j,2}); ...
            compositeResultsSplitATP{i,j,1}(1); ...
            compositeResultsSplitATP{i,j,3}];
    end
end

% spit out 6 .csv files
% the rows are distances from the calyx
% the columns are individual flies (sets of 9 movies)
stimSiteKey = {'v','h','c'};
branchKey = {'CtoV','CtoH'};
branchKeyATP = {'CtoVATP','CtoHATP'};
for i=1:length(stimSiteKey)
    for j=1:length(branchKey)
        csvwrite([stimSiteKey{i}, branchKey{j}, '.csv'], cell2mat(compositeResultsMergeBranches(i,:,j)));
    end
end

% Repeat for ATP only data
for i=1:length(stimSiteKey)
    for j=1:length(branchKeyATP)
        csvwrite([stimSiteKey{i}, branchKeyATP{j}, '.csv'], cell2mat(compositeResultsMergeBranchesATP(i,:,j)));
    end
end

