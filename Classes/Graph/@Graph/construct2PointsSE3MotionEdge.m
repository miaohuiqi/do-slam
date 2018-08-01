function [obj] = construct2PointsSE3MotionEdge(obj,config,edgeRow)
%CONSTRUCT2POINTSSE3MOTIONEDGE constructs edge representing measurement
%between two points and their respective SE3 motion vertex

%% 1. load vars from edge row
edgeLabel = edgeRow{1};
edgeIndex = edgeRow{2};
pointVertices = edgeRow{3};
SE3MotionVertex = edgeRow{4};
edgeValue = edgeRow{5};
edgeCovariance = edgeRow{6};

%% 2. properties
value       = edgeValue;
covariance  = upperTriVecToCov(edgeCovariance);
jacobians   = [];
type        = '2points-SE3Motion';
iVertices   = [pointVertices SE3MotionVertex];
index       = edgeIndex;

%% 3. construct edge
obj.edges(edgeIndex) = Edge(value,covariance,jacobians,type,iVertices,index);

%% 4. update edge
%computes value & jacobians
obj = obj.update2PointsSE3MotionEdge(config,edgeIndex);

%% 5. add index to point and motion vertices
obj.vertices(pointVertices(1)).iEdges = [obj.vertices(pointVertices(1)).iEdges edgeIndex];
obj.vertices(pointVertices(2)).iEdges = [obj.vertices(pointVertices(2)).iEdges edgeIndex];
obj.vertices(SE3MotionVertex).iEdges = unique([obj.vertices(SE3MotionVertex).iEdges edgeIndex]);

%% 6. check window size and delete old edges
%% this is for landmarks window size
% nLandmarks = numel(obj.vertices(SE3MotionVertex).iEdges) + 1;
% if nLandmarks > config.landmarksSlidingWindowSize
%     firstEdgeIndex = obj.vertices(SE3MotionVertex).iEdges(1);
%     obj.edges(firstEdgeIndex) = [];
%     obj.vertices(pointVertices(1)).iEdges...
%         (obj.vertices(pointVertices(1)).iEdges==firstEdgeIndex) =[];
%     obj.vertices(pointVertices(2)).iEdges...
%         (obj.vertices(pointVertices(2)).iEdges==firstEdgeIndex) =[];
%     obj.vertices(SE3MotionVertex).iEdges...
%         (obj.vertices(SE3MotionVertex).iEdges==firstEdgeIndex) =[];
% end

%% this is for object poses window size
posesVertices = [obj.vertices(obj.identifyVertices('pose')).index];
pointVerticesConnectedToMotionVertex = [];
pointsVertices = [obj.vertices(obj.identifyVertices('point'))];

SE3MotionEdges = [obj.identifyEdges('2points-SE3Motion')];
firstSE3MotionEdgeIndex = SE3MotionEdges(1);

for i=1:length(pointsVertices)
    pointVertex = pointsVertices(i);
    for j=1:length(pointVertex.iEdges)
        if pointVertex.iEdges(j) > firstSE3MotionEdgeIndex
            pointVertexEdge = obj.edges(pointVertex.iEdges(j)-obj.nSE3EdgesDeleted);
        else
            pointVertexEdge = obj.edges(pointVertex.iEdges(j));
        end
        if ismember(SE3MotionVertex,[pointVertexEdge.iVertices])
            pointVerticesConnectedToMotionVertex = [pointVerticesConnectedToMotionVertex...
                pointsVertices(i).index];
        end
    end
end

pointVerticesConnectedToMotionVertex = reshape(pointVerticesConnectedToMotionVertex,...
    [length(pointVerticesConnectedToMotionVertex)/2,2]);
uniquePoseIndex = [];

for i=1:size(pointVerticesConnectedToMotionVertex,1)
    closestPose1index = posesVertices(sum((pointVerticesConnectedToMotionVertex(i,1)-posesVertices)>0));
    closestPose2index = posesVertices(sum((pointVerticesConnectedToMotionVertex(i,2)-posesVertices)>0));     
    if isempty(uniquePoseIndex)
        uniquePoseIndex = [closestPose1index, closestPose2index];
    else
        if ~ismember(closestPose1index,uniquePoseIndex)
            uniquePoseIndex = [uniquePoseIndex closestPose1index];
        end
        if ~ismember(closestPose2index,uniquePoseIndex)
            uniquePoseIndex = [uniquePoseIndex closestPose2index];
        end
    end
end

nObjectPoses = numel(uniquePoseIndex); 
if nObjectPoses > config.objectPosesSlidingWindowSize
    firstEdgeIndex = obj.vertices(SE3MotionVertex).iEdges(1);
    firstEdgeVertices = [obj.edges(firstEdgeIndex).iVertices];
    firstLandmarkPoseindex = posesVertices(sum((firstEdgeVertices(1)-posesVertices)>0));
    secondLandmarkPoseindex = posesVertices(sum((firstEdgeVertices(2)-posesVertices)>0));
    for j=1:obj.nEdges
        if j > firstSE3MotionEdgeIndex
            indx = j-obj.nSE3EdgesDeleted;
        else
            indx = j;
        end
        if strcmp(obj.edges(indx).type,'2points-SE3Motion')
            edgeVertices = [obj.edges(indx).iVertices];
            landmark1PoseIndex = posesVertices(sum((edgeVertices(1)-posesVertices)>0));
            landmark2PoseIndex = posesVertices(sum((edgeVertices(2)-posesVertices)>0));
            if landmark1PoseIndex==firstLandmarkPoseindex && ...
                    landmark2PoseIndex==secondLandmarkPoseindex       
                obj.vertices(edgeVertices(1)).iEdges...
                    (obj.vertices(edgeVertices(1)).iEdges == ...
                    obj.edges(indx).index) = [];
                obj.vertices(edgeVertices(2)).iEdges...
                    (obj.vertices(edgeVertices(2)).iEdges ==...
                    obj.edges(indx).index) = [];
                obj.vertices(SE3MotionVertex).iEdges...
                    (obj.vertices(SE3MotionVertex).iEdges ==...
                    obj.edges(indx).index) = [];
                obj.edges(indx) = [];
                obj.nSE3EdgesDeleted = obj.nSE3EdgesDeleted+1;
            end
        end
    end
end

end

