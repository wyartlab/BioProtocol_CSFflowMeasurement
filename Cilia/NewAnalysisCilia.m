clear % Clear all Variables

% Add the program directory and subdirectory to memory
CurrentPath=pwd;
addpath(genpath(CurrentPath))

%%%%%%%%%%%%%%%%%%%%Adjustable parameters%%%%%%%%%%%%%
AcqFreq=100;%Hz
DrawCentralLine=0; % If 1, asks the user to draw the central line to distinguish between ventral and dorsal cilia.
SzAvg=4; %Size of local spatial average to increase SNR

AllFreq=zeros(9,10);
Compt=0;

%%%%%%%%%%%%%Choose directory where data .tif files are%%%%%%%%%

DataPath=uigetdir('','Choose Start Folder');
cd(DataPath)

%Find and analyze every .tif file one after the other
list=ls('*.tif');
if DrawCentralLine
    CentralLine=cell(1,size(list,1));
end

for nn=1:size(list,1)
    FileTif=strtrim(list(nn,:));
    SaveFigure=strcat(FileTif(1:end-4),'.png');
    SaveFreq=strcat(FileTif(1:end-4),'.mat');
    
    %%Open .tif file
    [Ima,Size]=OpenTif(FileTif);
    
    %Local Average (Smooth)to increase the SNR
    FilteredIma=Local2DAverage(Ima,SzAvg);
    imagesc(FilteredIma(:,:,1))
    
    %Draw CentralLine (if requested)
    if DrawCentralLine
        %Write a function
        imagesc(FilteredIma(:,:,1))
        title('Draw central line')
        [x, y] = getline;
        SeparationLine=zeros(2,1+ceil(x(end))-floor(x(1)));
        SeparationLine(1,:)=(floor(x(1)):ceil(x(end)));
        Compt=0;
        for zz=1:(length(x)-1)
            Length=sum(SeparationLine(1,:)<x(zz+1)&SeparationLine(1,:)>x(zz));
            SeparationLine(2,1+Compt:Compt+Length)=(y(zz):(y(zz+1)-y(zz))/(Length-1):y(zz+1));
            Compt=Compt+Length;
        end
        SeparationLine(2,Compt:end)=y(end);
        hold on
        plot(SeparationLine(1,:),SeparationLine(2,:),'r','linewidth',2)
        pause(0.1)
        CentralLine{nn}=SeparationLine;
    end
    
    %Calculate FFt and PSD
    
    [Freq,Freq_FromPSD]=CalculateFreqAndPSDMap(FilteredIma,Size,nn,AcqFreq);
    
    
    %%%%%%%%%%%%%%Analyze frequency maps %%%%%%%%%%
    FrequencyMap=Freq(:,:,1)*0;
    
    for ff=1:9 % I divide the frequency into 9 bands of 5 Hz
        
        %Create the binary image
        Freq2=Freq(:,:,1);
        Freq2=Freq2>ff*5&Freq2<(ff+1)*5;
        
        Freq2=bwlabel(Freq2, 8);
        Freq2=imfill(Freq2);
        
        %Find Regions of interest in the image
        blobMeasurements = regionprops(Freq2, Freq(:,:,1), 'all');
        %Keep only regions with Area > 40 pixels
        EffectiveCilia=blobMeasurements([blobMeasurements.Area]>40);
        keeperIndexes = find([blobMeasurements.Area]>40);
        keeperBlobsImage = ismember(Freq2, keeperIndexes);
        FrequencyMap=FrequencyMap+keeperBlobsImage.*Freq(:,:,1);
        keeperBlobsImage= bwlabel(keeperBlobsImage, 8);
        
        if DrawCentralLine
            SeparationLine=CentralLine{nn};
            AngleLine=atan(diff(SeparationLine(2,:),1,2))*180/pi;
        end
        
        NAreas=size(EffectiveCilia,1);% Number of cilia
        %Position of cilia
        PosCilia(1:2,Compt+1:Compt+NAreas)=reshape([EffectiveCilia.Centroid],2,NAreas);
        %Frequency
        AllFreq(1,Compt+1:Compt+NAreas)=[EffectiveCilia.MeanIntensity];
        %Diameter
        AllFreq(2,Compt+1:Compt+NAreas)=[EffectiveCilia.EquivDiameter];
        %Eccentricity
        AllFreq(4,Compt+1:Compt+NAreas)=[EffectiveCilia.Eccentricity];
        %Area
        AllFreq(5,Compt+1:Compt+NAreas)=[EffectiveCilia.Area];
        %Major Axis Length
        AllFreq(6,Compt+1:Compt+NAreas)=[EffectiveCilia.MajorAxisLength];
        %File number
        AllFreq(8,Compt+1:Compt+NAreas)=nn;
        
        
        if DrawCentralLine %If the central line is drawn, it saves the orientation depending on the position of the cilia + Saves if dorsal or ventral + Saves if too far from central canal (to be discarded)
            CiliaAngle=[EffectiveCilia.Orientation];
            IsDorsal=reshape([EffectiveCilia.Centroid],2,NAreas);
            
            for zz=1:NAreas
                [~,Idx]=min(abs(round(SeparationLine(1,:)-IsDorsal(1,zz))));
                AllFreq(3,Compt+zz)=CiliaAngle(zz)+AngleLine(max(1,Idx-1));
                AllFreq(3,Compt+zz)=90-AllFreq(3,Compt+zz);% Je calcule l'angle par rapport à la verticale
                AllFreq(7,Compt+zz)=(IsDorsal(2,zz)>SeparationLine(2,Idx)); %1 if ventral 0 if dorsal
                AllFreq(9,Compt+zz)=abs(IsDorsal(2,zz)-SeparationLine(2,Idx))<35;%1 if not too far (6.5um away) from central canal cetral line
            end
        else
            AllFreq(3,Compt+1:Compt+NAreas) =[EffectiveCilia.Orientation];
            AllFreq(7,Compt+1:Compt+NAreas)=-1*ones(NAreas,1);
            AllFreq(9,Compt+1:Compt+NAreas)=ones(NAreas,1);
            
        end
        
        Compt=Compt+NAreas;
    end
    
    imagesc(FrequencyMap,[5 AcqFreq/2])
    
    %Save 2D map
    save(SaveFreq,'Freq','Freq_FromPSD','AllFreq','FrequencyMap')
    
end
