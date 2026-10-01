delay = 5;

delayed = [zeros(1, delay), measured];

n_measured = 0:length(measured)-1;
n_delayed = 0:length(delayed)-1;

%% Plot the original noisy signal and the delayed signal
figure;
plot(n_measured, measured, 'Color', [0.6 0.6 0.6], 'LineWidth', 1.2);
hold on;
plot(n_delayed, delayed, 'r--', 'LineWidth', 1.5);
hold off;

grid on;
xlabel('Sample index n');
ylabel('Amplitude');
title('Original Noisy Signal vs Delayed Signal');
legend('Original Noisy Signal', 'Delayed Signal');


%% Task 3: Five-Point Moving-Average Filter

% Импульсная характеристика 5-точечного скользящего среднего
h5 = ones(1, 5) / 5;

% Свертка с сохранением исходной длины сигнала
filtered5 = conv(measured, h5, 'same');

% Построение графика
figure;
plot(n, clean, 'b', 'LineWidth', 1.5);
hold on;
plot(n, measured, 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
plot(n, filtered5, 'r', 'LineWidth', 1.5);
hold off;

grid on;
xlabel('Sample index n');
ylabel('Amplitude');
title('Clean, Noisy, and 5-Point Filtered Signals');
legend('Clean signal', 'Noisy signal', 'Five-point filtered signal');

% Сохранение графика в файл
saveas(gcf, 'noise_filtering.png');


%% Task 4: Compare Two Filter Lengths

% Импульсная характеристика и фильтрация 15-точечным фильтром
h15 = ones(1, 15) / 15;
filtered15 = conv(measured, h15, 'same');

% Построение всех сигналов на одном графике
figure;
plot(n, clean, 'b-', 'LineWidth', 2);                     % Чистый сигнал
hold on;
plot(n, measured, 'Color', [0.75 0.75 0.75], 'LineWidth', 1); % Исходный зашумленный сигнал
plot(n, filtered5, 'r--', 'LineWidth', 1.5);             % Фильтр с длиной 5
plot(n, filtered15, 'k-.', 'LineWidth', 1.8);            % Фильтр с длиной 15
hold off;

grid on;
xlabel('Sample index n');
ylabel('Amplitude');
title('Comparison of 5-Point and 15-Point Moving-Average Filters');
legend('Clean signal', 'Noisy signal', '5-point filtered signal', '15-point filtered signal', ...
       'Location', 'best');

% Сохранение изображения
saveas(gcf, 'filter_comparison.png');