%Function to generate a flow profile from the automatic kymograph approach

%INPUTS:
%FileTif : Full path to a multipage .tif file containing the video of particles flowing in CSF

%Name : Short Name of the acquisition (will be used to create the name of the ouput file)

%n : Number of the file if batch processing

%PixelSize : PixelSize of acquisition in micron

%FrameTIme : 1/fps =Time between two frames (Attention: May be different
%from exposure time)

%SaveVideo : If 1, outputs an avi file with the video of the generation of
%kymograph

function CSFProfile=Automatic_Kymograph_GUI_2020(Ima,DataPath,Name,n,PixelSize,FrameTime,SaveVideo,Display,Threshold,Output)

if exist('PixelSize','var')==0
    PixelSize=0.189; %um
end

if exist('FrameTime','var')==0
    FrameTime=0.1; %s
end

if exist('SaveVideo','var')==0
    SaveVideo=0; %s
end


if exist('Display','var')==0
    Display=1; %s
end

NLines=size(Ima,1);
NCol=size(Ima,2); %#ok<NASGU>
NImages=size(Ima,3);

%Permute dimensions to obtain the kymograph
Kymo=permute(Ima,[3 2 1]);

%Kymograph filtering : I filter out 50% of less bright pixels (Essentially
%pixels outisde the canal) and rescale all pixels between 1 and 2

Kymo=rescale(Kymo,0,1);
[~,CanalCenter]=max(mean(mean(Kymo)));

Min=quantile(Kymo(:,:,CanalCenter),Threshold,'all');
Kymo(Kymo<Min)=Min;
Kymo=rescale(Kymo,1,2);

%Kymograph normalization : I Normalize by the average value (versus time) 
%to avoid detecting particles stuck at a given position (same position for all times)
Kymo=Kymo./repmat(mean(Kymo,1),NImages,1);

NAvg=3;

LocalMean=zeros(length(NLines)-5,1);
LocalSE=zeros(length(NLines)-5,1);
SpeedAll=zeros(NLines-5,100);

%If SaveVideo, I will save the video of kymograph fit and histogram at each
%position as an .avi file
if SaveVideo
 v = VideoWriter(strcat(DataPath,'Kymograph_',Name,'.avi'));
 v.FrameRate = 2;
 open(v);
end
if Display
    figure(1)
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.9, 0.9]);
end
% Scan of all dorso-ventral positions
for ii=1:NLines-NAvg
    
    % (Moving)Average of NAvg successive positions (to avoid loosing
    % particles too fast) 
    
    Kymo_Avg=mean(Kymo(:,:,ii:ii+NAvg),3);   
    if Display
        %Disp_Min=quantile(Kymo_Avg,50,'all');
        %Disp_Max=quantile(Kymo_Avg,99,'all');
        subplot(2,2,1)
        imagesc(Kymo_Avg,[1.01 1.2])
        title('Original image (avg 3 lines)')
    end
    
    %Generation of a binary image : Every pixel  1% (Max-Min)Signal above
    %the Min Signal is 1.
    
    Binary=Kymo_Avg>1.01; % Not very stringent filter
    Binary= bwlabel(Binary, 8);
    if Display
        subplot(2,2,2)
        imagesc(Binary)
        title('Binary image')
    end

    % Find all regions of interest in the binary image and filters the
    % regions that don't look like single lines
    
    blobMeasurements = regionprops(Binary, Kymo_Avg, 'all');
    
    %To keep a region of interest, it has to be at least 15 pixels, have an
    %eccentricity above 0.9, to gave only very ellongated ellipses, i.e.
    %lines. I also discard vertical and horizontal region of interest,
    %because vertical lines are mostly particles stuck in some part of the
    %canal, and the horizontal lines are mostly due to camera noise (and
    %give infinite speed).
    
    EffectiveLines=blobMeasurements([blobMeasurements.Eccentricity]>0.9&[blobMeasurements.Area]>15&abs(sin(pi/180*[blobMeasurements.Orientation]))>0.1&abs(cos(pi/180*[blobMeasurements.Orientation]))>0.1);
  
    %Create an image with all regions of interest kept (bottom left)
    keeperIndexes = find([blobMeasurements.Eccentricity]>0.9&[blobMeasurements.Area]>15&abs(sin(pi/180*[blobMeasurements.Orientation]))>0.1&abs(cos(pi/180*[blobMeasurements.Orientation]))>0.1);
    keeperBlobsImage = ismember(Binary, keeperIndexes);
    keeperBlobsImage= bwlabel(keeperBlobsImage, 8);
    if Display
        subplot(2,2,3)
        imagesc(keeperBlobsImage)
        title('Kept Traces')
    end
    %Measure the angle of all remaining regions of interest
    
    Orient_Kymo=[EffectiveLines.Orientation];
    %Calculate the speed from the angle
    
    Speed=1./tan(-Orient_Kymo*pi/180)*(PixelSize/FrameTime);
   
    %I only keep and save the values of speed if at least 5 events are
    %detected
    if isempty(Speed)||length(Speed)<5
        LocalMean(ii)=0;
        LocalSE(ii)=0;
        
    else
        LocalMean(ii)=mean(Speed);
        LocalSE(ii)=std(Speed,0)/sqrt(length(Speed));
        SpeedAll(ii,1:length(Speed))=Speed;
    end
    
    %Plot the histogram (Bottom right)
    if Display
        subplot(2,2,4)
        histogram(Speed,20)
        xlim([-20 20]);
        title('Histo speeds')
    end
    
    X=linspace(1,NLines-NAvg,NLines-NAvg);
    %histogram(Speed,20)

    if SaveVideo
          frame=getframe(gcf);
          writeVideo(v,frame);
    end
      pause(0.05)
    
