function [result, SI] = readScanImageTiffLinLab(fileName)
% readScanImageTiffLinLab:
% Uses ScanImageTiffReader to read in a ScanImage file with the name
% fileName
% We use this because scanimage.util.opentif is unbearably slow
% 
% Usage:
% [result, SI] = readScanImageTiffLinLab(fileName);
% - result is a a 5D matrix in the order: x, y, z, channels, time
% If any of these are singletons, eg only one channel, they are kept as 
% singletons (the result is not squeezed)
% - SI holds the metadata as original created by ScanImage (possibly with
% some extra fields if the file was modified by our Fiji macros)
%
% Usage notes:
% If the metadata isn't there (eg because the .tif was created in Fiji),
% the function looks for an accompanying metadata text file
% If fileName is example.tif, the metadata file should be called
% example-metadata.txt
% If you lack the metadata file from a file created in Fiji, use the macro 
% 'saveMetadataAsText' in Fiji

% Written by Andrew Lin, andrew.lin@sheffield.ac.uk

tic

reader = ScanImageTiffReader(fileName);

metadataText = reader.metadata;

if isempty(metadataText)
    % look for the accompanying text file
    suffixIndex = strfind(fileName,'.');
    suffixIndex = suffixIndex(end);
    metadataFileName = strcat(fileName(1:(suffixIndex-1)),'-metadata.txt');
    SI = parseFijiScanImageMetadata(metadataFileName);
else
    SI = parseScanImageMetadata(metadataText);
end

movie = reader.data();
dimensions = size(movie);

% linesPerFrame = SI.hRoiManager.linesPerFrame;
% pixelsPerLine = SI.hRoiManager.pixelsPerLine;
numChannels = length(SI.hChannels.channelSave);

% in raw ScanImage data, the discarded flyback slices are retained in the
% movie file
% thus, if you want 10 slices and have 2 flyback slices, the parameters
% will be:
% SI.hFastZ.discardFlybackFrames = true
% SI.hStackManager.numSlices = 10
% SI.hFastZ.numFramesPerVolume = 12
% SI.hFastZ.numDiscardFlybackFrames = 2
% however, the Lin lab Z-registration Fiji plugin deletes the blank slices
% so in the above example, there would only be 10 slices, and no blank
% slices
% The code below deletes the blank slices but only if they are there.

% first check if ScanImage blanked the flyback frames, then check if the
% flybak frames have been deleted. If not, delete them
if (SI.hFastZ.discardFlybackFrames && ~SI.LinLab.flybackFramesDeleted)
    if ((SI.hFastZ.numFramesPerVolume - SI.hFastZ.numDiscardFlybackFrames) ~= SI.hStackManager.numSlices)
        SI.hFastZ.numFramesPerVolume
        SI.hFastZ.numDiscardFlybackFrames
        SI.hStackManager.numSlices
        error('Something is wrong with the ScanImage z parameters\n');
    end
    % reshape into dimensions: x y c z t
    result = reshape(reader.data(), dimensions(1), dimensions(2), ...
       numChannels,  SI.hFastZ.numFramesPerVolume, ...
        ceil(dimensions(3)/(SI.hFastZ.numFramesPerVolume*numChannels)));
    % now delete the last SI.hFastZ.numDiscardFlybackFrames z-slices
    result = result(:,:,:,1:(end-SI.hFastZ.numDiscardFlybackFrames),:);
else
    numSlices = SI.hStackManager.numSlices;
    if mod(dimensions(3), numSlices*numChannels)
        error('numFrames does not divide evenly by numSlices and numChannels');
    end
    % reshape into dimensions: x y c z t
    result = reshape(reader.data(), dimensions(1), dimensions(2), ...
        numChannels, numSlices, ceil(dimensions(3)/(numSlices*numChannels)));
end
% reorder into x y z c t
% the reason reshape used x y c z t instead of x y z c t is that
% channels are acquired simultaneously whereas z is acquired
% sequentially using the piezo. Thus channels are closer together in
% the interleaved file than z slices.
result = permute(result, [1 2 4 3 5]);

disp('Total time to read in file was: ');
toc
end