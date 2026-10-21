%% Sawtooth Wave Generator - Full Example
% Shows several ways to generate a sawtooth wave in MATLAB:
%   1. Built-in sawtooth() function (Signal Processing Toolbox)
%   2. Toolbox-free method using mod()
%   3. Additive synthesis (Fourier series)
% Also includes a spectrum plot and optional audio playback.

clear; clc; close all;

%% ---------------- Parameters ----------------
fs = 44100;          % Sampling frequency (Hz)
f  = 100;            % Wave frequency (Hz)
A  = 1;              % Amplitude
T  = 0.05;           % Duration to plot (s)
N  = 20;             % Number of harmonics for Fourier synthesis

t = 0:1/fs:T;        % Time vector

%% ---------------- Method 1: sawtooth() function ----------------
if exist('sawtooth', 'file')
    x1 = A * sawtooth(2*pi*f*t);        % Rising sawtooth, -A to A
    x1_fall = A * sawtooth(2*pi*f*t, 0);% Falling sawtooth
    x1_tri = A * sawtooth(2*pi*f*t, 0.5); % Triangle wave
    has_toolbox = true;
else
    warning('sawtooth() not found (Signal Processing Toolbox missing). Skipping Method 1.');
    has_toolbox = false;
end

%% ---------------- Method 2: Using mod() (no toolbox) ----------------
x2 = A * (2*mod(f*t, 1) - 1);           % Rising sawtooth, -A to A
x2_fall = A * (1 - 2*mod(f*t, 1));      % Falling sawtooth

%% ---------------- Method 3: Fourier series ----------------
x3 = zeros(size(t));
for k = 1:N
    x3 = x3 + (-1)^(k+1) * sin(2*pi*k*f*t) / k;
end
x3 = A * (2/pi) * x3;

%% ---------------- Plot time-domain waveforms ----------------
figure('Name', 'Sawtooth Wave Methods', 'Position', [100 100 900 700]);

subplot(3,1,1);
if has_toolbox
    plot(t, x1, 'b', 'LineWidth', 1.5);
    title('Method 1: sawtooth() function');
else
    text(0.5, 0.5, 'Signal Processing Toolbox not available', ...
        'HorizontalAlignment', 'center');
    title('Method 1: sawtooth() function (unavailable)');
end
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(3,1,2);
plot(t, x2, 'r', 'LineWidth', 1.5);
title('Method 2: mod() function (no toolbox)');
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

subplot(3,1,3);
plot(t, x3, 'g', 'LineWidth', 1.5);
title(sprintf('Method 3: Fourier series (%d harmonics)', N));
xlabel('Time (s)'); ylabel('Amplitude'); grid on;

%% ---------------- Plot rising vs falling vs triangle ----------------
figure('Name', 'Wave Shape Variants', 'Position', [150 150 900 500]);
plot(t, x2, 'b', t, x2_fall, 'r', 'LineWidth', 1.5);
hold on;
if has_toolbox
    plot(t, x1_tri, 'k--', 'LineWidth', 1.2);
    legend('Rising sawtooth', 'Falling sawtooth', 'Triangle (width 0.5)');
else
    legend('Rising sawtooth', 'Falling sawtooth');
end
xlabel('Time (s)'); ylabel('Amplitude');
title('Sawtooth Variants'); grid on;

%% ---------------- Frequency spectrum ----------------
t_long = 0:1/fs:1;                      % 1 second for good resolution
x_long = A * (2*mod(f*t_long, 1) - 1);

L = length(x_long);
X = abs(fft(x_long)) / L;
X = X(1:floor(L/2)+1);
X(2:end-1) = 2*X(2:end-1);              % Single-sided spectrum
freqs = (0:floor(L/2)) * fs / L;

figure('Name', 'Spectrum', 'Position', [200 200 900 400]);
plot(freqs, X, 'LineWidth', 1.2);
xlim([0 2000]);
xlabel('Frequency (Hz)'); ylabel('Magnitude');
title('Single-Sided Spectrum of Sawtooth (harmonics at multiples of f)');
grid on;

%% ---------------- Scaled version example (0 to 5 V) ----------------
V = 5 * mod(f*t, 1);                    % Range 0 to 5
figure('Name', 'Scaled Sawtooth', 'Position', [250 250 900 400]);
plot(t, V, 'm', 'LineWidth', 1.5);
xlabel('Time (s)'); ylabel('Voltage (V)');
title('Sawtooth Scaled to 0-5 V'); grid on;

%% ---------------- Audio playback (optional) ----------------
play_audio = false;                     % Set to true to hear it
if play_audio
    t_audio = 0:1/fs:2;                 % 2 seconds
    f_audio = 220;                      % A3 note
    x_audio = 0.3 * (2*mod(f_audio*t_audio, 1) - 1);
    sound(x_audio, fs);
end