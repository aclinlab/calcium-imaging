function SI = parseScanImageMetadata(metadataText)

% takes a string like
% SI.LINE_FORMAT_VERSION = 1
% SI.TIFF_FORMAT_VERSION = 3
% SI.VERSION_MAJOR = '5.2'
% SI.VERSION_MINOR = '2'
% SI.acqState = 'grab'
% SI.acqsPerLoop = 1
% SI.extTrigEnable = 1
% [etc]
% and runs eval to return a structure with the correct values


% Written by Andrew Lin, andrew.lin@sheffield.ac.uk

% add semi-colon to the end of each line to prevent eval from displaying
% the results
eval(strrep(metadataText, char(10), strcat(';',char(10))));

% default values for LinLab-specific parameters
if ~(isfield(SI,'LinLab')&&isfield(SI.LinLab,'flybackFramesDeleted'))
    SI.LinLab.flybackFramesDeleted = false;
end

end