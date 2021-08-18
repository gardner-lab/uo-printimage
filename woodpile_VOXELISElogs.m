function [gridOUTPUT,varargout] = woodpile_VOXELISE(gridX,gridY,gridZ,varargin)

X=length(gridX);
Y=length(gridY);
Z=length(gridZ);
M=zeros(X,Y,Z);
% 
% %current print for 153
 LOGSIZEX=8;
 LOGSIZEY=20;
 LOGSIZEZ=60; %last print was 40 %original was 8
 
 FILLFACTOR=4;

%test print for larger devices
%  LOGSIZEX=4;
%  LOGSIZEY=10;
%  LOGSIZEZ=30; %last print was 40 %original was 8
%  
%  FILLFACTOR=4;

%LOGSIZEX=2;
%LOGSIZEY=2;
%LOGSIZEZ=2;

a=mod(1:X,LOGSIZEX)<(LOGSIZEX/FILLFACTOR);
z=repmat(a,Y,1);

a=mod(1:Y,LOGSIZEY)<(LOGSIZEY/FILLFACTOR);
z2=repmat(a,X,1);
z2=z2';

for(i=1:Z),
    if(mod(i,LOGSIZEZ)<(LOGSIZEZ/2)) M(:,:,i)=z';
    else
         M(:,:,i)=z2';
    end
    
end

%Add a solid base for attachment
for (i=1:40),
   M(:,:,i)=0 ;
   M(1:(X-1),1:(Y-1),i)=1 ;
end
gridOUTPUT=M;