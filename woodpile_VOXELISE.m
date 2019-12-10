function [gridOUTPUT,varargout] = woodpile_VOXELISE(gridX,gridY,gridZ,varargin)

X=length(gridX);
Y=length(gridY);
Z=length(gridZ);
M=zeros(X,Y,Z);
 LOGSIZEX=8;
 LOGSIZEY=20;
 LOGSIZEZ=8;
 
 FILLFACTOR=4;
%LOGSIZEX=2;
%LOGSIZEY=2;
%LOGSIZEZ=2;

a=mod(1:X,LOGSIZEX)<(LOGSIZEX/FILLFACTOR);
z=repmat(a,Y,1);

a=mod(1:Y,LOGSIZEY)<(LOGSIZEY/FILLFACTOR);
z2=repmat(a,X,1);
z2=z2';

for(i=1:Z),
    if(mod(i,LOGSIZEZ)<(LOGSIZEZ/FILLFACTOR)) M(:,:,i)=z';
    else
         M(:,:,i)=z2';
    end
    
end

gridOUTPUT=M;