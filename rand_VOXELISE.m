function [gridOUTPUT,varargout] = woodpile_VOXELISE(gridX,gridY,gridZ,varargin)

X=length(gridX);
Y=length(gridY);
Z=length(gridZ);
M=zeros(X,Y,Z);
 

rbs=rand(X,Y);
a=ones(X,Y,Z);
for z=1:1:Z %z=300 "layers"
    figure(1)
    rbs=rbs+.4*(rand(X,Y)-.5);
    rbs2=imgaussfilt(rbs,4);
    imagesc(rbs2>.5) %.5 detemines porosity
    a(:,:,z)=rbs2>.5;
    
end


 

for (i=1:40),
   M(:,:,i)=0 ;
   M(1:(X-1),1:(Y-1),i)=1 ;
end
gridOUTPUT=M;