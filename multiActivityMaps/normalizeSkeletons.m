function skeletons = normalizeSkeletons(filenames, spacing)

% Let's start with filenames as an cell array of strings specifying the .mat
% files

% calling function must supply the value of 'spacing' which is the node
% spacing on the 'standardized' skeleton

% The purpose of this function is normalize the lengths of the vertical
% lobe, peduncle, and horizontal lobes to single "standard" lengths
% each file will be a .mat file containing multiple activityMap objects -
% they would all have the same skeleton but would be different movies (e.g.
% odor, odor+ATP, ATP alone, and the pipette in different locations)

% Let's try returning the array of skeleton objects ('skeletons')

numFiles = length(filenames);

% length will store the length of each branch in each file
lengths = zeros(numFiles,3); % 1 = v, 2 = p, 3 = h
% junctionIndices will store the index of the node on each skeleton that is
% the junction
junctionIndices = zeros(numFiles,1);

for i=1:numFiles
    
    % loop through all files
    %  read in .mat file
    load(filenames{i}); % assumes the .mat file contains a variable called allMaps
    %  just take the 1st skeleton in allMaps because they shoudl all have
    %  the same skeleton
    skeletons(i) = allMaps(1).skel;
    
    %   find the node that has >2 connections - that's the junction
    nodeLinks = {skeletons(i).nodes.links};
    numLinksPerNode = zeros(length(nodeLinks),1);
    for j=1:length(nodeLinks)
        numLinksPerNode(j) = length(nodeLinks{j});
    end
    
    [maxLinks,junctionIndices(i)] = max(numLinksPerNode);
    if maxLinks~=3
        error('the node with the most links does not have 3 links!');
    end
    % to measure its peduncle, vertical lobe and
    %  horizontal lobe
    %   just measure the distance along the skeleton between each end point and
    %   the junction
    % We assume that the skeleton is always drawn from vertical lobe tip to
    % calyx, then the horizontal lobe is added from junction to horizontal
    % lobe tip last.
    % Thus endNodes are in the order: vertical, calyx, horizontal
    endNodes = skeletons(i).findEndNodes();

    % Get the distances from the junction node to all nodes in the skeleton
    [distances,~] = skeletons(i).getDistances(junctionIndices(i));
    
    if length(endNodes)~=3
        error('number of endNodes ~= 3!');
    end
    
    lengths(i,:) = distances(endNodes);
    
end
meanLengths = mean(lengths,1);

% Divide every length by the mean length for that lobe
stretchFactors = lengths./repmat(meanLengths, numFiles, 1);

% Loop over all files again
% For each set of 9 skeletons (each file), modify the skeleton
for i=1:numFiles
    % label the branches (divide the skeleton into segments)
    % see comment on the labelBranches function - follow the convention of
    % v = 1, p = 2, c = 3
    skeletons(i) = skeletons(i).labelBranches();
    
    % Re-draw the  spaced nodes, emanating from the junction
    % Set the starting point to be the junction
    skeletons(i).userStartingPoint = skeletons(i).nodes(junctionIndices(i)).realCoords;
    % skeletons(i).userStartingPoint = skeletons(i).nodes(1).realCoords; % for debugging
    skeletons(i) = skeletons(i).createSpacedNodes(spacing*stretchFactors(i,:));
    skeletons(i) = skeletons(i).createVoronoiMask();
end

end