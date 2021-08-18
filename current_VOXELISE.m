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
 
 FILLFACTOR=4; % here 1/FF is solid
 STP=0.1; %percent of tip that is solid
 SBP=0.1; %percent of base that is solid
 
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

% Add a solid tip for insertion

for (i=(1:floor(Z*STP))),
   M(:,:,i)=0 ;
   M(2:(X-1),2:(Y-1),i)=1 ;
end

% Add a solid base for attachment
for (i=((Z-floor(Z*SBP)):Z)),
   M(:,:,i)=0 ;
   M(2:(X-1),2:(Y-1),i)=1 ;
end

% add the taper
for(i=1:Z)%add increase stup up based on solid base below
    tape1=floor(((floor(size(M,1)/2))/Z)*i);%floor(0.1*i);
%      M(1:(floor(size(M,1)/2)-floor(size(M,1)*tape/2)),:,i)=0;
        M((floor(size(M,1)/2)+tape1):end,:,i)=0;
        M(1:(floor(size(M,1)/2)-tape1),:,i)=0;
        
    
end

for(i=1:Z)%add increase stup up based on solid base below
    tape2=floor(((floor(size(M,2)/2))/Z)*i);%floor(0.1*i);
        M(:,(floor(size(M,2)/2)+tape2):end,i)=0;
        M(:,1:(floor(size(M,2)/2)-tape2),i)=0;
        
    
end
% for(i=1:Z),
%     tape=0.5%floor(0.1*i);
%     if(mod(i,LOGSIZEZ)<(LOGSIZEZ/2))...
%         M(1:(floor(size(M,1)/2)-floor(size(M,1)*tape/2)),:,i)=0;
%         M((floor(size(M,1)/2)+floor(size(M,1)*tape/2):end),:,i)=0;
%     else
%          M(:,:,i)=z2';
%     end
%     
% end



M1=M;
% invert
for (i=(1:Z)),
   M(:,:,i)=M1(:,:,(end+1-i));
end

gridOUTPUT=M;