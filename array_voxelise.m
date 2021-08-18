
function [gridOUTPUT,varargout] = array_voxelise(lX,lY,lZ,wx,wy,B,X,Y,Z,bufX,bufY,varargin)


repx=floor((lX-bufX)/X);
repy=floor((lY-bufY)/Y);
M=ones(X,Y,Z+B);
OUT=zeros(lX,lY,Z+B);
M(wx:X-wx,wy:Y-wy,B:Z+B)=0;
M2=repmat(M,repx,repy);

[a,b,c]=size(M2);
OUT(bufX-wx:a+bufX-1+wx,bufY-wy:b+bufY-1+wy,1:c)=1;

OUT(bufX:a+bufX-1,bufY:b+bufY-1,1:c)=M2;
gridOUTPUT=OUT;