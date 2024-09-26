% create the body AOI based on all frames of all videos of one dyad.

clearvars

dir_out = '/home/emba/Documents/PESI/matAOI/body';
dir_in  = '/home/emba/Documents/PESI/taskPESI/Stimuli';
pic_sz  = [576, 768];
if ~exist(dir_out, 'dir')
    mkdir(dir_out);
end
ls_dirs = dir([dir_in filesep 'PESI_D*']);

for k = 1:length(ls_dirs)

    img = zeros(pic_sz(1),pic_sz(2),3,'uint8');

    if ls_dirs(k).isdir

        ls_files = dir([ls_dirs(k).folder filesep ls_dirs(k).name filesep '*.jpg']);
        
        for i = 1:300
            stm = imread([ls_files(i).folder filesep ls_files(i).name]);
            img = img + stm;
        end

        imwrite(rgb2gray(img), [dir_out filesep ls_dirs(k).name '.jpg'])

    end

end

% combine the dyads
ls_files = dir([dir_out filesep '*000*.jpg']);

for i = 1:length(ls_files)
    if i ~= 1
        if ~strcmp(ls_files(i).name(1:8),ls_files(i-1).name(1:8))
            img = rgb2gray(img);
            img(img > 0) = 255;
            img = imresize(img, 1/4, 'bilinear');
            img(img > 0) = 255;
            img = imresize(img, 4, 'bilinear');
            img(img > 0) = 255;
            imwrite(img, [dir_out filesep ls_files(i-1).name(1:8) '.jpg'])
            img = zeros(pic_sz(1),pic_sz(2),3,'uint8');
        end
    else
        img = zeros(pic_sz(1),pic_sz(2),3,'uint8');
    end
    img = img + imread([ls_files(i).folder filesep ls_files(i).name]);
end
img = rgb2gray(img);
img(img > 0) = 255;
img = imresize(img, 1/4, 'bilinear');
img(img > 0) = 255;
img = imresize(img, 4, 'bilinear');
img(img > 0) = 255;
imwrite(img, [dir_out filesep ls_files(end).name(1:8) '.jpg'])

% read in and save as csv
dir_out = '/media/emba/emba-2/PESI/matAOI/body';
ls_files = dir([dir_out filesep '*body.jpg']);
dir_out = '/media/emba/emba-2/PESI/PESI_scripts/AOIs';
% do this later to save RAM!
% scr_sz  = [1080,1920]; % size of the output screen
% % pictures were moved up by 200 pixel, so that irrelevant part of stimulus 
% % was cut off
% over   = pic_sz(1) - scr_sz(1)/2 + 200;
% % real size of the image presented to the participants
% pic_rl = [2*pic_sz(1)-over, 2*pic_sz(2)];
for i = 1:length(ls_files)
    % mtx  = zeros(scr_sz(1),scr_sz(2),'uint8'); % size of the output screen
    img = imread([ls_files(i).folder filesep ls_files(i).name]);
    % img = imresize(img, 2, 'bilinear');
    img(img < 50)  = 0;
    img(img >= 50) = 255;
    % % add img to the "empty screen"
    % mtx(1:pic_rl(1),...
    %     (size(mtx,2)/2 - pic_rl(2)/2):(size(mtx,2)/2 + pic_rl(2)/2 -1)) = ...
    %     img((over+1):end,:);
    % writematrix(mtx, [dir_out filesep ls_files(i).name(1:end-3) 'csv']);
    writematrix(img, [dir_out filesep ls_files(i).name(1:end-3) 'csv']);
end

% perform some checks
dir_out = '/home/emba/Documents/PESI/matAOI/body';
ls_dirs = dir([dir_in filesep 'PESI_D*']);
dyad = '';
for k = 1:length(ls_dirs)

    if ls_dirs(k).isdir

        if ~strcmp(dyad, ls_dirs(k).name(1:8))
            dyad = ls_dirs(k).name(1:8);
            fl_dyad = dir([dir_out filesep dyad '_body.jpg']);
            mask = imread([fl_dyad.folder filesep fl_dyad.name]);
        end

        ls_files = dir([ls_dirs(k).folder filesep ls_dirs(k).name filesep '*.jpg']);
        
        for i = [1:50:300 300]
            img = imread([ls_files(i).folder filesep ls_files(i).name]);
            img = img + mask*0.5;
            imwrite(img, [dir_out filesep 'checkAOIs' filesep ls_files(i).name '_check.jpg'])
        end

    end

end