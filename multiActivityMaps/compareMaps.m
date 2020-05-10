function result = compareMaps(maps, defineSubarea, f0Thres, varargin)
% compareMaps: calculate sparseness and inter-stimulus correlation for a
% set of activity maps
% 
% Usage:
% compareMaps(maps, defineSubarea, f0Thres, whichChannel)
% Inputs:
%  maps: N x 1 array of activityMap objects
%  defineSubarea: how to decide what pixels to exclude from the analysis
%  (i.e. you should not include pixels with no GCaMP fluorescence as that would
%  make the response seems sparser than it really is)
%       0: let the function automatically create a mask by thresholding the
%          F0 signal by f0Thres
%       -1: get user to trace out what to EXclude from the mask that's
%           automatically created by the function
%           ex. you might want to do this to exclude the calyx from
%           analysis of KC cell body responses
%       1: get user to trace out what to INclude from the mask that's
%          automatically created by the function
%       a matrix: use that as the mask
%  f0Thres: threshold to use to automatically create the mask (i.e. include
%           pixels that have a higher f0 than f0Thres)
%  whichChannel: optional parameter, which channel to use to create the
%                for excluding irrelevant pixels (default = 1)
%
% Output:
%  returns a struct with the following fields:
%   corrMatrix: N x N matrix of correlations between each map
%   scrambledcorrMatrix: a negative control. N x N matrix of correlations
%    between each map where the pixels in each map have been scrambled.
%    Scrambled correlations should be ~0!
%   angsepMatrix: N x N matrix of angular separation between each map
%    (i.e., cosine distance). This is similar to correlation.
%   sparseness: N x 1 matrix of the population sparseness of each map,
%    calculated pixel-wise
%   offsets: store the xy offsets needed to register the maps to each other
%    according to their F0
%   linearMapMatrix: N X P matrix, where P is the number of pixels inside
%    the mask. Each row is one linearized activity map (i.e. 3D map
%    converted into a linear vector)
%   mask: the mask that was used to exclude pixels with no baseline
%    fluorescence or pixels that aren't relevant to the analysis
%   f0Thres: the threshold that was used to automatically determine which 
%    pixels are included in the analysis (before any manual inclusion or
%    exclusion according to defineSubarea)

% modified by Andrew Lin August 2017 to change how it deals with masking
% the input
% also to let it deal with 3D stacks instead of only 2D images
% modified by Andrew Lin May 2018 to work with the activityMap class
% modified by Andrew Lin and Hoger Amin Sept 2018 to operate on
% multi-channel maps. Verified that it still works the same on
% single-channel maps.
% also changed angsepMatrix - previously it was cosine similarity, but now
% it is 1 - cosine similarity, or true angular separation.

% this is for binning when images are too big
% currently not being used
% resize_factor=0.3;

if nargin==4
    whichChannel = varargin{1};
elseif nargin==3
    whichChannel = 1;
else
    error('Wrong number of arguments');
end
    

numFiles = size(maps, 1);

% create cell array of all the F0's from every map
% need to transpose because registerImages expects an N x 1 cell array
f0s = {maps.f0}';
% register all the F0's to each other
[offsets, xmin, xmax, ymin, ymax, ~] = registerImages(f0s);

% KLUDGE: get the z and channel dimension from the first F0 stack. This doesn't
% work if some of the stacks have different z dimensions! Come back to this
% later to fix it
xDim = xmax - xmin + 1;
yDim = ymax - ymin + 1;
zDim = size(f0s{1},3);
cDim = size(f0s{1},4);

% Place the activity maps according to the offsets from F0 alignment

registeredMaps = zeros(numFiles, yDim, xDim, zDim, cDim);
%registeredMapsNoThres = zeros(numFiles, yDim, xDim, zDim, cDim);
% binSize = size(imresize(squeeze(registeredMaps(1,:,:,1,1)),resize_factor,'box'));
% binRegisteredMaps = zeros(numFiles, binSize(1), binSize(2), zDim, numMaps);
meanf0 = zeros(yDim, xDim, zDim);
for i=1:numFiles
    registeredMaps(i,:,:,:,:) = maps(i).dff((ymin - offsets(i,1)):(ymax - offsets(i,1)),(xmin - offsets(i,2)):(xmax - offsets(i,2)),:,:);
    %registeredMapsNoThres(i,:,:,:,:) = maps(i).dffNoThres((ymin - offsets(i,1)):(ymax - offsets(i,1)),(xmin - offsets(i,2)):(xmax - offsets(i,2)),:,:);
    meanf0 = meanf0 + f0s{i}((ymin - offsets(i,1)):(ymax - offsets(i,1)),(xmin - offsets(i,2)):(xmax - offsets(i,2)),:,whichChannel);
end
%meanRegisteredMaps = squeeze(mean(registeredMaps,1)); 

% calculate a "maximum-intensity projection" thgouth all the different
% activity maps

maxRegisteredMaps = max(registeredMaps,[],1);

