clear
close all
addpath functions GraphCut

%% a test with matlabs build-in data
load mri
nerve_tracking_gui(squeeze(D(:,:,1,:)), 'regularization_propagation', [0.1,0.5],...
    'range', -15:15, 'nr_points', 180, 'zoom_width', 130)

%% using GUI without loading some previously segmented nerves
input_folder = '../data/EM_mouse_data';
nerve_tracking_gui(input_folder, 'z_multiplier', 60/5.5)

%% and on another data
input_folder = '../data/nerves_part.tiff';
nerve_tracking_gui(input_folder)

%% using some other options
nerve_tracking_gui(input_folder, 'zoom_width', 30, 'nr_points', 60)

%% and with previously saved outlines
load('mouse_NERVES_XY.mat') % loading previously saved results
input_folder = '../data/EM_mouse_data';
nerve_tracking_gui(input_folder, 'tracks', XY, 'z_multiplier', 60/5.5)

%% exporting as obj files                                                            
mkdir('meshes')
zskip = 60/5.5; % voxels are not square for EM_mouse 
export_mesh(XY, 'meshes/nerve_', 'quad', jet(size(XY,2)), 60/5.5)


