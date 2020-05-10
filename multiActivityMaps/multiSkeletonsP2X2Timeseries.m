%PARAMETERS
% nodestdThresh. This is the standard deviation threshold for exclusion of
% skeleton nodes based on prePeriod activity
nodestdThresh = 1;

%set filepath
filePath = cd(uigetdir);
%find files matching expression 'normalizedSkeleton'
fileList = dir('*normalizedSkeleton*');
numFiles=length(fileList);
%Declare empty cell array
compositeResultsOverTime =cell(numFiles, 3);
compositeResultsATPTime  =cell(numFiles, 3);
compositeFrameTimes=zeros(numFiles,3);
compositeATPFrameTimes=zeros(numFiles,3);
numNodes=NaN;
frameTimes=cell(numFiles,1);
frameTime=0.2;
QTlength=Inf;
QTlengthATP=Inf;
for i=1:numFiles
    load(fileList(i).name)
        % make the composites to do the (vx2 - vx1)/vx1 
    % use string pattern matching to find the matching pairs vx2, vx1
    
    % get the descriptions into a single array
    descriptions = strings(length(allMaps),1);
    for j=1:length(allMaps)
        descriptions(j) = string(allMaps(j).params.description);
        thisNumNodes=length(allMaps(j).voronoiMeanResp);
        frameTimes{i}(j)=1/allMaps(j).frameRate;
        if isnan(numNodes)
            numNodes=thisNumNodes;
        else
            if numNodes~=thisNumNodes
                error("files have different length numNodes")
            end
        end
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
        % find the matching description with the same firstChar but with
        % '1' in the last position
        for k=1:length(odorAlonemapIndices)
            
            if firstChar==descriptions{odorAlonemapIndices(k)}(1)
                % ie (odor alone - odor+ATP) / (odor alone max for each segment)
                % (avg-avg)/max. Repmat division factor to match size of numerator
                mapDurationK=allMaps(odorAlonemapIndices(k)).nFrames/allMaps(odorAlonemapIndices(k)).frameRate;
                mapFrameTimeK=1/allMaps(odorAlonemapIndices(k)).frameRate;
                mapDurationJ=allMaps(odorATPmapIndices(j)).nFrames/allMaps(odorATPmapIndices(j)).frameRate;
                mapFrameTimeJ=1/allMaps(odorATPmapIndices(j)).frameRate;
                mapDuration=min([mapDurationK mapDurationJ]);
                QueryTime=(frameTime:frameTime:mapDuration);
                if length(QueryTime)<QTlength
                    QTlength=length(QueryTime);
                end
                interpTimeOdorATP=zeros(numNodes,QTlength);
                interpTimeOdorAlone=zeros(numNodes,QTlength);
                for n=1:numNodes
                    interpTimeOdorATP(n,:)=interp1(mapFrameTimeJ:mapFrameTimeJ:mapDurationJ, allMaps(odorATPmapIndices(j)).voronoiTimeSeries(n,:), QueryTime(1:QTlength));
                    interpTimeOdorAlone(n,:)=interp1(mapFrameTimeK:mapFrameTimeK:mapDurationK, allMaps(odorAlonemapIndices(k)).voronoiTimeSeries(n,:), QueryTime(1:QTlength));
                end
%                 normDiffTime = -(interpTimeOdorAlone - ...
%                     interpTimeOdorATP) ./ ...
%                     repmat((allMaps(odorAlonemapIndices(k)).voronoiMaxResp),1,QTlength);
%                 Uncomment either of these if you want to generate plots of
%                 Odor alone or Odor+ATP time series
                normDiffTime = interpTimeOdorAlone;
%                 normDiffTime = interpTimeOdorATP; 

                switch firstChar
                    case 'v'
                        compositeResultsOverTime{i,1} = normDiffTime;
                    case 'h'
                        compositeResultsOverTime{i,2} = normDiffTime;
                    case 'c'
                        compositeResultsOverTime{i,3} = normDiffTime;
                end
            end
        end
    end
    % Loop through the descriptions that have '3' in last position
    for y=1:length(ATPmapIndices)
        firstChar = descriptions{ATPmapIndices(y)}(1);
        % Check the sd of the response of each node during the prePeriod. If
        % this exceeds nodestdThreshold, set the voronoiMeanResp of that node to NaN
        mapDuration=allMaps(ATPmapIndices(y)).nFrames/allMaps(ATPmapIndices(y)).frameRate;
        mapFrameTime=1/allMaps(ATPmapIndices(y)).frameRate;
        stdNodes=std(allMaps(ATPmapIndices(y)).voronoiTimeSeries(:,allMaps(y).prePeriod),0,2);
        indexNodes=find(stdNodes>nodestdThresh);
        ATPavgTime = allMaps(ATPmapIndices(y)).voronoiTimeSeries;
        QueryTime=(frameTime:frameTime:mapDuration);
        if length(QueryTime)<QTlengthATP
            QTlengthATP=length(QueryTime);
        end
        interpTime=zeros(numNodes,QTlengthATP);
        for n=1:numNodes
            interpTime(n,:)=interp1(mapFrameTime:mapFrameTime:mapDuration, ATPavgTime(n,:), QueryTime(1:QTlengthATP));
        end
        %ATPavg(indexNodes)=NaN;
        switch firstChar
            case 'v'
                compositeResultsATPTime{i,1} = interpTime;
            case 'h'
                compositeResultsATPTime{i,2} = interpTime;
            case 'c'
                compositeResultsATPTime{i,3} = interpTime;
        end
    end
