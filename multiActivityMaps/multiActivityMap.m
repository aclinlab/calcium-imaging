% A script to make activity maps for many files at once
% specify the files you want to run in a text file
%
% Currently for movies with two odor pulses (easy to change)
% You can use this as a template for your own movies with different stimuli
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
% filename pathname conditions bkgnd correlationthreshold
% WARNING no longer looks for frame rate
C = textscan(fid, '%s %s %s %f %f', 'Delimiter', '\t', 'HeaderLines', 1);
fclose(fid);

numFiles = length(C{1});

% pre-allocate your array with empty activityMap objects
allMaps = repmat(activityMap(),numFiles,1);

stimPeriod = [20 25; 35 40];

% Warning: assumes all columns in the input file were equal!
for i=1:numFiles
    
    params = activityMapParams;
    params.preLimits = [10 20];
    params.stimLimits = stimPeriod;
    params.ctrlLimits = [5 10];
    
    thisFileName = C{1}{i};
    % remove double quotes that Matlab inserts in file names with special
    % characters, like commas
    if thisFileName(1)=='"'
        thisFileName = thisFileName(2:(end-1));
    end
    params.fileName = thisFileName;
    params.pathName = C{2}{i};
    params.description = C{3}{i};
    params.bkgnd = C{4}(i);
    params.corrThres = C{5}(i);

    allMaps(i) = activityMap(params);

end

%%% Save allMaps using name of .txt file (need to get prefix)
experimentName = filename(1:end-4);
save(strcat(experimentName, '.mat'), 'allMaps', 'experimentName', 'stimPeriod', 'C');
 
displayMultiActivityMaps(allMaps, experimentName, 1);
