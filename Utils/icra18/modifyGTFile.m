function modifyGTFile(filePath,n)
% read lines 1:step:end
fileID = fopen(filePath,'r');
Data = textscan(fileID, '%s', 'delimiter', '\n', 'whitespace', '');
CStr = Data{1};
fclose(fileID);
% write those lines to new file
nLines = size(CStr,1);
increment = ceil(nLines/n);
list = 1:increment:nLines;
DataNew = CStr(list);
% delete first two and last 21 lines
DataNew(1:2) = [];
DataNew(end-20:end)=[];
% re-write file
fileID = fopen(filePath,'w');
for i=1:numel(DataNew)
    fprintf(fileID,[DataNew{i} '\n']);
end
fclose(fileID);