end

%Create a loop that goes through every voronoiTimeSeries for every
%recording and interpolates the values to 5 fps. Assumes that numNodes is equal length
%for all recordings. Put the interp. values into a interpMatrix
%Desired number of timepoints tPoints
% tPoints=250;
% %Preallocate
% interpMatrix=zeros(numFiles, 3, length(compositeResultsOverTime{i,1}(:,1)), tPoints);
% numNodes=length(compositeResultsOverTime{i,1}(:,1));
% for i=1:numFiles
% 
%     for c=1:3
%         if isempty(compositeResultsOverTime{i,c})
%             interpMatrix(i,c,:,:)=NaN;
%         else
%             mapFrametime=compositeFrameTimes(i,c);
%             mapDuration=allMaps(i).nFrames*mapFrametime;
%             for n=1:numNodes
%                 interpMatrix(i, c, n,:)=interp1(mapFrametime:mapFrametime:mapDuration, compositeResultsOverTime{i,c}(n,:), 0.2:0.2:50);
%             end
%         end
%     end
% end
% Preallocate interpolated matrix for averaging across files, for odour+ATP
% and ATP alone. If there are no odor recordings, QTlength = Inf. If so
% InterpMatrix gives error. Set QTlength=0 in this case.
if QTlength==Inf
    QTlength=0;
end
interpMatrix=zeros(numFiles,3,numNodes,QTlength);
% interpMatrixATP=zeros(numFiles,3,numNodes,QTlengthATP);
% for i=1:numFiles
%     for j=1:3
%         if isempty(compositeResultsOverTime{i,j})
%             interpMatrix(i,j,:,:)=NaN;
%         else
%         interpMatrix(i,j,:,:)=compositeResultsOverTime{i,j}(:,1:QTlength);
%         end
%         if isempty(compositeResultsATPTime{i,j})
%             interpMatrixATP(i,j,:,:)=NaN;
%         else
%         interpMatrixATP(i,j,:,:)=compositeResultsATPTime{i,j}(:,1:QTlengthATP);
%         end
%     end
% end

%Calculate average response in time across flies
avgTime=nanmean(interpMatrix,1);
% avgATPTime=nanmean(interpMatrixATP,1);
%Squeeze to remove singleton
avgTime=squeeze(avgTime);
% avgATPTime=squeeze(avgATPTime);

% Create a variable branchNumbers that stores the indices of the various
% branches, and use this to plot the time series from calyx->vertical and
% calyx->horizontal
branchNumbers = [allMaps(1).skel.spacedNodes.branchNumber];
branchIndices=cell(3,1);
for i=1:3
    branchIndices{i}=find(branchNumbers==i);
end
% CtoV: calyx-->vertical (branch 2 inverted, then 1)
mergeBranchesCtoV=[fliplr(branchIndices{2}),branchIndices{1}];
% CtoH: calyx-->horizontal (branch 2 inverted, then first element of branch 1 (the junction), then branch 3)
mergeBranchesCtoH=[fliplr(branchIndices{2}),branchIndices{1}(1),branchIndices{3}];
   
% Plot average response in time for each node separately for all 3
% conditions. Make separate averages for CtoH and CtoV
% odour+ATP
valuesCtoH=(1:length(mergeBranchesCtoH));
maxValueCtoH = max(valuesCtoH(:));
minValueCtoH = min(valuesCtoH(:));
cmap = colormap;
colors = cmap(round((valuesCtoH-minValueCtoH)*63/(maxValueCtoH-minValueCtoH))+1,:);
for c=1:3
    figure
    for n=1:length(mergeBranchesCtoH)
        plot((1:QTlength)*frameTime-20, squeeze(avgTime(c,mergeBranchesCtoH(n),:)), 'Color', colors(n,:))
        hold on
    end
    %Manually set the axis limits and font options desired for the figures
    set(gca, 'xlim',[-5,15])
    set(gca, 'ylim',[-1.5,1.5])
    set(gca, 'FontName', 'Times New Roman');
    set(gca,'FontSize',22)
    %     Draw a dashed horizontal line at y=0
    xL = get(gca, 'XLim');
    plot(xL, [0 0], '--k')
    %     Create shaded box in the specified area to show stimulus window
    patch([0 2.5 2.5 0], [-1.5 -1.5 1.5 1.5],'r')
    %     Set transparency of the patch to desired value
    alpha(0.2)
    hold off
