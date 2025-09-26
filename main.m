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
%---------------------------------------
[PNPND,PVVND,PNVND,PGTND,MRstr,Nusers] = preturcam(nacionalidad,genero,rangoedad,NPND,VVND,NVND,GTND,NA,GE,AC,TA,MV,OA,SP,MVE,FV,GR,Dtestmethod,K,beta,lambda,num_runs_GD,stddev,itermethod,num_iter,biased,num_runs_RMSE);
%---------------------------------------
if NPND==0, disp(sprintf('PNPND=%d',PNPND)); end;
if VVND==0, disp(sprintf('PVVND=%d',PVVND)); end;
if NVND==0, disp(sprintf('PNVND=%d',PNVND)); end;
if GTND==0, disp(sprintf('PGTND=%d',PGTND)); end;