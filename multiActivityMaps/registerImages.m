function [offsets, xmin, xmax, ymin, ymax, biggestMapIndex] = registerImages(images)
% Takes cell array, each cell is a 2d or 3d image
% Usage:
% [offsets, xmin, xmax, ymin, ymax, biggestMapIndex] = registerImages(images)
% Inputs:
%  images: a cell array, each cell is a 2d or >2d image
%  the dimensions of the cell array should be N x 1
% Outputs:
%  offsets: N x 2 matrix giving the displacement of each image
%  xmin, xmax, ymin, ymax: because if the images are displaced from each
%  other, to line them up and only keep the part where they are
%  overlapping, you have to trim off the edges. These values give the
%  limits of the overlapping area
%  biggestMapIndex: the index of the image in the input cell array that had
%  the biggest image size
%
% Important: only registers in X and Y
%                                                                                                                                                                                                                                                                                                                          
%
% Example code for how to use the outputs (for 2D images)
%
% [offsets, xmin, xmax, ymin, ymax, biggestMapIndex] = registerImages(images)
% for i=1:length(images)
%     regImages{i} = images{i}((ymin - offsets(i,1)):(ymax - offsets(i,1)), ...
%         (xmin - offsets(i,2)):(xmax - offsets(i,2)));
% end
% 
% For N-D images, add the extra dimensions at the end, e.g.:
%     regImages{i} = images{i}((ymin - offsets(i,1)):(ymax - offsets(i,1)), ...
%         (xmin - offsets(i,2)):(xmax - offsets(i,2)),:,:,:);
% 
% Written by Andrew Lin
% Modified August 2017 to handle images with arbitrary numbers of
% dimensions (not just 2d images) but it will still only register along the
% first 2 dimensions ie x and y

numFiles = size(images,1);

for i=1:numFiles
    % if there are more than 2 dimensions for this image, average along the
    % other dimensions until you get a 2d image
    while (length(size(images{i})) > 2)
        images{i} = squeeze(mean(images{i},3));
    end
end

offsets = zeros(numFiles,2);
% make size
sizes = zeros(numFiles,2);

% register to the biggest map
biggestMapIndex = 0;
currentMaxSize = 0;
for i=1:numFiles
    mapSize = size(squeeze(images{i}(:)));
    if (mapSize(1) > currentMaxSize(1))
        currentMaxSize = mapSize;
        biggestMapIndex = i;
    end
end
map1 = images{biggestMapIndex};
% biggestMapIndex % for debugging

% size(map1) % for debugging
% images % for debugging
for i=1:numFiles
    cc = normxcorr2(images{i}, map1);
    % Use max
    % Rob's approach was to take an average of some above threshold?
    [~, imax] = max(cc(:));
    
    [ypeak, xpeak] = ind2sub(size(cc),imax(1));
    sizes(i,:) = size(images{i});
    offsets(i,:) = [ (ypeak-sizes(i,1)) (xpeak-sizes(i,2)) ];
end

% Get the appropriate limits for the overlaps based on offsets

xmin = max(offsets(:,2)) + 1;
xmax = min(sizes(:,2) + offsets(:,2));
ymin = max(offsets(:,1)) + 1;
ymax = min(sizes(:,1) + offsets(:,1));

% for debugging:
% offsets
% sizes
% xmin
% xmax
% ymin
% ymax
end