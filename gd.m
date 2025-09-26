function [RMSE,w1,w2,nu,bs,bi] = gd(S,I,p,DtrainS,DtrainI,DtestS,DtestI,K,beta,lambda,num_runs_GD,itermethod,num_iter,biased,stddev)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Gradient descend
%
% ENTRADAS:
% ========
% S            - n�mero de estudiantes (filas de matriz p)
% I            - n�mero de tareas (columnas de p)
% p            - matriz de rendimientos, tiene valores conocidos y desconoc. (entre 0 y 1)
% Dtrain       - especifica valores de entrenamiento (fila S, columna I)
% Dtest        - especifica valores de test (fila S, columna I)
% K            - n�mero de factores latentes
% beta         - tasa de aprendizaje
% lambda       - factor de regularizaci�n
% num_runs_GD  - n�mero de ejecuciones de GD; la mejor ejecuci�n es la que
%                da el error (no RMSE) m�nimo en los datos de entrenamiento;
%                con esta mejor ejecuci�n se calcula RMSE de datos de test
% itermethod   - m�todo de parada de GD:
%                0: se alcanza un n�mero dado de iteraciones de GD
%                1: no mejora el error m�nimo en la siguiente iteraci�n
%                mejor m�todo 0; el m�todo 1 puede estancarse en alguna
%                iteraci�n, sobre todo si stddev es alto
% num_iter     - iteraciones de GD, aplicable solo si itermethod=0
% biased       - MF con predisposici�n (1) o est�ndar (0)
% stddev       - desviaci�n est�ndard para inicializar GD: stddev=sigma
%                utilizar stdev=0.1 (sigma^2=0.01) para scores entre 0 y 1 (normalizados)
%
% SALIDAS:
% =======
% RMSE         - valor de la m�trica RMSE
% w1           - matriz W1 para la predicci�n
% w2           - matriz W2 para la predicci�n
% nu           - promedio global
% bs           - predisposici�n del estudiante
% bi           - predisposici�n de la tarea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ntrain=size(DtrainS,2);
Ntest=size(DtestS,2);