% get rid of leading singleton dimension, which was the map number
maxRegisteredMaps = shiftdim(maxRegisteredMaps,1);
    %        binRegisteredMaps(i,:,:,:,m)=imresize(squeeze(registeredMaps(i,:,:,:,m)),resize_factor,'box');
meanf0 = meanf0 ./ numFiles;

% Register a mask for F0
size(maxRegisteredMaps)
size(permute(maxRegisteredMaps, [2 1 3 4]))
size(permute(meanf0, [2 1 3 4]))

[montageRGB, montageDims] = ...
    stackToMontage(overlayColorOnGrayscale(permute(maxRegisteredMaps(:,:,:,whichChannel), [2 1 3]), ...
    permute(meanf0, [2 1 3]), [0 2], 0));

if isscalar(defineSubarea)
    f0Mask = meanf0; 
    % binFpremeanMask=imresize(fpremeanMask,resize_factor,'box');
    f0Mask(f0Mask < f0Thres) = 0;
    f0Mask(f0Mask >= f0Thres) = 1;
    % binFpremeanMask(binFpremeanMask < fpremeanThres)= 0;
    % binFpremeanMask(binFpremeanMask >= fpremeanThres)= 1;
    if defineSubarea
        if (defineSubarea==-1)
            fig = figure('Name','Choose region to EXclude out of the automatically defined mask (green)');
        elseif (defineSubarea==1)
            fig = figure('Name','Choose region to INclude from the automatically defined mask (green)');
        else
            error('Invalid parameter defineSubarea');
        end
        imagesc(montageRGB);
        alphamask(edge(stackToMontage(permute(f0Mask, [2 1 4 3]))), [0 1 0], 1);
        
        % ask user to select area to exclude or include
        maskMontage = multiROI(fig, gca);

        maskStack = montageToStack(maskMontage,montageDims);
        maskStack = permute(maskStack, [2 1 3 4]);
        % for debugging:
        %         size(f0Mask)
        %         size(maskStack)
        if (defineSubarea==-1)
            maskStack = ~maskStack;
        end
        f0Mask = f0Mask.*maskStack;
    end
else
    % if the passed-in parameter is already a matrix, just use that as the
    % mask
    if size(defineSubarea)==size(meanf0)
        f0Mask = defineSubarea;
    else
        disp('meanfpremean size:\n');
        size(meanf0);
        disp('defineSubarea size:\n');
        size(defineSubarea);
        error('the mask is the wrong size!\n');
    end

end
f0Mask = logical(f0Mask);

figure('Name', 'How the response looks like on top of your mask');
imagesc(montageRGB, [0 200]);
colormap hot;
size(f0Mask)
alphamask(stackToMontage(permute(f0Mask, [2 1 4 3]),montageDims(1), montageDims(2)), [0 0 1], 0.5);





%find(isnan(registeredMaps))

% linearMapMatrix takes each 2d map and turns it into a linear array (masked by
% f0Mask)
numPixels = size(f0Mask(f0Mask==1));
numPixels = numPixels(1,1);
linearMapMatrix = zeros(numFiles, numPixels, cDim);
%linearMapMatrixNoThres = zeros(numFiles, numPixels, cDim);
[corrMatrix, scrambledcorrMatrix, angsepMatrix, f0corrMatrix] = deal(zeros(numFiles, numFiles, cDim, cDim));
% scrambledcorrMatrix = corrMatrix;
% angsepMatrix = corrMatrix;
% f0corrMatrix = corrMatrix;
sparseness = zeros(numFiles, cDim);


% numBinPixels = size(binFpremeanMask(binFpremeanMask==1));
% numBinPixels = numBinPixels(1,1);
% binMapMatrix = zeros(numFiles, numBinPixels, numMaps);
for i=1:numFiles
    for j=1:cDim
        map1 = squeeze(registeredMaps(i,:,:,:,j));
        %map1NoThres = squeeze(registeredMapsNoThres(i,:,:,:,j));
        linearMapMatrix(i,:,j) = map1(f0Mask > 0.5);
        %linearMapMatrixNoThres(i,:,j) = map1NoThres(f0Mask > 0.5);
    end
end


% Get correlations between each activity map
for i=1:numFiles
    for c=1:cDim
        % need to transpose to make it a column array instead of row
        linearmap1 = squeeze(linearMapMatrix(i,:,c))';
        
        %     max(map1(:))
        %     max(linearmap1(:))
        %     min(linearmap1(:))
        %    binMap1 = squeeze(binRegisteredMaps(i,:,:));
        %    binLinearmap1 = binMap1(binFpremeanMask > 0.5);
        for j=1:numFiles
            for d=1:cDim
                
                linearmap2 = squeeze(linearMapMatrix(j,:,d))';
                
                %       binMap2 = squeeze(binRegisteredMaps(j,:,:));
                %       binLinearmap2 = binMap2(binFpremeanMask > 0.5);
                corrMatrix(i,j,c,d) = corr(linearmap1, linearmap2);
                
                %       binCorrMatrix(i,j) = corr(binLinearmap1, binLinearmap2);
                scrambledcorrMatrix(i,j,c,d) = ...
                    corr(linearmap1(randperm(size(linearmap1,1))), ...
                    linearmap2(randperm(size(linearmap2,1))));
                
                angsepMatrix(i,j,c,d) = pdist2(linearmap1',linearmap2','cosine');
                
                f0i = f0s{i}((ymin - offsets(i,1)):(ymax - offsets(i,1)),(xmin - offsets(i,2)):(xmax - offsets(i,2)),:,c);
                f0i = f0i(f0Mask > 0.5);
                f0j = f0s{j}((ymin - offsets(j,1)):(ymax - offsets(j,1)),(xmin - offsets(j,2)):(xmax - offsets(j,2)),:,d);
                f0j = f0j(f0Mask > 0.5);
                f0corrMatrix(i,j,c,d) = corr(f0i(:),f0j(:));
                
                if (isnan(corrMatrix(i,j,c,d)))
                    fprintf('Warning: NaN for indices %d and %d between channels %d and %d\n', i, j, c, d);
                end
                
            end
        end
    end
    
