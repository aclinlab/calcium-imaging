function SI = parseFijiScanImageMetadata(filename)


% Written by Andrew Lin, andrew.lin@sheffield.ac.uk

metadataText = fileread(filename);

% in Fiji metadata, the ScanImage metadata appears after the string
% 'Software = '
startKey = 'Software = ';
% in some Fiji files, there is a line ----------------- after the ScanImage
% metadata
endKey = '---------------------';

startIndex = strfind(metadataText, startKey);
if isempty(startIndex)
    startIndex = 1;
else
    % startIndex(end) in case strfind returns multiple places where startKey occurs
    startIndex = startIndex(end) + length(startKey);
end

endIndex = strfind(metadataText, endKey);
if isempty(endIndex)
    endIndex = length(metadataText);
else
    endIndex = endIndex(1) - 1;
end

ScanImageMetadataText = metadataText(startIndex:endIndex);
SI = parseScanImageMetadata(ScanImageMetadataText);

end