errmean = 0;    % Error medio
errmin  = Inf;  % Error m�nimo
for run = 1:num_runs_GD
    %=========== run: FASE DE ENTRENAMIENTO
    %--- Inicializaci�n de par�metros predisposici�n
    nu=0;          %--- nu
    bs=[];         %--- bs
    bi=[];         %--- bi
    if biased == 1
        %nu=0;          %--- nu
        for ctrain=1:Ntrain   
            s=DtrainS(ctrain);
            i=DtrainI(ctrain);
            nu=nu+p(s,i);
        end
        nu=nu/Ntrain;
        %bs=[];         %--- bs
        for cs = 1:S
            bs(cs)=0;
            cont=0;
            for ctrain=1:Ntrain
                s=DtrainS(ctrain);
                i=DtrainI(ctrain);
                if s>cs
                    ctrain = Ntrain;
                elseif s == cs
                    bs(cs)=bs(cs)+p(s,i)-nu;
                    cont=cont+1;
                end
                %if s == cs
                %    bs(cs)=bs(cs)+p(s,i)-nu;
                %    cont=cont+1;
                %end
            end
            bs(cs)=bs(cs)/cont;
        end
        %bi=[];         %--- bi
        for ci = 1:I
            bi(ci)=0;
            cont=0;
            for ctrain=1:Ntrain
                s=DtrainS(ctrain);
                i=DtrainI(ctrain);
                if i == ci
                    bi(ci)=bi(ci)+p(s,i)-nu;
                    cont=cont+1;
                end
            end
            bi(ci)=bi(ci)/cont;
        end
    end
    %--- Inicializaci�n de W1 y W2
    w1 = zeros(S,K);
    w2 = zeros(I,K);
    mean = 0;
    for s = 1:S
        for k = 1:K
            w1(s,k) = abs(normrnd(mean,stddev));
        end
    end
    for i = 1:I
        for k = 1:K
            w2(i,k) = abs(normrnd(mean,stddev));
        end
    end
    nw1=w1; % Almacena temporalmente la matriz actualizada
    nw2=w2;
    %--- Gradiente en Descenso
    err=[];
    errminrun = Inf;
    itermin   = 1;    
    iter      = 1;
    iter_stop = 0;
    err_last  = Inf;
    while iter_stop == 0        
        %--------------- Comienzan iteraciones
        nfw1=norm(w1,'fro');
        nfw2=norm(w2,'fro');
        reg=lambda*(nfw1^2+nfw2^2);
        err(iter)=0;
        for ctrain=1:Ntrain   % Solamente datos entrenamiento
            %---
            s=DtrainS(ctrain);
            i=DtrainI(ctrain);
            %---
            if biased == 1
                %--- Calcula el error (MF con predisposici�n)
                ppsi=0;
                for k=1:K
                    ppsi = ppsi + w1(s,k)*w2(i,k);
                end
                ppsi = ppsi + nu + bs(s) + bi(i);      % A�ade nu+bss+bii
                e = p(s,i) - ppsi;
                e2 = e*e + reg;
                err(iter) = err(iter) + e2;
                nu = nu + beta*e;                      % Actualiza nu
                bs(s) = bs(s) + beta*(e-lambda*bs(s)); % Actualiza bs(s)
                bi(i) = bi(i) + beta*(e-lambda*bi(i)); % Actualiza bi(i)
                %---
            else
                %--- Calcula el error (MF sin predisposici�n)
                ppsi=0;
                for k=1:K
                    ppsi = ppsi + w1(s,k)*w2(i,k);
                end
                e = p(s,i) - ppsi;
                e2 = e*e + reg;
                err(iter) = err(iter) + e2;
                %---            
            end
            %--- Calcula el gradiente y actualiza la matriz
            for k=1:K
                nw1(s,k) = w1(s,k)+beta*(2*e*w2(i,k)-lambda*w1(s,k));
                nw2(i,k) = w2(i,k)+beta*(2*e*w1(s,k)-lambda*w2(i,k));
            end %k
            %---
        end %for
        %------- 
        w1 = nw1; % Actualiza la matriz
        w2 = nw2;
        if err(iter) < errminrun
            errminrun = err(iter);
            itermin = iter;
            w1optrun = w1;
            w2optrun = w2;
        end        
        %------- Comprueba si esta iteraci�n debe ser la �ltima      
        if itermethod == 0 % itermethod=0: hasta alcanzar num_iter
            if iter < num_iter
                iter = iter+1;
            else
                iter_stop=1;
            end
        else  % itermethod=1: m�nimo no mejora desde la anterior iteraci�n
            if err(iter) < err_last
                err_last = err(iter);
                iter = iter+1;
            else
                iter_stop=1;
            end
        end % if itermethod               
        %--------------- Terminan iteraciones
    end %iter
    w1 = w1optrun;
    w2 = w2optrun;
    %plot(err);
    %title(sprintf('Experimento (\\beta=%g \\lambda=%g) run #%d: errminrun=%g',beta,lambda,0,errminrun));
    %xlabel('Iteraciones'); ylabel('Error');
    %pause; close;
    %=========== run: FIN FASE DE ENTRENAMIENTO
    errmean = errmean + errminrun;
    if errminrun < errmin
        errmin = errminrun;
        w1opt = w1optrun;
        w2opt = w2optrun;
    end
end % end for run
errmean = errmean/num_runs_GD;
%disp(sprintf('RESULTADOS: errmin=%g, errmean=%g',errmin,errmean));

%=========== Actualiza el modelo con las matrices �ptimas
w1=w1opt;
w2=w2opt;

%=========== C�lculo de RMSE
% Antes o despu�s de la fase de predicci�n, porque
% los datos de test no est�n actualizados en p
sumtest=0;
for ctest=1:Ntest   % Solamente datos de test
    %---
    s=DtestS(ctest);
    i=DtestI(ctest);
    %--- Calcula los rendimientos de los valores de test
    ppsi=0;
    for k=1:K
        ppsi = ppsi + w1(s,k)*w2(i,k);
    end
    if biased == 1
        ppsi = ppsi + nu + bs(s) + bi(i);
    end
    dif = p(s,i)-ppsi;
    sumtest = sumtest + dif*dif;
    %---
end %for
RMSE = sqrt(sumtest/Ntest);
%disp(sprintf('RMSE: %g\n',RMSE));