end

% % get dF/F time courses of entire area where f0mask==1
% timecourses = cell(numFiles,1);
% maxDFFs = cell(numFiles,1);
% meanDFFs = cell(numFiles,1);
% for i=1:numFiles
%     
%     [movie, ~] = readScanImageTiffLinLab(strcat(maps(i).params.pathName,maps(i).params.fileName));
%     movie = single(movie);
%     movie = movie - maps(i).params.bkgnd; % possible bug point if bkgnd is not a scalar!
%     
%     % apply offsets in case the activityMap object has been
%     % registered
%     movie = movie((ymin - offsets(i,1)):(ymax - offsets(i,1)),(xmin - offsets(i,2)):(xmax - offsets(i,2)),:,:,:);
% 
%     % calculate the timecourse of dFF for each channel
%     timecourses{i} = zeros(maps(i).nFrames,maps(i).nChannels);
%     maxDFFs{i} = zeros(maps(i).nChannels,1);
%     for c=1:maps(i).nChannels
%         for t=1:maps(i).nFrames
%             thisFrame = squeeze(movie(:,:,:,c,t));
%             timecourses{i}(t,c) = mean(thisFrame(f0Mask));
%         end
%         f0 = f0s{i}((ymin - offsets(i,1)):(ymax - offsets(i,1)),(xmin - offsets(i,2)):(xmax - offsets(i,2)),:,c);
%         meanf0 = mean(f0(f0Mask));
%         timecourses{i}(:,c) = (timecourses{i}(:,c) - meanf0)/meanf0;
%         % get the max dF/F during the first stimPeriod
%         firstStimPeriod = intersect(maps(1).stimPeriod, maps(1).getFramesFromLimits(maps(1).params.stimLimits(1,:)));
%         maxDFFs{i}(c) = max(timecourses{i}(firstStimPeriod,c));
%         meanDFFs{i}(c) = mean(timecourses{i}(firstStimPeriod,c));
%     end
% end
% 
% % concatenate the cell array timecourses into a matrix padded with NaNs
% % copied from https://uk.mathworks.com/matlabcentral/answers/48869-concatenation-with-array-of-different-dimensions
% k = cellfun(@numel,timecourses);
% result.meanDFFtimecourses = nan(max(k),numFiles);
% c = cellfun(@numel,maxDFFs);
% result.maxDFFs = zeros(numFiles,max(c));
% result.meanDFFs = zeros(numFiles,max(c));
% for i = 1:numFiles
%     result.meanDFFtimecourses(1:k(i),i) = timecourses{i}(:); % NOTE this will give some nonsense if there is more than 1 channel!!
%     result.maxDFFs(i,1:c(i)) = maxDFFs{i}(:);
%     result.meanDFFs(i,1:c(i)) = meanDFFs{i}(:);
% end



% % Get distances between each activity map
% %distMatrix = squareform(pdist(linearMapMatrix));
% 
% % Get angular separation between each activity map
% % i.e. cosine distance
% mag_linearMapMatrix = squeeze(sqrt(sum(linearMapMatrix.*linearMapMatrix,2)));
% for i=1:numFiles
%     for j=1:numFiles
%         angsepMatrix(i,j) = dot(squeeze(linearMapMatrix(i,:)), ...
%             squeeze(linearMapMatrix(j,:))) ...
%             /(mag_linearMapMatrix(i)*mag_linearMapMatrix(j));
%     end
% end

for i=1:numFiles
    for c= 1:cDim
        map1 = squeeze(linearMapMatrix(i,:,c));
        sparseness(i,c) = (1 - (sum(map1./numPixels))^2/sum(map1.^2/numPixels))/(1-1/numPixels);
    end
end

result.corrMatrix = corrMatrix;
result.scrambledcorrMatrix = scrambledcorrMatrix;
result.angsepMatrix = angsepMatrix;
result.sparseness = sparseness;
result.offsets = offsets;
result.linearMapMatrix = linearMapMatrix;
result.mask = f0Mask;
result.f0Thres = f0Thres;
result.f0corrMatrix = f0corrMatrix;
%result.meanDFFoverArea = mean(linearMapMatrixNoThres,2);

end