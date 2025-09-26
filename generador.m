%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generador de las 40 matrices de ratings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%-------
tablaMRG = readtable('MRG.csv');
dimMRG = size(tablaMRG);
%-------
NusersG  = dimMRG(1);
NitemsG  = dimMRG(2)-1;
usersG   = table2array(tablaMRG(:,1));
items   = {'NPND','VVND','NVND','GTND','NA','GE','AC','TA','MV','OA','SP','MVE','FV','GR'};
ratingsG = table2array(tablaMRG(:,2:15));
%---------------------------
nacionalidad = {'AL','FR','IT','PT','UK'};
NA           = [126 ,110 ,115 ,123 ,125];
genero       = {'H','M'};
rangoedad    = {'15-24','25-44','45-65','66-M'};
GE           = [5,7,9,11,6,8,10,12];
GE_str       = {'M_15-24','M_25-44','M_45-65','M_66-M','H_15-24','H_25-44','H_45-65','H_66-M'};
%---------------------------
for inac = 1:length(NA)
    for iGE = 1:length(GE)
        %------- creamos matriz de ratings
        MR    = [];
        users = {};
        MRstr = strcat('MR_',nacionalidad{inac},'_',GE_str{iGE});
        disp(MRstr);
        %------- recorremos matriz general
        cont = 1;
        for iu = 1:NusersG
            if ratingsG(iu,5) == NA(inac)         % comprobamos nacionalidad
                if ratingsG(iu,6) == GE(iGE)     % comprobamos genero y edad
                    MR(cont,:)  = ratingsG(iu,:);  % copiamos fila
                    users{cont} = usersG{iu};     % copiamos usuario
                    cont = cont+1;
                end
            end
        end
        %------- guardamos matriz ratings particular
        save(strcat(MRstr,'.mat'),'MR','users');       %load MRstr;
        %-------
    end
end
disp('Fin.');