end
valuesCtoV=(1:length(mergeBranchesCtoV));
maxValueCtoV = max(valuesCtoV(:));
minValueCtoV = min(valuesCtoV(:));
cmapCtoV = colormap;
colorsCtoV = cmapCtoV(round((valuesCtoV-minValueCtoV)*63/(maxValueCtoV-minValueCtoV))+1,:);
for c=1:3
    figure
    for n=1:length(mergeBranchesCtoV)
        plot((1:QTlength)*frameTime-20, squeeze(avgTime(c,mergeBranchesCtoV(n),:)), 'Color', colorsCtoV(n,:))
        hold on
    end
    %Manually set the axis limits and font options desired for the figures
    set(gca, 'xlim',[-5,15])
    set(gca, 'ylim',[-1.5,1.5])
    set(gca, 'FontName', 'Times New Roman');
    set(gca,'FontSize',22)
    %     Draw a dashed horizontal line at y=0
    xL = get(gca, 'XLim');
    plot(xL, [0 0], '--k')
    %     Create shaded box in the specified area to show stimulus window
    patch([0 2.5 2.5 0], [-1.5 -1.5 1.5 1.5],'r')
    %     Set transparency of the patch to desired value
    alpha(0.2)
    hold off
end

% Repeat for ATP only

% valuesCtoHATP=(1:length(mergeBranchesCtoH));
% maxValueCtoHATP = max(valuesCtoHATP(:));
% minValueCtoHATP = min(valuesCtoHATP(:));
% cmap = colormap;
% colors = cmap(round((valuesCtoHATP-minValueCtoHATP)*63/(maxValueCtoHATP-minValueCtoHATP))+1,:);
% for c=1:3
%     figure
%     for n=1:length(mergeBranchesCtoH)
%         plot((1:QTlengthATP)*frameTime-15, squeeze(avgATPTime(c,mergeBranchesCtoH(n),:)), 'Color', colors(n,:))
%         hold on
%     end
%     %Manually set the axis limits and font options desired for the figures
%     set(gca, 'xlim',[-5,15])
%     set(gca, 'ylim',[-0.2,5])
%     set(gca, 'FontName', 'Times New Roman');
%     set(gca,'FontSize',22)
%     %     Draw a dashed horizontal line at y=0
%     xL = get(gca, 'XLim');
%     plot(xL, [0 0], '--k')
%     %     Create shaded box in the specified area to show stimulus window
%     patch([0 2.5 2.5 0], [-0.2 -0.2 5 5],'r')
%     %     Set transparency of the patch to desired value
%     alpha(0.2)
%     hold off
% end
% valuesCtoVATP=(1:length(mergeBranchesCtoV));
% maxValueCtoVATP = max(valuesCtoVATP(:));
% minValueCtoVATP = min(valuesCtoVATP(:));
% cmapCtoV = colormap;
% colorsCtoV = cmapCtoV(round((valuesCtoVATP-minValueCtoVATP)*63/(maxValueCtoVATP-minValueCtoVATP))+1,:);
% for c=1:3
%     figure
%     for n=1:length(mergeBranchesCtoV)
%         plot((1:QTlengthATP)*frameTime-15, squeeze(avgATPTime(c,mergeBranchesCtoV(n),:)), 'Color', colorsCtoV(n,:))
%         hold on
%     end
%     %Manually set the axis limits and font options desired for the figures
%     set(gca, 'xlim',[-5,15])
%     set(gca, 'ylim',[-0.2,5])
%     set(gca, 'FontName', 'Times New Roman');
%     set(gca,'FontSize',22)
%     %     Draw a dashed horizontal line at y=0
%     xL = get(gca, 'XLim');
%     plot(xL, [0 0], '--k')
%     %     Create shaded box in the specified area to show stimulus window
%     patch([0 2.5 2.5 0], [-0.2 -0.2 5 5],'r')
%     %     Set transparency of the patch to desired value
%     alpha(0.2)
%     hold off
% end
%Draw CtoH and CtoV distance-colored skeletons
DrawMergeBranchesCtoH=NaN(numNodes,1);
for i=1:length(mergeBranchesCtoH)
    DrawMergeBranchesCtoH(mergeBranchesCtoH(i))=i;
end
allMaps(1).skel.drawSkeleton(DrawMergeBranchesCtoH)

DrawMergeBranchesCtoV=NaN(numNodes,1);
for i=1:length(mergeBranchesCtoV)
    DrawMergeBranchesCtoV(mergeBranchesCtoV(i))=i;
end
allMaps(1).skel.drawSkeleton(DrawMergeBranchesCtoV)

