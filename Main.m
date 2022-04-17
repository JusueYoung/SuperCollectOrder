% Super Collect Orders
% ===========================================================================
% Version: 2.0
% Author: ZhuXiang
% Date: April 2, 2022
% ===========================================================================
clc; clear; close all;
%% Load data
filename = 'JanTest.csv';
raw_data = importdata(filename);
% =========================== process to param =========================== %
mentle_amount = raw_data.data(:,1);
price = raw_data.data(:,2);
dry_amount = str2num(char(raw_data.textdata(:,6)));
goods_id = raw_data.textdata(:,1);
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
file_column = size(raw_data.data,2) + size(raw_data.textdata,2);
read_sheet = [raw_data.textdata, num2cell(raw_data.data)];
wirte_sheet = [];
for i = 1: m
    index = find(group == i);
    empty_line = cell(1,file_column);
    if ~isempty(index)
        group_sheet = read_sheet(index, :);
        wirte_sheet = [wirte_sheet; group_sheet];
    end
    wirte_sheet = [wirte_sheet; empty_line];
end

fid = fopen('TCC1.csv','wt');
if fid<0
	errordlg('File creation failed','Error');
end
for i=1:size(wirte_sheet,1)
    fprintf(fid, '%s,%s,%s,%s,%s,%s,%s,%d,%d,%d\n', ...
        wirte_sheet{i,1}, wirte_sheet{i,2}, ...
        wirte_sheet{i,3}, wirte_sheet{i,4}, ...
        wirte_sheet{i,5}, wirte_sheet{i,6}, ...
        wirte_sheet{i,7}, wirte_sheet{i,8}, ...
        wirte_sheet{i,9}, wirte_sheet{i,10});
end
fclose(fid);