%function [PNPND,PVVND,PNVND,PGTND,MRstr,Nusers] = preturcam(nacionalidad,genero,rangoedad,NPND,VVND,NVND,GTND,AC,TA,MV,MVE,SP,GR,OA,FV,Dtestmethod,K,beta,lambda,num_runs_GD,stddev,itermethod,num_iter,biased,num_runs_RMSE)
clear;
%--------------------------------------- Datos de entrada del turista
%----------- Info. identidad
NA=126; nacionalidad='AL';
GE=7; genero='M'; rangoedad='25-44';
%----------- Info. básica
NPND=2; VVND=0; NVND=3; GTND=0;
%----------- Info. complementaria
AC=1; TA=3; MV=0; OA=83; SP=0; MVE=7; FV=0; GR=3;
%--------------------------------------- Datos del algoritmo
%----------- Factorización matricial
K_ini             = 32;
beta_ini          = 0.8;
lambda_ini        = 3;
biased_ini        = 0;
%----------- Gradiente en descenso
itermethod_ini    = 0;
num_iter_ini      = 500;
num_runs_GD_ini   = 5;
stddev_ini        = 0.1;
%----------- Otros
num_runs_RMSE_ini = 3;
Dtestmethod_ini   = 1;
%-----------
K=K_ini; beta=beta_ini; lambda=lambda_ini; biased=biased_ini;
itermethod=itermethod_ini; num_iter=num_iter_ini;
num_runs_GD=num_runs_GD_ini; stddev=stddev_ini;
num_runs_RMSE=num_runs_RMSE_ini; Dtestmethod=Dtestmethod_ini;











%------------------------------- Carga matriz de datos
MRstr = strcat('MR_',nacionalidad,'_',genero,'_',rangoedad);
load(strcat('matrices/',MRstr,'.mat'));  % users y MR
Nusers = length(users);
%------------------------------- Generamos matriz de ratings p
p     = MR(:,1:4);  % Excluyo información complementaria
S     = size(p,1);  % S (num. usuarios)
I     = size(p,2);  % I (num. tareas)
unk   = -1;         % indica rating desconocido
%------------------------------- Normalizar a 0-1
% ratings: enteros de 1 a 5
% rating desconocido: 0
% normalizamos al intervalo 0 a 1; rating desconocido = -1
for s = 1:S
    for i = 1:I
        if p(s,i) == 0, p(s,i)=unk;
        else            p(s,i)= 0.25*(p(s,i)-1);
        end
    end %i
end %s
%------------------------------- Dtrain (todos los ratings conocidos)
DtrainS=[]; DtrainI=[];
contDtrain=1;
for s = 1:S
    for i = 1:I
        if p(s,i) ~= unk
            DtrainS(contDtrain)=s; DtrainI(contDtrain)=i;
            contDtrain=contDtrain+1;
        end
    end %i
end %s
%------------------------------- Dtest
DtestS=[]; DtestI=[];
switch Dtestmethod
    case 1
        %-------
        contDtest=1;
        s=1; i=1; salir=0;
        while (salir==0 )
            if p(s,i) ~= unk
                DtestS(contDtest)=s; DtestI(contDtest)=i;
                contDtest=contDtest+1;
            end
            i=i+1;
            %-------
            if S>I  %--- S>I
                if s==S, salir = 1;
                else     s = s+1;
                end
                if i==(I+1), i=1;
                end
            else    %--- S<=I
                if s==S, s = 1;
                else     s = s+1;
                end
                if i==(I+1), salir=1;
                end
            end
            %-------
        end %s
        %-------
    case 2
        DtestS=DtrainS;
        DtestI=DtrainI;
end % switch
%------------------------------- Datos turista: normalizamos a 0-1 e insertamos en última fila de p
NPND_ini=NPND;
if NPND==0, NPND=unk;
else        NPND=0.25*(NPND-1);
end
VVND_ini=VVND;
if VVND==0, VVND=unk;
else        VVND=0.25*(VVND-1);
end
NVND_ini=NVND;
if NVND==0, NVND=unk;
else        NVND=0.25*(NVND-1);
end
GTND_ini=GTND;
if GTND==0, GTND=unk;
else        GTND=0.25*(GTND-1);
end
S = S+1;
p(S,:)=[NPND,VVND,NVND,GTND];
%------------------------------- Ejecuciones para generar mejor modelo
RMSE_array = [];
RMSE_best  = Inf;  % RMSE mínimo
w1_best    = zeros(S,K);
w2_best    = zeros(I,K);
nu_best    = 0;
bs_best    = [];
bi_best    = [];
for run_RMSE = 1:num_runs_RMSE
    disp(sprintf('Run %d de %d:',run_RMSE,num_runs_RMSE));
    [RMSE,w1,w2,nu,bs,bi] = gd(S,I,p,DtrainS,DtrainI,DtestS,DtestI,K,beta,lambda,num_runs_GD,itermethod,num_iter,biased,stddev);
    RMSE_array(run_RMSE) = RMSE;
    if RMSE < RMSE_best
        RMSE_best = RMSE;
        w1_best = w1;
        w2_best = w2;
        nu_best = nu;
        bs_best = bs;
        bi_best = bi;
    end;
    disp(sprintf('RMSE = %g\n',RMSE));
end;
disp(sprintf('RMSE min    = %g\n',min(RMSE_array)));
disp(sprintf('RMSE max    = %g\n',max(RMSE_array)));
disp(sprintf('RMSE mean   = %g\n',mean(RMSE_array)));
disp(sprintf('RMSE median = %g\n',median(RMSE_array)));
disp(sprintf('RMSE stdev  = %g\n',std(RMSE_array)));

%=========== FASE DE PREDICCIÓN para la mejor ejecución
% Calcula solo los valores desconocidos de la última fila (turista)
s=S;
for i = 1:I
    if p(s,i)==unk %
        %--- Predice rating
        ppsi=0;
        for k=1:K
            ppsi = ppsi + w1_best(s,k)*w2_best(i,k);
        end
        if biased == 1
            ppsi = ppsi + nu_best + bs_best(s) + bi_best(i);
        end
        p(s,i) = abs(ppsi);
        %--- Aproximamos la predicción al rating normalizado más cercano
        p(s,i) = 0.25*(round(1+(p(s,i)/0.25))-1);
        %---
    end %if
end %i

disp(p);
disp(sprintf('mean:         %.4f              %.4f',mean(p(1:135,2)),mean(p(1:135,4))));
disp(sprintf('mean acerc.   %.4f              %.4f',0.25*(round(1+(mean(p(1:135,2))/0.25))-1),0.25*(round(1+(mean(p(1:135,4))/0.25))-1)));


%------------------------------- Descodificamos la normalización a 1-5
NPND = 1+p(S,1)*(5-1);
VVND = 1+p(S,2)*(5-1);
NVND = 1+p(S,3)*(5-1);
GTND = 1+p(S,4)*(5-1);
        
disp(sprintf('\n%d  %d  %d  %d',NPND,VVND,NVND,GTND));

