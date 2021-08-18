% rng(1)

X=length(gridX);
Y=length(gridY);
Z=length(gridZ);
X=300;
Y=152;
Z=100;

M=zeros(X,Y,Z);
 

rbs=rand(X,Y);
% M=ones(X,Y,Z);
for z=1:1:Z %z=300 "layers"
%     figure(1)
    rbs=rbs+.4*(rand(X,Y)-.5);
    rbs2=imgaussfilt(rbs,4);
    imagesc(rbs2>.5) %.5 detemines porosity
    M(:,:,z)=rbs2>.5;
    
end
 

% for (i=1:40),
%    M(:,:,i)=0 ;
%    M(1:(X-1),1:(Y-1),i)=1 ;
% end
gridOUTPUT=M;