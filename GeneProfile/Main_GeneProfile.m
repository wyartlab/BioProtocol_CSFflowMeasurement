clear; close all; clc

%Variables To be defined

CurrentPath=pwd;
addpath(genpath(CurrentPath))

Rotate=0;
Wiener=1;
Display=0;
Avi=0;
Output=0;

Action =0;
Files='';

FrameTime=0.1;
PixelSize=0.189;
FilterSize=5;
Threshold=50;


%Start GUI

H=GeneProfile;
ListHandles=allchild(H);

while  Action>=0
    
    if Action >0&&Action<4 %Then performs the action
        
        if iscell(Files) %It is the case if several files are chosen
            Nfiles=size(Files,2);%I keep the cell structure
        elseif length(Files)>=1 %If one file only, it outputs a char with many characters
            Nfiles=1;
            Files2{1,1}=Files;
            Files=Files2;
            clear Files2
        else
            Nfiles=0;
            hTemp=msgbox('Please select some file(s) first');
            Action=0;
            pause(5)
            delete(hTemp)
            
        end
        
        %Find the desired ouput from the checkboxes
        Output=get(ListHandles(2),'Value')+2*get(ListHandles(1),'Value');%0 if no output, 1 if .mat, 2 if.xls, 3 if both
        
        %Opens the first file and apply rotation (if asked) and Wiener filter (if asked)
        
        if Nfiles>0 %Updates the value of the parameters that will be used
            FrameTime=str2double(get(ListHandles(8),'String'));
            PixelSize=str2double(get(ListHandles(7),'String'));
            FilterSize=str2double(get(ListHandles(6),'String'));
            Threshold=str2double(get(ListHandles(5),'String'))/100;
            
            if isempty(Ima)% Open the .tif file. If Ima already exists, I don't load the data again.
                try
                    
                    DataFile=strcat(FilePath,'\',Files{1}); %For Windows
                    
                catch
                    
                    DataFile=strcat(FilePath,Files{1}); %For Mac
                    
                end
                
                %Image parameters
                Infos=imfinfo(DataFile);
                NCol=Infos(1).Width;
                NLines=Infos(1).Height;
                NImages=numel(Infos);
                Ima=zeros(NLines,NCol,NImages);
                
                for ii=1:NImages
                    Ima(:,:,ii) = double(imread(DataFile,'Index',ii,'Info', Infos));
                    %Ima(:,:,ii)=Ima(:,:,ii)./mean(mean(Ima(:,:,ii)));
                end
            end
            
            if Rotate % I perform two rotations and crop
                NewIma=RotateAndCropImage(Ima); %#ok<UNRCH>
                NewIma=RotateAndCropImage(NewIma);
            else
                NewIma=Ima;
            end
            
            if Wiener
                for ii=1: NImages
                    NewIma(:,:,ii)=wiener2(NewIma(:,:,ii),[FilterSize FilterSize]);
                end
            end
        end
        
        switch Action
            case 1
                for nn=1:Nfiles
                    if nn>1
                        try
                            
                            DataFile=strcat(FilePath,'\',Files{nn}); %For Windows
                            
                        catch
                            
                            DataFile=strcat(FilePath,Files{nn}); %For Mac
                            
                        end
                        
                        %Image parameters
                        Infos=imfinfo(DataFile);
                        NCol=Infos(1).Width;
                        NLines=Infos(1).Height;
                        NImages=numel(Infos);
                        Ima=zeros(NLines,NCol,NImages);
                        
                        for ii=1:NImages
                            Ima(:,:,ii) = double(imread(DataFile,'Index',ii,'Info', Infos));
                            %Ima(:,:,ii)=Ima(:,:,ii)./mean(mean(Ima(:,:,ii)));
                        end
                        
                        if Rotate % I perform two rotations.
                            NewIma=RotateAndCropImage(Ima); %#ok<UNRCH>
                            NewIma=RotateAndCropImage(NewIma);
                        else
                            NewIma=Ima;
                        end
                        
                        if Wiener
                            for ii=1: NImages
                                NewIma(:,:,ii)=wiener2(NewIma(:,:,ii),[FilterSize FilterSize]);
                            end
                        end
                        
                    end
                    
                    Name=Files{nn};
                    Name=Name(1:end-4);
                    CSFProfile(nn)=Automatic_Kymograph_GUI_2020(NewIma,FilePath,Name,nn,PixelSize,FrameTime,Avi,Display,Threshold,Output);
                    plot(ListHandles(24),CSFProfile(nn).Pos, smooth(CSFProfile(nn).Speed),'linewidth',2)
                    xlabel(ListHandles(24),'Dorso-ventral position (um)')
                    ylabel(ListHandles(24),'Average Rostro-Caudal Speed (um/s)')
                    legend(ListHandles(24),'Experimental data')
                    
                    set(ListHandles(19),'BackgroundColor',[0,1,0]);
                    set(ListHandles(4),'BackgroundColor',[0,1,0]);
                end
                
            case 2
                Kymo=permute(NewIma,[3 2 1]);
                [~,PosMax]=max(mean(mean(Kymo)));
                
                imagesc(ListHandles(23),Kymo(:,:,PosMax))
                set(ListHandles(16),'BackgroundColor',[0.93,0.69,0.13]);
                
            case 3
                Kymo=permute(NewIma,[3 2 1]);
                [~,PosMax]=max(mean(mean(Kymo)));
                
                imagesc(ListHandles(23),Kymo(:,:,PosMax))
                Kymo=rescale(Kymo,0,1);
                Min=quantile(Kymo(:,:,PosMax),Threshold,'all');
                Kymo(Kymo<Min)=Min;
                Kymo=rescale(Kymo,1,2);
                Kymo=Kymo./repmat(mean(Kymo,1),NImages,1);
                
                Kymo_Avg=mean(Kymo(:,:,PosMax-1:PosMax+1),3);
                
                imagesc(ListHandles(24),Kymo_Avg>1.01)
                set(ListHandles(15),'BackgroundColor',[0.93,0.69,0.13]);
                
                
        end
        
        drawnow();
        Action=0;
        
    elseif Action==4
        
                if isempty(CSFProfile)
                    hTemp=msgbox('Please calculate experimental profile first');
                    Action=0;
                    pause(3)
                    delete(hTemp)
                else
                    TheoreticalProfile=Fit_CSFmodel(CSFProfile);   
                    
                    for nn=1:Nfiles
                        plot(ListHandles(24),CSFProfile(nn).Pos, smooth(CSFProfile(nn).Speed),'linewidth',2)
                        hold(ListHandles(24),'on')
                        plot(ListHandles(24),TheoreticalProfile(nn).X,TheoreticalProfile(nn).Profile,'-r','linewidth',2)
                        xlabel(ListHandles(24),'Dorso-ventral position')
                        ylabel(ListHandles(24),'Average Rostro-Caudal Speed (um/s)') 
                        legend(ListHandles(24),'Experimental data', 'Theoretical model')

                        figure
                        plot(CSFProfile(nn).Pos, smooth(CSFProfile(nn).Speed),'linewidth',2)
                        hold on
                        plot(TheoreticalProfile(nn).X,TheoreticalProfile(nn).Profile,'-r','linewidth',2)
                        xlabel('Dorso-ventral position (um)')
                        ylabel('Average Rostro-Caudal Speed (um/s)') 
                        legend('Experimental data', 'Theoretical model (eLife 2020)')
                        try
                            Name=Files{nn};
                            Name=Name(1:end-4);
                            saveas(gcf,strcat(FilePath,Name,'_Profile.fig'))
                            saveas(gcf,strcat(FilePath,Name,'_Profile.png'))
                        catch
                            saveas(gcf,strcat(FilePath,'File',num2str(nn),'_Profile.fig'))
                            saveas(gcf,strcat(FilePath,'File',num2str(nn),'_Profile.png'))
                        end
                        close(gcf)
                        
                        pause(5)
                        
                        hold(ListHandles(24),'off')
                    end
                    if mod(Output,2)==1 % Save as .mat
                        save(strcat(FilePath,'TheoreticalProfiles.mat'),'TheoreticalProfile');
                    end
                    
                    if Output>1 % Save as .xls

                        NameStruct=fieldnames(TheoreticalProfile(1));
                        SaveStructAsXls(TheoreticalProfile,strcat(FilePath,'TheoreticalProfiles.xlsx'),NameStruct);

                    end
                    Action=0;
                end
    else
        pause(0.5)
    end
    
end

