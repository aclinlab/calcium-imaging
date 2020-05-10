function result = correlateImages(images)
% input: images should be a cell array, each cell contains an N-dimensional
% image

numImages = length(images);
for i=1:numImages
    % if there are more than 2 dimensions for this image, average along the
    % other dimensions until you get a 2d image
    while (length(size(images{i})) > 2)
        images{i} = squeeze(mean(images{i},3));
    end
end

result = zeros(numImages);

for i=1:numImages
    for j=1:numImages
        result(i,j) = corr(images{i}(:), images{j}(:));
    end
end

end