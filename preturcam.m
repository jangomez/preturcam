function [PNPND,PVVND,PNVND,PGTND,MRstr,Nusers] = preturcam(nacionalidad,genero,rangoedad,NPND,VVND,NVND,GTND,NA,GE,AC,TA,MV,OA,SP,MVE,FV,GR,Dtestmethod,K,beta,lambda,num_runs_GD,stddev,itermethod,num_iter,biased,num_runs_RMSE)
%===============================================================
% Entradas:
% ---------
% nacionalidad : 'AL', 'FR', 'IT', 'PT', 'UK'
% genero       : 'H', 'M'
% rangoedad    : '15-24', '25-44', '45-65', '66-M'
% NPND         : Nº pernoctaciones  : 0: (desconocido); 1 (muy pocas); 2 (pocas); 3 (normal) ; 4 (bastantes); 5 (muchas)
% VVND         : Valoración viaje   : 0: (desconocido); 1 (pésima)   ; 2 (mala) ; 3 (regular); 4 (buena)    ; 5 (excelente)
% NVND         : Nº visitas anter.  : 0: (desconocido); 1 (muy pocas); 2 (pocas); 3 (normal) ; 4 (bastantes); 5 (muchas)
% GTND         : Gasto total        : 0: (desconocido); 1 (muy bajo) ; 2 (bajo) ; 3 (medio)  ; 4 (alto)     ; 5 (muy alto)
% NA
% GE
% AC           : Acceso entrada     : 0: S/D; 1: Carretera, 2: Aeropuerto; 3: Puerto; 4: Tren
% TA           : Tipo alojamiento   : 0: S/D; 1: Hoteles o similares; 2: Alojamiento en alquiler; 3: Camping; 4: Casa Rural; 5: Crucero; 6: Otro alojamiento de mercado; 7: Vivienda en propiedad; 8: Vivienda de familiares/amigos; 9: Otro alojamiento no de mercado
% MV           : Motivo viaje       : 0: S/D; 1: Ocio, vacaciones; 2: Negocios; 3: Estudios; 4: Personal (salud, familia); 5: Otros motivos
% OA           : Ocupación actual   : 0: S/D; 81: Ocupado, trabajando; 82: Jubilado, retirado; 83: Parado (buscando trabajo); 84: Estudiante; 85: Labores del hogar; 86: Otro (rentista, servicio militar, etc.) 
% SP           : Situación prof.    : 0: S/D; 1: Empresario autónomo; 2: Asalariado. cargo alto dirección, etc.; 3: Asalariado cargo medio; 4: Asalariado sin cualificación 
% MVE          : Motivo viaje (ext.): 0: S/D; 1: Asistencia a ferias, congresos y convenciones; 2: Trabajador estacional (temporero); 3: Otros motivos de trabajo y negocios; 4: Estudios (educación y formación); 5: Visitas a familiares y amigos; 6: Tratamiento de salud, voluntario; 7: Motivos religiosos o peregrinaciones; 8: Compras o servicios personales; 9: Turismo gastronómico; 10: Turismo cultural; 11: Práctica deportiva; 12: Turismo de sol y playa; 13: Turismo de naturaleza; 14: Incentivos de empresa; 15: Otros tipos de ocio; 16: Otros
% FV           : Frecuencia viajes  : 0: S/D; 1: Semanalmente, en fin de semana; 2: Semanalmente, entre semana; 3: Una vez por mes; 4: Una vez por trimestre; 5: Una vez por semestre; 6: Una vez al año; 7: Menor frecuencia
% GR           : Grupo              : 0: S/D; 1: Sólo / 2: Con su pareja; 3: Con mi familia incluyendo hijos; 4: Con mi familia sin incluir hijos; 5: Con mi familia y amigos; 6: Con amigos; 7: Con compañeros de trabajo o estudios
% Dtestmethod  : Cómo generar Dtest : 1: uno por fila, columnas seguidas, saltar si desconocido; 2: Dtest=Dtrain
% K            : Número de factores latentes
% beta         : Tasa de aprendizaje
% lambda       : Factor de regularización
% num_runs_GD  : Nº ejecuciones de GD; la mejor ejecución es la que da el error (no RMSE) mínimo en los datos de entrenamiento; con esta mejor ejecución se calcula RMSE de datos de test
% stddev       : Desviación estándard para inicializar GD, stddev=sigma. Utilizar stdev=0.1 (sigma^2=0.01) para scores entre 0 y 1 (normalizados)
% itermethod   : Método de parada de GD: 0: Se alcanza un número dado de iteraciones de GD (usar este método por defecto); 1: no mejora el error mínimo en la siguiente iteración (este método puede estancarse en alguna iteración, sobre todo si stddev es alto)
% num_iter     : Iteraciones de GD, aplicable solo si itermethod=0
% biased       : MF con predisposición (1) o estándar (0)
% num_runs_RMSE: N1 de ejecuciones distintas para la predicción, para escoger la que produzca menor RMSE
%
% Salidas:
% ---------
% PNPND        : Predicción del nº de pernoctaciones
% PVVND        : Predicción de la valoración del viaje
% PNVND        : Predicción del nº de visitas anteriores
% PGTND        : Predicción de la frecuencia de viajes
%=============================================== Carga
MRstr = strcat('MR_',nacionalidad,'_',genero,'_',rangoedad);
%------------------- Cargamos matriz de ratings particular
%load(strcat('matrices/',MRstr,'.mat'));  % users y MR
load(strcat(MRstr,'.mat'));  % users y MR
Nusers = length(users);
%=============================================== 
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
end;
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
%------------------- Resultados de la predicción, decodificados a la normalización 1-5
PNPND = 1+p(S,1)*(5-1);
PVVND = 1+p(S,2)*(5-1);
PNVND = 1+p(S,3)*(5-1);
PGTND = 1+p(S,4)*(5-1);
%-------------------


