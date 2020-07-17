
function [NewIma,RepeatRotate]=RotateAndCropImage(Ima)

NLines=size(Ima,1);
NCol=size(Ima,2);
NImages=size(Ima,3);
Ima_M=mean(Ima,3);

%%%%%%%%%%%%%%Find the Canal%%%%%%%%%%%%%%%

%Saturate Perc % of the image to get rid of large particles stuck in the canal
img = imfilter(Ima_M,fspecial('gaussian',[5 20],5));
Perc=25;
SortedIm=sort(reshape(img,NLines*NCol,1),'descend');
img(img>SortedIm(floor(length(SortedIm)/(100/Perc))))=1;
img(img~=1)=0;

Test=img;
Filter=imfill(Test);
Filter= bwlabel(Filter, 8);

%Automatically detect the canal (Find ROI of high values and choose the
%only the largest ones. If more than 1 large region detected, the canal is chosen as the one with the brightest mean pixel intensity)
blobMeasurements = regionprops(Filter, Ima_M, 'all');

Number=find([blobMeasurements.Area]>2000);

if length(Number)>1
    
    [~,Number2]=max([blobMeasurements(Number).MeanIntensity]);
    Filter = ismember(Filter,Number(Number2));
    Angle=blobMeasurements(Number(Number2)).Orientation;
else
    Filter = ismember(Filter,Number);
    Angle=blobMeasurements(Number).Orientation;
end

%Find the Angle of the chosen ROI and rotate image + mask image
%Angle=blobMeasurements(Number).Orientation;
RotIma=imrotate(Ima_M,-Angle);
figure(2)
imagesc(RotIma)
%RotFilter=imrotate(Filter,-Angle);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Ask if rotation is correct and modifies if not
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RepeatRotate=1;
TotalAngle=0;

while RepeatRotate>0
    
    AddRot=CheckRotation(Ima_M, RotIma);
    
    if AddRot==90
        AddRot=-Angle;%Corresponds to cancel rotation
        
        RepeatRotate=0;
    else
        
        if AddRot~=0&&AddRot~=180
            RepeatRotate=1;
        else
            RepeatRotate=0;
        end
    end
    
    TotalAngle=TotalAngle+AddRot;
    
    RotIma=imrotate(Ima_M,-TotalAngle-Angle);
    
end
    
% switch AddRot %Nothing happens till AddRot is eventually modified in the GUI
%     case 0
%         
%     case 90
%         return % Ends the function entirely
%         
%     case 180 %Rotate image of 180° and stops while loop
%         RotIma=imrotate(RotIma,180);
%         RotFilter=imrotate(RotFilter,180);
%         
% end

%Crop Image
figure(2)
imagesc(RotIma);
title({'Draw the largest portion of flat central canal.',' Along DV axis, central canal should be around half the crop'})
ROI=drawrectangle('Color','r');
Message=strcat('Enter Yes when the ROI is defined');    
menu(Message,'Yes','No');


Pos=round(ROI.Position); 
close(figure(2))

%%%%%%%%%%%%%%%%%%
%Apply rotation  and crop to all images of the stack
%%%%%%%%%%%%%%%%
NLines=Pos(4);
NCol=Pos(3);
NewIma=zeros(NLines,NCol,NImages);

for ii=1:NImages
    NewIma2(:,:)=imrotate(Ima(:,:,ii),-TotalAngle-Angle);
    NewIma(:,:,ii)=NewIma2(Pos(2):Pos(2)+Pos(4)-1,Pos(1):Pos(1)+Pos(3)-1,:);
end

end

