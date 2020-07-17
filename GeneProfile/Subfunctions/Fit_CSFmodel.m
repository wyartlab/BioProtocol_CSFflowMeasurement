
%% Program to automatically fit the experimental velocity profiles
function FitProfile=Fit_CSFmodel(Profile)

NSamples=size(Profile,2);
FitProfile=struct([]);
for nn=1:NSamples
    Sample=Profile(nn);
    
    % Detection of the ventral wall (VW) and dorsal wall (DW)
    selvw = find(Sample.Speed==0);
    diff_selvw = diff(selvw);
    frontier_w = find(diff_selvw==max(diff_selvw));
    VW = selvw(frontier_w-1);
    DW = selvw(frontier_w+1);
    
    %     figure
    % plot(Sample.Pos,smooth(Sample.Speed))
    % hold on
    % plot(Sample.Pos(VW),Sample.Speed(VW),'ro')
    % plot(Sample.Pos(DW),Sample.Speed(DW),'bs')
    
    Pos_dim = Sample.Pos(VW:DW);
    Speed_dim = Sample.Speed(VW:DW);
    Pos_dim = fliplr(Pos_dim);
    Speed_dim = fliplr(Speed_dim);
    
    Max_speed = max(Speed_dim);
    
    %Fit
    xc = [0 0 max(Pos_dim)];
    yc = [0 0 0];
    cc = [max(Pos_dim) 0 max(Pos_dim); 0 0 0; 0 0 0];
    con = struct('xc',xc,'yc',yc,'cc',cc);
    AA = splinefit(Pos_dim,Speed_dim,2,3,con);
    PP = ppval(AA,linspace(0,max(Pos_dim),10000));
    
    V_MMAX = max(abs(Sample.Speed));
        V_mean_abs = mean(abs(Sample.Speed));
    %V_mean_abs = mean(abs(PP));
    %V_mean = abs(mean(PP));
    V_mean=mean(Sample.Speed);
    Ratio_Mean = abs(V_mean)/V_mean_abs;
    Ratio_Max = abs(V_mean)/V_MMAX;
    
    FIT1=NaN;
    FIT2=NaN;
    if Ratio_Mean > 0.30
        WARNING = strcat('WARNING : the flow is weakly bidirectional. The fraction of the total flow rate that is bidirectional is as low as  ',num2str(round((1-Ratio_Mean)*100)),...
            '%. We thereby do not advise to fit the velocity profile with the model developed in Thouvenin et al. (eLife 2020)');
        FIT1=menu({WARNING,'Do you want to stop the analysis, or to fit anyway ?'},'Stop here','Fit anyway');
        
        %There should be two button following the question : 'Do you want to stop
        %the analysis, or to fit anyway ? Proposing a choice between 'Stop here'
        % and 'Fit anyway'.
        
    else
        
        VALIDATION = strcat('The flow is mainly bidirectional (',num2str(round((1-Ratio_Mean)*100)),'% of the flow rate) and could be fitted by the model developed in Thouvenin et al. (eLife 2020). Do you want to fit ?');
        FIT2 = menu(VALIDATION,'Yes','No');
    end
    
    FitProfile(nn).X=linspace(0,max(Pos_dim),10000);
    if FIT1==2||FIT2 == 1
        
        FitProfile(nn).Profile=PP;
        FitProfile(nn).Flow=round((1-Ratio_Mean)*100);
        FitProfile(nn).Diameter=Pos_dim(end)-Pos_dim(1);
        FitProfile(nn).l_cilia = AA.breaks(2);
        mu_CSF=10^-3; %Pa.s
        FitProfile(nn).f_v=abs(AA.coefs(1,1)-AA.coefs(2,1))*2*mu_CSF*10^6;%unit: Pa/m
        FitProfile(nn).GradP=abs(AA.coefs(1,1))*2*mu_CSF*10^6;
        
    else
        FitProfile(nn).Profile=ones(10000,1)*0;
        FitProfile(nn).Flow=round((1-Ratio_Mean)*100);
        FitProfile(nn).Diameter=Pos_dim(end)-Pos_dim(1);
        FitProfile(nn).l_cilia = 0;
        FitProfile(nn).f_v=0;%unit: Pa/m
        FitProfile(nn).GradP=0;
  
    end
    
end

end
