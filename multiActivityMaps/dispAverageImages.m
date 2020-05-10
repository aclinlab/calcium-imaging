function [] = dispAverageImages(images)
% input: images should be a cell array, each cell contains a 4-dimensional
% image
% displays a montage of channel 1, averaged across all images in the cell
% array

nDims= length(size(images{1}));
ImgAverage=mean(cat(nDims+1,images{:}),nDims+1);
figure
imagesc(stackToMontage(permute(ImgAverage(:,:,:,1), [2,1,4,3])))
axis equal, axis tight

end