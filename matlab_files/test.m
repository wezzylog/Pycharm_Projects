clear; clc; close all;

% --- parameters ---
A   = 1;          % pulse amplitude
tau = 1e-3;       % pulse duration (s)
T   = 4e-3;       % period (s), q = T/tau = 4
N   = 30;         % number of harmonics to show

w1 = 2*pi/T;      % fundamental angular frequency
n  = -N:N;        % harmonic indices

% --- complex coefficients: c_n = (A*tau/T) * sin(x)/x, x = n*pi*tau/T ---
x  = n*pi*tau/T;
cn = (A*tau/T) * ones(size(n));      % n = 0 case: limit sin(x)/x = 1
idx = (x ~= 0);
cn(idx) = (A*tau/T) * sin(x(idx)) ./ x(idx);

% --- envelope: (A*tau/T)*|sin(w*tau/2)/(w*tau/2)| ---
w  = linspace(-N*w1, N*w1, 2000);
xe = w*tau/2;
env = (A*tau/T) * ones(size(w));
ie = (xe ~= 0);
env(ie) = (A*tau/T) * abs(sin(xe(ie)) ./ xe(ie));

% --- plot amplitude spectrum ---
figure;
stem(n*w1, abs(cn), 'filled'); hold on;
plot(w, env, 'r--', 'LineWidth', 1.2);
grid on;
xlabel('\omega (rad/s)');
ylabel('|c_n|');
title(sprintf('Amplitude spectrum, A=%g, \\tau=%g ms, T=%g ms (q=%g)', ...
      A, tau*1e3, T*1e3, T/tau));
legend('|c_n| (lines)', 'envelope');

% --- check: reconstruct signal from the harmonics ---
t = linspace(-1.5*T, 1.5*T, 4000);
s = zeros(size(t));
for k = n
    s = s + cn(k+N+1) * exp(1j*k*w1*t);
end
figure;
plot(t*1e3, real(s)); grid on;
xlabel('t (ms)'); ylabel('s(t)');
title(sprintf('Reconstruction from %d harmonics', N));