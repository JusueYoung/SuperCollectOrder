clear;
clc;
[num_data, str_data] = xlsread('TEST1');
price = [];
dry_amount = [];
mentle_amount = [];

head_title = str_data(1, :);
sheet = str_data;
sheet(2:end, 2) = num2cell(num_data(:, 1));
sheet(2:end, 4:end) = num2cell(num_data(:, 3:end));


for i = 1:size(head_title,2)
    elem = head_title(i);
    if strcmp(char(elem),'钴金属量')
        mentle_amount = num_data(:, i-1);
    elseif strcmp(char(elem),'MB价格')
        price = num_data(:, i-1);
    elseif strcmp(char(elem),'干重吨')
        dry_amount = num_data(:, i-1);
    else
    end
end

ratio = 2.20462 * [0.5, 0.48, 0.46, 0.44, 0.42, 0.40, 0.38, 0]';
solub = [0.07995, 0.06995, 0.05995, 0.04995, 0.03995, 0.02995, 0.01995, 0]';

C = mentle_amount .* price * ratio';
[n, m] = size(C);
M = mentle_amount * ones(1, m) - dry_amount * solub';

%% Establish Optimal Problem
% =========================== optimal variable =========================== %
X = binvar(n, m, 'full');
% =========================== objective func ============================= %
z = -sum(sum(C .* X));
% =========================== constrains ================================= %
ST = [];
for i = 1:n
    s = sum(X(i,:));
    ST = [ST, s  == 1];
end

for j = 1:m
    s = X(:,j)' * M(:, j);
    ST = [ST, s >= 0];
end

%% Solve Problem
ops = sdpsettings('solver', 'INTLINPROG', 'verbose',1);
ops.intlinprog.MaxTime = 1000;
ops.intlinprog.IntegerTolerance = 1e-3;
result  = optimize(ST, z, ops);
if result.problem == 0
    value(X)
    value(z)
else
    disp('solve error');
end

%% Write Result to File
T = value(X);
[~, group] = max(T,[],2);
wirte_sheet = sheet(1, :);
for i = 1: m
    index = find(group == i);
    empty_line = cell(1,size(head_title,2));
    if ~isempty(index)
        group_sheet = sheet(index+1, :);
        wirte_sheet = [wirte_sheet; group_sheet];
    end
    wirte_sheet = [wirte_sheet; empty_line];
end

xlswrite('./TCC1.xlsx',wirte_sheet);