end

 if SaveVideo
     close(v)
 end

 %Generation of the profile, and Canal normalized position (X)
 
SmoothedProfile=smooth(LocalMean);
CanalPos=find(SmoothedProfile~=0);
X=-(X-CanalPos(end))*PixelSize;

% %Plot profile without errorbars
% figure(10)
% plot(X,smooth(squeeze(LocalMean)))
% xlabel('Normalized Dorso-ventral position')
% ylabel('Average Rostro-Caudal Speed (um/s)')
% 
% %Plot profile with errorbars
% figure(2)
% 
% errorbar(X,smooth(squeeze(LocalMean)),squeeze(LocalSE));
% xlabel('Normalized Dorso-ventral position')
% ylabel('Average Rostro-Caudal Speed (um/s)')
% 

%Save the value of all particle speeds but only for the max and min
%position (for validation)

[~,Posm]=min(SmoothedProfile);
[~,PosM]=max(SmoothedProfile);

VentralTraces=SpeedAll(PosM,:);
VentralTraces=VentralTraces(VentralTraces~=0);% Because I had to define a matrix where all lines have the same size, there are zeros at the end. I could have used a struct instead
DorsalTraces=SpeedAll(Posm,:);
DorsalTraces=DorsalTraces(DorsalTraces~=0);% Because I had to define a matrix where all lines have the same size, there are zeros at the end. I could have used a struct instead



%Save the variables in a .mat file : The variables are saved in a structure whose name is the name of the original file  

Name=strrep(Name,'-','_');
Name=strrep(Name,' ','_');
if ~isletter(Name(1))
    Name=strcat('F',Name);
end

try
    OriginalName=Name;
    eval(strcat(Name,'.Pos =X;'))
catch
    Name=strcat('Sample',num2str(n));
    OriginalName=Name;
    eval(strcat(Name,'.Pos =X;'))
end
disp(Name)
eval(strcat(Name,'.Speed =LocalMean;'))
eval(strcat(Name,'.SE =LocalSE;'))
eval(strcat(Name,'.HistoMax=VentralTraces;'))
eval(strcat(Name,'.HistoMin=DorsalTraces;'))

if n>1
    if mod(Output,2)==1 % Save as .mat
        save(strcat(DataPath,'SpeedvsPos_AllTraces.mat'),Name,'-append');
    end
    
    if Output>1 % Save as .xls
        xlswrite(strcat(DataPath,'FlowProfile.xlsx'),[X;LocalMean;LocalSE],OriginalName);
    end
        
else
     if mod(Output,2)==1 % Save as .mat
         save(strcat(DataPath,'SpeedvsPos_AllTraces.mat'),Name);
     end
     
     if Output>1 %Save as .xls
         xlswrite(strcat(DataPath,'FlowProfile.xlsx'),[X;LocalMean;LocalSE],OriginalName);
     end
end

%Generate the output structure
eval(strcat('CSFProfile=',Name,';'))

end
 

   