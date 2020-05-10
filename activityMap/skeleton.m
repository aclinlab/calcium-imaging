classdef skeleton
    % skeleton: Class for defining and analysing skeletons of 3D objects
    % This class allows you to take a mask of an object (eg the mushroom
    % body), manually define a skeleton by clicking on a montage of the
    % mask, and define a "starting point" (eg where stimulation was locally
    % applied). Then it will create a series of evenly spaced nodes on the
    % skeleton to divide up the object evenly into 'zones' of certain
    % distances from the starting point
    %
    % Instructions for use:
    % Draw a mask based on channel 2 of an activityMap object, 'map':
    % >> mask = activityMap.outlineObject(map.f0, 2); 
    %
    % Create the skeleton object:
    % >> skel = skeleton(mask, map.pixelCal); 
    % This will then display the mask as a montage. The user then clicks a
    % few points in order to define one branch of the skeleton. (Single
    % click to add a point; double click to finish; or press <Return> when
    % you're finished.)
    % A dialog then pops up: add another branch or done? If you want to add
    % another branch, the new branch will connect to the existing skeleton:
    % from the *first* point on the new branch to whatever point on the
    % eixsting skeleton is closest
    %
    % Define a starting point:
    % >> skel = skel.defineStartingPoint(map.f0(:,:,:,2));
    % This will display the inputted image in a montage, and you click a
    % single point to say where the local stimulation occurred (again,
    % press <Return> when finished)
    %
    % Create spaced node skeleton: user defines spacing in microns
    % >> skel = skel.createSpacedNodes(20); % 20 micron spacing
    %
    % Create Voronoi divisions according spaced node skeleton
    % >> skel = skel.createVoronoiMask();
    %
    % See the results!
    % >> skel.drawSkeleton();
    
    % WARNINGS:
    % the first 2 dimensions of pixelCal (x and y) may not be in the right
    % order. This probably doesn't matter because the microscope should be
    % calibrated to give square images in xy.
    %
    % Written by Andrew Lin and Hoger Amin
    properties
        mask % binary mask defining what voxels are in the object
        voronoiMask = [] % each voxel in the mask is assigned to one node in spacedNodes
        nodes = [] % the user-defined nodes of the skeleton
        links = [] % links between the user-defined nodes (n x 2 matrix)
        spacedNodes = [] % nodes that are 'spacing' microns apart along the skeleton
        spacedLinks = [] % links between spaced nodes
        userStartingPoint = [] % user defines a point in space
        startingPoint = [] % the point on the skeleton closest to userStartingPoint
        startingLink = [] % which link (in links) is startingPoint on
        pixelCal % how many microns per pixel in each dimension (x y z) (1x3 matrix)
        numBranches

        %        spacing = 20 % how far apart should the nodes in spacedNodes be

        
    end
    
    methods
        function obj = skeleton(inputMask, inputPixelCal)
            %
            
            obj.mask = inputMask;
            obj.pixelCal = inputPixelCal;
            
            % display the mask in montage form
            maskFigHandle= figure('Name','Click points for skeleton');
            [montageMask, montageDims] = stackToMontage(permute(obj.mask,[2 1 4 3]));
            imagesc(montageMask);
            axis equal, axis tight;
            
            % manually enter points IN ORDER of the line
            [x_in, y_in] = getpts(maskFigHandle);
            
            % Then need to turn this into x y z coordinates
            [x,y,z] = montageXYToStackXYZ(x_in,y_in,[size(obj.mask,1) size(obj.mask,2)],montageDims);
            % each of x, y and z is a nx1 vector where n is the number of points
                        
            % Now link these points together in a network:
            pixelCoords = [x, y, z];
            realCoords = obj.pixelsToMicrons(pixelCoords);
            
            branchNumber = 1;
            obj = obj.appendGraphNodes(realCoords, branchNumber);
            
            % while still adding new branches
            roiLoop = 1;
            while(roiLoop)
                nextAction = menu('Choose an option','Add another branch','Done');
                if nextAction == 1
                    % enter the points IN ORDER: 
                    % the first point will be linked to the existing
                    % skeleton!
                    [x_in, y_in] = getpts(maskFigHandle);
                    [x,y,z] = montageXYToStackXYZ(x_in,y_in,[size(obj.mask,1) size(obj.mask,2)],montageDims);
                    pixelCoords = [x, y, z];
                    realCoords = obj.pixelsToMicrons(pixelCoords);
                    branchNumber = branchNumber + 1;
                    obj = obj.appendGraphNodes(realCoords, branchNumber);
                elseif nextAction == 2
                    roiLoop = 0;
                end
            end
            close(maskFigHandle);
            
        end
        
        function obj = defineStartingPoint(obj, image)
            % image must be a 3d image
            image = squeeze(image);
            if size(image)~=size(obj.mask)
                error('defineStartingPoint: input image is not the same size as the mask');
            end
            figHandle = figure('Name', 'Click on the starting point, then press <return>');
            [montageImage, montageDims] = stackToMontage(permute(image,[2 1 4 3]));
            imagesc(montageImage);
            axis equal, axis tight;
            
            % manually enter a point
            [x_in, y_in] = getpts(figHandle);
            [x, y, z] = montageXYToStackXYZ(x_in,y_in,[size(obj.mask,1) size(obj.mask,2)],montageDims);
            
            obj.userStartingPoint = obj.pixelsToMicrons([x, y, z]);
            
            close(figHandle);
        end
        
        function obj = appendGraphNodes(obj, realCoords, branchNumber)
            % link up all the inputted points in realCoords into a single linear
            % branch
            branchNodes = [];
            branchLinks = [];
            for i=1:size(realCoords,1)
                branchNodes(i).realCoords = realCoords(i,:);
                if i<2
                    prevNode = [];
                else
                    prevNode = i-1;
                end
                if i==size(realCoords,1)
                    nextNode = [];
                else
                    nextNode = i+1;
                end
                branchNodes(i).links = [prevNode nextNode];
                if ~isempty(nextNode)
                    branchLinks = [branchLinks; [i, nextNode, branchNumber]];
                end
            end
            
            % append this branch to the nodes/links of this object
            
            if ~isempty(obj.nodes) && ~isempty(obj.links)
                
                % find the point on the existing links that is closest to the FIRST node on
                % the new branch
                [branchPoint, branchLink] = obj.closestPointOnSkeleton(branchNodes(1).realCoords);
                
                % add a new node at branch point
                obj.nodes(end+1).realCoords = branchPoint;
                branchPointIndex = length(obj.nodes);
                % de-link the 2 ends of branchLink from each other and link them instead to
                % branchPoint
                node1 = obj.links(branchLink,1);
                node2 = obj.links(branchLink,2);
                oldBranchNumber = obj.links(branchLink,3);
                % delete the old link
                obj.links(branchLink,:) = [];
                % add new links to the new branch point
                obj.links = [obj.links; [node1, branchPointIndex, oldBranchNumber]; [node2, branchPointIndex, oldBranchNumber]];
                % replace the links in the nodes and link them to branchPoint
                obj.nodes(node1).links(obj.nodes(node1).links==node2) = branchPointIndex;
                obj.nodes(node2).links(obj.nodes(node2).links==node1) = branchPointIndex;
                % link new branchPoint to the old nodes
                obj.nodes(branchPointIndex).links = [node1 node2];
                
                % Now add the new branch
                % need to re-index all the node numbers in branchNodes
                for i=1:length(branchNodes)
                    branchNodes(i).links = branchNodes(i).links + length(obj.nodes);
                end
                % and re-index the node numbers in branchLinks
                branchLinks(:,[1 2]) = branchLinks(:,[1 2]) + length(obj.nodes);
                % add the links
                obj.links = [obj.links; branchLinks];
                % add the nodes
                obj.nodes = [obj.nodes, branchNodes];
                
                % link new branchPoint to the old nodes plus the first node of the branch
                obj.nodes(branchPointIndex).links = [obj.nodes(branchPointIndex).links branchPointIndex+1];
                obj.nodes(branchPointIndex+1).links = [obj.nodes(branchPointIndex+1).links branchPointIndex];
                
                % add the link between the new branch and the old branch
                obj.links = [obj.links; [branchPointIndex, (branchPointIndex+1), branchNumber]];
            else
                obj.nodes = branchNodes;
                obj.links = branchLinks;
            end
        end
        
        function obj = labelBranches(obj)
            % labels the links in the skeleton 
            % if you drew the skeleton in this order:
            % vertical lobe tip -> calyx, then add horizontal lobe on
            % then vertical lobe = 1, peduncle/calyx = 2, horizontal lobe =
            % 3
            
            % find all nodes with >2 connections
            nodeLinks = {obj.nodes.links}';
            numLinksPerNode = zeros(length(nodeLinks));
            for j=1:length(nodeLinks)
                numLinksPerNode(j) = length(nodeLinks{j});
            end
            junctionIndices = find(numLinksPerNode>2);
            % initialize all branch labels
            obj.links(:,3) = 0;
            %loop through the junctions
            count = 1;
            for i=1:length(junctionIndices)
                % get the neighbors of the junction
                neighbors = nodeLinks{junctionIndices(i)};
                neighbors = sort(neighbors);
                for j=1:length(neighbors)
                    reachedEnd = false;
                    currentNode = junctionIndices(i); 
                    nextNode = neighbors(j);
                    linkIndex = obj.getLinkIndices([currentNode nextNode]);
                    if ~obj.links(linkIndex,3)
                        while ~reachedEnd
                            obj.links(linkIndex,3) = count;
                            nextNeighbors = obj.nodes(nextNode).links;
                            if length(nextNeighbors) ~= 2
                                reachedEnd = true;
                            else
                                lastNode = currentNode;
                                currentNode = nextNode;
                                nextNode = nextNeighbors(nextNeighbors~=lastNode);
                                linkIndex = obj.getLinkIndices([currentNode nextNode]);
                            end
                        end
                        count = count+1;
                    end
                end
            end

            obj.numBranches = 3;
        end
        
        function result = splitBranches(obj)
            % Return an n x numPaths matrix where each column follows
            % the skeleton from the starting point, along every possible
            % path
            
        end
        
        function obj = createSpacedNodes(obj, spacing)
            disp('Creating spaced nodes');
            if isempty(obj.userStartingPoint)
                error('createSpacedNodes: you must run defineStartingPoint first');
            end
            if isscalar(spacing)
                spacing = repmat(spacing, obj.numBranches, 1);
            end
            
            [obj.startingPoint, obj.startingLink] = obj.closestPointOnSkeleton(obj.userStartingPoint);
                        
            startingNode = [];
            startingNode.realCoords = obj.startingPoint;
            startingNode.distFromStart = 0;
            startingNode.skeletonLink = obj.startingLink;
            startingNode.branchNumber = obj.links(obj.startingLink,3);
            startingNode.links = []; % links to other spaced nodes
            
            % we will construct a new array of nodes that are all evenly spaced
            % they will be labeled with the distance from the starting node
            % each node will be a struct with the fields:
            % - realCoords
            % - distance from startingNode
            % - which skeletonLink is it on
            % - which branchNumber is it on
            % - which other nodes is it connected to
            
            % the new nodes
            obj.spacedNodes = startingNode;
            obj.spacedLinks = [];
            
            skeletonNodes = obj.nodes;
            skeletonLinks = obj.links;
            
            % breadth-first search in case there are loops in the skeleton
            spacedNodeQueue = [];
            spacedNodeQueue = [spacedNodeQueue; 1];
            % the stack contains INDICES of nodes (in spacedNodes), not the nodes themselves
            
            % mark which skeletonLinks have been visited already
            % initialise with all at 0 - they will be marked as 1 as they get visited
            skeletonLinksVisited = zeros(length(skeletonLinks), 1);
            
            % key to variable names:
            % t: the starting spacedNode
            % n: the successive skeletonNodes after t
            % o: the skeletonNode after n
            distanceTolerance = 0.01;
            while ~isempty(spacedNodeQueue)
                % take the top element of spacedNodeQueue BUT DO NOT POP IT
                % OFF YET (we only remove spacedNodes when we are sure
                % you cannot create any more spacedNodes from it)
                tIndex = spacedNodeQueue(1);
                t = obj.spacedNodes(tIndex);
                % mark the link that t is on as visited
                skeletonLinksVisited(t.skeletonLink) = 1;
                
                % test if t is actually on the link that it's supposed to be on
                linkEndpoint1 = skeletonNodes(skeletonLinks(t.skeletonLink,1)).realCoords;
                linkEndpoint2 = skeletonNodes(skeletonLinks(t.skeletonLink,2)).realCoords;
                if abs(pdist2(t.realCoords,linkEndpoint1) + pdist2(t.realCoords,linkEndpoint2) ...
                        - pdist2(linkEndpoint1, linkEndpoint2)) > distanceTolerance
                    error('Node is not on the link that it is supposed to be on!');
                end
                
                createdASpacedNode = 0;
                % for both ends of the current link
                for i=1:2
                    newCoords = NaN;
                    nextSkeletonNodeIndex = skeletonLinks(t.skeletonLink,i);
                    nextSkeletonNode = skeletonNodes(nextSkeletonNodeIndex);
                    vector = nextSkeletonNode.realCoords - t.realCoords;
                    %display(strcat('norm(vector)=',num2str(norm(vector)))); % debugging delete %%%%%%%%%%%%%%%%%%%%%%%
                    unitVector = vector / norm(vector);
                    branchNumber = skeletonLinks(t.skeletonLink,3);
                    %display(strcat('branchNumber=',num2str(branchNumber))); %%%%%%%%%%%%%%%%%%%
                    if norm(vector)>=spacing(branchNumber)
                        % these two values carry down below to the
                        % commands to create a new spacedNode
                        newCoords = t.realCoords + spacing(branchNumber)*unitVector;
                        linkIndex = t.skeletonLink; % we are still on the same link
                    else
                        % DEPTH-FIRST SEARCH to find the next place to put a node at
                        % the right distance from the current node
                        % from the next node, only have remainingDistance left to
                        % search
                        remainingDistance = spacing(branchNumber) - norm(vector);
                        %disp(strcat('remainingDistance:',num2str(remainingDistance)));
                        skeletonNodeStack = [];
                        distanceStack = [];
                        lastSpacingStack = [];
                        % need to keep track of links visited on this
                        % search so that if at any point we encounter a
                        % skeletonNode with unexplored links, we will mark
                        % all links from this search as unvisited, so that
                        % we will go back to them
                        linksVisitedOnThisSearch = [];
                        % push next node and next distance onto the respective stacks
                        % only push the next node on if it's not a terminal node
                        if length(nextSkeletonNode.links)>1
                            skeletonNodeStack = [nextSkeletonNodeIndex; skeletonNodeStack];
                            distanceStack = [remainingDistance; distanceStack];
                            lastSpacingStack = [spacing(branchNumber); lastSpacingStack];
                            while ~isempty(skeletonNodeStack)
                                % nIndex <- nodeStack.pop()
                                nIndex = skeletonNodeStack(1);
                                skeletonNodeStack = skeletonNodeStack(2:end);
                                n = skeletonNodes(nIndex);
                                dist = distanceStack(1);
                                distanceStack = distanceStack(2:end);
                                lastSpacing = lastSpacingStack(1);
                                lastSpacingStack = lastSpacingStack(2:end);
                                % for all links from node n
                                skelNodesLinkedFromN = sort(n.links);
                                numLinks = length(skelNodesLinkedFromN);
                                % call getLinkIndices by horcat n (node1) and skelNodesLinkedFromN (column vector of node2)
                                linkIndices = obj.getLinkIndices([repmat(nIndex,numLinks,1) skelNodesLinkedFromN(:)]);
                                % the indices of visited match the
                                % indices of skelNodesLinkedFromN
                                % and linkIndices
                                visited = skeletonLinksVisited(linkIndices);
                                if sum(visited) < numLinks % if some of the links are unvisited
                                    % pick the first unvisited link
                                    [~,firstUnvisited] = min(visited);
                                    linkIndex = linkIndices(firstUnvisited);
                                    % mark this link as visited
                                    skeletonLinksVisited(linkIndex) = 1;
                                    % if node n still has other unvisited links after this new link has been
                                    % visited
                                    if sum(visited) < (numLinks-1)
                                        % set all previous visited links from this search to be unvisited
                                        skeletonLinksVisited(linksVisitedOnThisSearch) = 0;
                                    end
                                    % add this link to linksVisitedOnThisSearch
                                    linksVisitedOnThisSearch = [linksVisitedOnThisSearch linkIndex];
                                    oIndex = skelNodesLinkedFromN(firstUnvisited);
                                    o = skeletonNodes(oIndex);
                                    vector = o.realCoords - n.realCoords;
                                    branchNumber = obj.links(linkIndex,3);
                                    unitVector = vector / norm(vector);
                                    %disp(strcat('Now on the link between_',num2str(obj.links(linkIndex,1)),'_and_',num2str(obj.links(linkIndex,2)),'_which is branch_',num2str(branchNumber)));
                                    %disp(strcat('norm(vector)insideDFS: ',num2str(norm(vector))));
                                    %disp(strcat('dist:',num2str(dist)));
                                    thisDist = dist*spacing(branchNumber)/lastSpacing; % use thisDist in case >1 unvisited linksFromN
                                    %disp(strcat('thisDist: ',num2str(thisDist)));
                                    if norm(vector)>=thisDist %%%%%%%
                                        newCoords = n.realCoords + thisDist*unitVector;
                                        skeletonLinksVisited(linkIndex) = 1; % ensure that the link with the next node is marked visited
                                    else
                                        %display(strcat('distbeforesub ',num2str(dist)));
                                        dist = thisDist - norm(vector); %%%%%%
                                        %display(strcat('dist:', num2str(dist)));
                                        distanceStack = [dist; distanceStack];
                                        skeletonNodeStack = [oIndex; skeletonNodeStack];
                                        lastSpacingStack = [spacing(branchNumber); lastSpacingStack];
                                    end
                                %else
                                %    disp(['all links visited! from skeletonNode ', num2str(nIndex)]);
                                end
                            end
                        end
                    end
                    
                    % create the new spacedNode
                    if ~isnan(newCoords)
                        % check if you have created this one before
                        createdBefore = 0;
                        for j=1:length(obj.spacedNodes)
                            if pdist2(obj.spacedNodes(j).realCoords, newCoords) < distanceTolerance
                                createdBefore = 1;
                                break;
                            end
                        end
                        % check if you are putting a node on an existing link
                        onExistingLink = 0;
                        for j = 1:size(obj.spacedLinks,1)
                            % test if newCoords lie on any existing links
                            linkEndpoint1 = obj.spacedNodes(obj.spacedLinks(j,1)).realCoords;
                            linkEndpoint2 = obj.spacedNodes(obj.spacedLinks(j,2)).realCoords;
                            if abs(pdist2(newCoords,linkEndpoint1) + pdist2(newCoords,linkEndpoint2) ...
                                    - pdist2(linkEndpoint1, linkEndpoint2)) < distanceTolerance
                                onExistingLink = 1;
                                break;
                            end
                        end
                        if ~createdBefore && ~onExistingLink
                            newNode.realCoords = newCoords;
                            newNode.distFromStart = t.distFromStart + spacing(branchNumber);
                            newNode.skeletonLink = linkIndex;
                            newNode.links = tIndex;
                            newNode.branchNumber = skeletonLinks(linkIndex,3);
                            %display(['Created node ', num2str(tIndex), ' at distance ', num2str(newNode.distFromStart), ' on branch ', num2str(newNode.branchNumber)]);
                            obj.spacedNodes = [obj.spacedNodes; newNode];
                            % link the previous node to the new node
                            obj.spacedNodes(tIndex).links = [obj.spacedNodes(tIndex).links; length(obj.spacedNodes)];
                            obj.spacedLinks = [obj.spacedLinks; [tIndex length(obj.spacedNodes)]];
                            spacedNodeQueue = [spacedNodeQueue; length(obj.spacedNodes)];
                            createdASpacedNode = 1;
                        end
                    end

                end %for i=1:2
                if ~createdASpacedNode
                    % remove t from spacedNodeStack
                    spacedNodeQueue(spacedNodeQueue==tIndex) = [];
                end
            end % while ~isempty(spacedNodeStack)
        end % function
        
        function result = getLinkIndices(obj, nodeArray)
            % finds the indices for the links between nodes
            % nodeArray is an n x 2 array where each row is a pair of node
            % indices
            % returns an n x 1 array where the i'th element is the index of
            % the link between the nodes in the i'th row of nodeArray
            % the i'th element will be 0 if there is no such link (and will
            % print out a warning)
            % e.g.
            % nodeArray = [1 2; 3 4; 1 3];
            % getLinkIndices(nodeArray) returns the indices for the links
            % between nodes 1&2, 3&4, 1&3
            n = size(nodeArray,1);
            result = zeros(n,1);
            for i=1:n
                node1 = nodeArray(i,1);
                node2 = nodeArray(i,2);
                [~, linkIndex1] = ismember([node1 node2], obj.links(:,[1 2]), 'rows');
                [~, linkIndex2] = ismember([node2 node1], obj.links(:,[1 2]), 'rows');
                linkIndex = max(linkIndex1, linkIndex2);
                if ~linkIndex
                    disp(['getLinkIndices warning: returning 0 in element ' num2str(i)]);
                end
                result(i) = linkIndex;
            end
        end
        
        function endNodes = findEndNodes(obj)
            % Returns the indices of the nodes that have only one node
            % linked to them (i.e. "ends")
            endNodes = [];
            for i=1:length(obj.nodes)
                if length(obj.nodes(i).links)==1
                    endNodes = [endNodes i];
                end
            end
        end
        
        function [distances, prevNodes] = getDistances(obj, startingNode)
            % This function will find the distances between the starting
            % node (the node with index number 'startingNode') and every
            % other node in the skeleton
            % Returns:
            % distances: an array whose i-th element is the distance between
            % the starting node and the node in the skeleton with index i
            % prevNodes: an array whose i-th element is the previous node
            % in the shortest path from the starting node to the node in
            % the skeleton with index i
            
            % Implements the pseudocode from the Wikipedia page about
            % Dijkstra's algorithm
            distances = Inf(length(obj.nodes), 1);
            prevNodes = zeros(length(obj.nodes), 1);
            distances(startingNode) = 0;
            Q = 1:length(obj.nodes);
            while ~isempty(Q)
                % u is the index of the node with the minimum distance 
                % but only search for the distances of nodes that are still
                % in Q
                [~, minDistIndex] = min(distances(Q));
                u = Q(minDistIndex);
                % remove u from Q
                Q = Q(Q~=u); % ie keep only values in Q that are not u
                
                % for each neighbor of u
                for i=1:length(obj.nodes(u).links)
                    % v is the index of the neighbor
                    v = obj.nodes(u).links(i);
                    % alt is the distance of node u, plus the distance
                    % between u and the neighbor
                    
                    alt = distances(u) + pdist2(obj.nodes(u).realCoords, obj.nodes(v).realCoords);
                    if (alt < distances(v)) % if we've found a shorter distance for v
                        distances(v) = alt;
                        prevNodes(v) = u;
                    end
                end
            end
        end
        
        function obj = createVoronoiMask(obj)
            anchorPoints = cell2mat({obj.spacedNodes.realCoords}');
            w=size(obj.mask,1);
            l=size(obj.mask,2);
            h=size(obj.mask,3);
            % get all the points where mask is not 0
            [x_vals,y_vals,z_vals]=ind2sub([w,l,h],find(obj.mask(:)));
            % make an nx3 matrix
            points = [x_vals, y_vals, z_vals];
            pointsActualLocs = obj.pixelsToMicrons(points);
            
            % get distances between all voxels and the 'anchor' points
            distances = pdist2(pointsActualLocs,anchorPoints);
            % find which point gives the minimum distance for each voxel
            [~,indices] = min(distances,[],2);
            
            obj.voronoiMask = false(w, l, h, size(anchorPoints,1));
            for i=1:nnz(obj.mask(:))
                obj.voronoiMask(points(i,1),points(i,2), points(i,3), indices(i)) = true;
            end
        end
        
        function [] = drawSkeleton(obj, varargin)
            % Draw the 3d surface and skeleton
            % Usage:
            % skel.drawSkeleton() -->
            %  If spaced nodes have not been defined yet, draws the surface
            %  in gray and user-defined nodes in red
            %  If spaced nodes have been created, adds in the spaced nodes
            %  color-coded by distance from start point
            %  If the object has already been divided into Voronoi spaces
            %  by the spaced noes, draw the surfaces not in gray but also
            %  color-coded by the distance of the relevant spaced node.
            % skel.drawSkeleton(values) -->
            %  Instead of color-coding the Voronoi spaces by distance,
            %  instead color-code them by the input parameter 'values'.
            %  length(values) must equal the number of Voronoi spaces
            %  To do this, you must have already defined the Voronoi
            %  spaces. If no Voronoi spaces have been defined, it will just
            %  draw the surface in gray.
            %  
            figure('Name','Outline and skeleton - rotate for 3d view','Color','white');
            
            % match up voxels in the image to dimensions for display so that we can
            % display microns instead of pixels
            [x,y,z] = meshgrid(obj.pixelCal(2)*(1:size(obj.mask,2)), ...
                obj.pixelCal(1)*(1:size(obj.mask,1)), ...
                obj.pixelCal(3)*(size(obj.mask,3):-1:1));
            % generate the 3D surface outline of the volume
            if isempty(obj.voronoiMask)
                isonormals(obj.mask,patch(isosurface(x,y,z,obj.mask,0),'FaceColor',[.7 .7 .8], 'EdgeColor','none'));
                colors = zeros(length(obj.spacedNodes),3);
            else
                cmap = colormap;
                % if voronoiMask exists, divide up the mask with color
                % coding 
                if (nargin==1)
                    maxDist = max([obj.spacedNodes.distFromStart]);
                    colors = cmap(round([obj.spacedNodes.distFromStart]*63/maxDist)+1,:);
                    title(['Color coding = distance, max dist = ' num2str(maxDist)]);
                else
                    values = varargin{1};
                    if length(values)~=size(obj.voronoiMask,4)
                        error('length(values) must equal # of Voronoi spaces');
                    end
                    maxValue = max(values(:));
                    minValue = min(values(:));
                    colors = cmap(round((values-minValue)*63/(maxValue-minValue))+1,:);
                    title(['Color coding = data, range ' num2str(minValue) ' to ' num2str(maxValue)]);
                end
                for i=1:size(obj.voronoiMask,4)
                    isonormals(obj.voronoiMask(:,:,:,i),patch(isosurface(x,y,z,obj.voronoiMask(:,:,:,i),0),'FaceColor',colors(i,:), 'EdgeColor','none'));
                end
%                 if (nargin==0)
%                     maxDist = max([obj.spacedNodes.distFromStart]);
%                     for i=1:size(obj.voronoiMask,4)
%                         thisColor = cmap(round(obj.spacedNodes(i).distFromStart*63/maxDist)+1,:);
%                         isonormals(obj.voronoiMask(:,:,:,i),patch(isosurface(x,y,z,obj.voronoiMask(:,:,:,i),0),'FaceColor',thisColor, 'EdgeColor','none'));
%                     end
%                 else
%                     values = varargin{1};
%                     if length(values)~=size(obj.voronoiMask,4)
%                         error('length(values) must equal # of Voronoi spaces');
%                     end
%                     maxValue = max(values(:));
%                     for i=1:size(obj.voronoiMask,4)
%                         thisColor = cmap(round(values(i)*63/maxValue)+1,:);
%                         isonormals(obj.voronoiMask(:,:,:,i),patch(isosurface(x,y,z,obj.voronoiMask(:,:,:,i),0),'FaceColor',thisColor, 'EdgeColor','none'));
%                     end
%                 end
            end
            
            % apply a light
            camlight;
            % make the surface 30% transparent
            alpha(0.3);
            axis equal;
            
            hold on
            % draw the notes
            for i=1:length(obj.nodes)
                x = obj.nodes(i).realCoords(1);
                y = obj.nodes(i).realCoords(2);
                z = obj.nodes(i).realCoords(3);
                
                plot3(y,x,z,'o','Markersize',5,...
                    'MarkerFaceColor','r',...
                    'Color','k');
                
            end
            for j=1:size(obj.links,1)
                coords(1,:) = obj.nodes(obj.links(j,1)).realCoords; % 1x3
                coords(2,:) = obj.nodes(obj.links(j,2)).realCoords; % 1x3
                % coords is now a 2x3 array
                
                line(coords(:,2)',coords(:,1)',coords(:,3)','Color','r','LineWidth',1);
                text(mean(coords(:,2)), mean(coords(:,1)), mean(coords(:,3)),strcat('.  ',num2str(obj.links(j,3))));
            end
            
            % draw the skeleton
            if ~isempty(obj.spacedNodes)
                for i=1:length(obj.spacedNodes)
                    x = obj.spacedNodes(i).realCoords(1);
                    y = obj.spacedNodes(i).realCoords(2);
                    z = obj.spacedNodes(i).realCoords(3);
                    
                    % draw the node
                    plot3(y,x,z,'o','Markersize',9,...
                        'MarkerFaceColor',colors(i,:),...
                        'Color','k');
                    text(y,x,z,strcat(num2str(obj.spacedNodes(i).distFromStart)));
                    
                end
            end

        end
        
        function result = pixelsToMicrons(obj, pixelCoords)
            maxZ = size(obj.mask,3);
            % turn the z dimension upside down
            pixelCoords(:,3) = maxZ - pixelCoords(:,3) + 1;
            result = pixelCoords.*repmat(obj.pixelCal,size(pixelCoords,1),1);
        end
        
        function [closestPoint, closestLink] = closestPointOnSkeleton(obj, P)
            % Find the point and link on the skeleton closest to P
            % usage:
            % result = obj.closestPointOnSkeleton(P)
            % P is an [x y z] triple in real space (not pixelspace)
            % returns an [x y z] triple (1x3) of th
            
            % start from the first node
            minDist = pdist2(obj.nodes(1).realCoords, P);
            closestPoint = obj.nodes(1).realCoords;
            closestLink = 1;
            % loop through all links
            for k = 1:size(obj.links,1)
                % the point on one end of the link
                A = obj.nodes(obj.links(k,1)).realCoords;
                % N is the vector pointing from A to the other end of the
                % link
                N = obj.nodes(obj.links(k,2)).realCoords - A;
                normN = norm(N); % the length of N
                % make the unit vector in the direction of N
                unitN = N/normN;
                % see equation at https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
                % The equation of a line can be given in vector form: X = A + t*unitN
                % in our case t is given by dot(P-A,unitN). But we don't want t to be
                % negative or to be bigger than normN or else it won't be within the line segment
                closestPointOnLine = A + min(normN,max(0,dot(P-A,unitN)))*unitN;
                distance = pdist2(closestPointOnLine, P);
                if distance < minDist
                    closestPoint = closestPointOnLine;
                    minDist = distance;
                    closestLink = k;
                end
            end
        end
        
        function result = closestSpacedNodeToUserClick(obj)
            % Asks user to click a point or points on the montage view of
            % the skeleton's mask, then returns the index or indices of the
            % spaced node(s) closest to the user-selected point(s)
            %
            % Usage:
            % result = skel.closestSpacedNodeToUserClick();
            % 
            % result will contain the indices of the closest spaced nodes
            % to the user-selected points, in the order that the user
            % clicked the points.
            %
            
            figHandle = figure('Name', 'Click on a point(s) to find the closest spaced node(s), then press <return>');
            [montageImage, montageDims] = stackToMontage(permute(obj.mask,[2 1 4 3]));
            imagesc(montageImage);
            axis equal, axis tight;
            
            % manually enter a point
            [x_in, y_in] = getpts(figHandle);
            [x, y, z] = montageXYToStackXYZ(x_in,y_in,[size(obj.mask,1) size(obj.mask,2)],montageDims);
            points = [x, y, z];
            pointsActualLocs = obj.pixelsToMicrons(points);
            
            % What is the closest spaced node to the user-entered point?
            anchorPoints = cell2mat({obj.spacedNodes.realCoords}');
            distances = pdist2(pointsActualLocs,anchorPoints);
            % find which point gives the minimum distance for each voxel
            [~,indices] = min(distances,[],2);
            result = indices;
        end
    end
        
    methods(Static)
        function [] = saveRotatingMovie(azimuthRange, azimuthStepSize, elevation, fileName)
            % saveRotatingMovie(azimuthRange, azimuthStepSize, elevation, fileName)
            % takes a figure with a 3d object and saves an .avi movie where
            % the object is viewed from a certain elevation and is rotated
            % through a range of azimuth angles, forward and backward.
            %
            % Usage:
            % map.skel.saveRotatingMovie(azimuthRange, azimuthStepSize, elevation, fileName);
            % azimuthRange: a 1x2 matrix with the endpoints of the angles
            %  over which you want to rotate, eg [-60 -120]
            % azimuthStepSize: how many degrees do you want to rotate the
            %  object for each frame of the movie?
            % elevation: the elevation angle you want to view the object
            %  from
            % fileName: a string with the file name you want to use to save
            %  the movie
            %
            % example usage:
            % map.skel.saveRotatingMovie([-120 -60], 1, 30,'rotatingMovie.avi')
            %
            % Usage notes:
            % * YOU MUST HAVE DRAWN THE SKELETON ALREADY AND HAVE THE FIGURE
            %   WITH THE SKELETON AS THE TOP WINDOW!!
            % * To decide on the right azimuthRange and elevation, rotate the
            %   figure manually and note the values displayed in the lower
            %   left corner, e.g. "Az: -120 El: 30" - note these values
            %   only appear when you are actively rotating the object.
            
            axis tight manual % this ensures that getframe() returns a consistent size
            if sign(azimuthRange(2)-azimuthRange(1)) ~= sign(azimuthStepSize)
                error('azimuthRange(2)-azimuthRange(1) must have the same sign as azimuthStepSize');
            end
            
            % forward rotation
            angles = azimuthRange(1):azimuthStepSize:azimuthRange(2);
            
            % reverse rotation
            angles = [angles azimuthRange(2):(-azimuthStepSize):azimuthRange(1)];
            
            for n = 1:length(angles)
                view(angles(n),elevation)
                % Capture the plot as an image
                frame = getframe(gcf);
                im = frame2im(frame);
                movie(:,:,:,n) = im;
            end
            
            v = VideoWriter(fileName);
            open(v);
            writeVideo(v,movie);
            close(v);
        end
    end
    
end