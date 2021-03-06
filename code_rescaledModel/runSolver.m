clear all; close all;

% Model parameters from experiments
epsi0 = 0.020;  % amplitude-to-depth ratio, reference 0.017.
del0 = 0.23;    % depth-to-wavelength ratio, reference 0.23.
Drat = 0.24;    % depth ratio, reference 0.24.
% Simulation parameters
JJ = 32;        % Reference 32
Nw = 8;         % Reference 8 or JJ/4.
MC = 1E2;       % Reference 1E3 or 5E3 for tfin=10.
% time step parameters
dt = 5E-4;  % Reference 5E-4
nout = 20; % Reference 100
tfin = 1;  % Reference 10

% Choose upstream or downstream
gibup = true;
if gibup == true
    theta = 20.;
    gibd = 1.;
else
    theta = 0.;
    gibd = 0.24;
end
fi = 1; % fi = 1 for outgoing and 0 for incoming


% Run the simulation.
tic;
C2 = (2/3)*pi^2*del0/Nw^2
C3 = (3/2)*pi^(1/2)*epsi0/del0
[uarray, duarray] = SolverKdV_SymplecticM4a_MC(...
    C2,C3,Drat,JJ,MC,theta,gibd,fi,dt,nout,tfin);

% Save output
runtime = round(toc/60, 3, 'significant')
save('output.mat', 'C2','C3','Drat','JJ',...
    'MC','theta','gibd','fi','dt','nout','tfin',...
    'Nw','runtime','uarray', 'duarray');

% Make a histogram of u.
ulist = reshape(uarray,1,[]);
figure(1); histogram(ulist);
figure(2); histogram(ulist); set(gca,'yscale','log');
skewu = skewness(ulist)
% Make a plot to see the waves.
%x=(-pi:2*pi/J:pi-2*pi/J)';
%contourf(T,x,uarray(:,1,:));