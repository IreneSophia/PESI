% script to create jpgs based on the AOIs to be able to check whether the
% AOIs are placed correctly. Needs as input the Stimuli as well as the csvs
% containing the AOI placement per frame. 

clearvars
addpath('/home/emba/Documents/MATLAB/export_fig');

% path to Deep Lab Cut output csvs
dir_matAOI = '/media/emba/emba-2/PESI/AOIs/';

% path to stimuli
dir_in  = '/media/emba/emba-2/PESI/Stimuli/';

% where to save the pics
dir_out = [dir_matAOI filesep 'checkAOIs'];
if ~exist(dir_out, 'dir')
    mkdir(dir_out);
end

% get a list of all stimuli
vids = dir([dir_matAOI filesep 'PESI*0.csv']);

% set size of AOIs
r = 60;
s = 2/3;
theta = 0 : (2 * pi / 10000) : (2 * pi);

% number of local cores
cores = 32;

% request cores
local = parcluster('local'); local.NumWorkers = cores;

% start parallel pool
pool = parpool(local, local.NumWorkers);
maxNumWorkers = cores;

parfor (k = 1:length(vids), maxNumWorkers) %

    vid_name = vids(k).name(1:end-4);    
    disp(vid_name)

    dir_vid = [dir_in filesep vid_name];
    fl_tbl  = dir([dir_matAOI filesep vids(k).name]);
    tbl     = readtable([fl_tbl.folder filesep fl_tbl.name]);
    ls_files = dir([dir_vid filesep '*.jpg']);
    
    for i = [1, 50, 100, 150, 200, 250, 300]%
        % disp(i)
        PICpng = imread([ls_files(i).folder filesep ls_files(i).name]);
        imshow(PICpng);  
        hold on;
        % face left
        pline_x = r * cos(theta) + tbl.indiv1_midFace_x(i);
        pline_y = r * sin(theta) + tbl.indiv1_midFace_y(i);
        plot(pline_x, pline_y, 'r', 'LineWidth', 3);
        text(50,30,...
            sprintf('x %.0f y %.0f', tbl.indiv1_midFace_x(i),tbl.indiv1_midFace_y(i)),...
            'Color','r');
        % face right
        pline_x = r * cos(theta) + tbl.indiv2_midFace_x(i);
        pline_y = r * sin(theta) + tbl.indiv2_midFace_y(i);
        plot(pline_x, pline_y, 'b', 'LineWidth', 3);
        text(150,30,...
            sprintf('x %.0f y %.0f', tbl.indiv2_midFace_x(i),tbl.indiv2_midFace_y(i)),...
            'Color','b');
        % hands indiv1
        if ~iscell(tbl.indiv1_HandL_x) && ~iscell(tbl.indiv1_HandL_y)
            pline_x = r * s * cos(theta) + tbl.indiv1_HandL_x(i);
            pline_y = r * s * sin(theta) + tbl.indiv1_HandL_y(i);
            plot(pline_x, pline_y, 'g', 'LineWidth', 3);
            text(250,30,...
                sprintf('L: x %.0f y %.0f', tbl.indiv1_HandL_x(i),tbl.indiv1_HandL_y(i)),...
                'Color','g');
        end
        if ~iscell(tbl.indiv1_HandR_x) && ~iscell(tbl.indiv1_HandR_y)
            pline_x = r * s * cos(theta) + tbl.indiv1_HandR_x(i);
            pline_y = r * s * sin(theta) + tbl.indiv1_HandR_y(i);
            plot(pline_x, pline_y, 'y', 'LineWidth', 3);
            text(350,30,...
                sprintf('R: x %.0f y %.0f', tbl.indiv1_HandR_x(i),tbl.indiv1_HandR_y(i)),...
                'Color','y');
        end
        % hands indiv2
        if ~iscell(tbl.indiv2_HandL_x) && ~iscell(tbl.indiv2_HandL_y)
            pline_x = r * s * cos(theta) + tbl.indiv2_HandL_x(i);
            pline_y = r * s * sin(theta) + tbl.indiv2_HandL_y(i);
            plot(pline_x, pline_y, 'm', 'LineWidth', 3);
            text(450,30,...
                sprintf('L: x %.0f y %.0f', tbl.indiv2_HandL_x(i),tbl.indiv2_HandL_y(i)),...
                'Color','m');
        end
        if ~iscell(tbl.indiv2_HandR_x) && ~iscell(tbl.indiv2_HandR_y)
            pline_x = r * s * cos(theta) + tbl.indiv2_HandR_x(i);
            pline_y = r * s * sin(theta) + tbl.indiv2_HandR_y(i);
            plot(pline_x, pline_y, 'c', 'LineWidth', 3);
            text(550, 30,...
                sprintf('R: x %.0f y %.0f', tbl.indiv2_HandR_x(i),tbl.indiv2_HandR_y(i)),...
                'Color','c');
        end
        % add grid lines
        yline(50:100:800,'--w');
        yline(0:100:800,'w');
        xline(50:100:800,'-.w');
        xline(0:100:800,'w');
        hold off;
        export_fig(sprintf('%s%s%s_AOI_%03d.jpg', ...
            dir_out, filesep, vid_name, i-1));
        close all
    end

end

pool.delete()