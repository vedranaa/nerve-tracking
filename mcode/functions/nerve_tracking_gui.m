function nerve_tracking_gui(data,varargin)
%NERVE_TRACKING_GUI   GUI for tracking nerves in volumetric data.
%   Check https://github.com/vedranaa/NerveTracking for suggested workflow.
%   NERVE_TRACKING_GUI(DATA)
%   NERVE_TRACKING_GUI(DATA,Name,Value) sets one or more properties using 
%           name-value pair arguments. Keyboard shortcuts: arrows for 
%           slicing, home and end for first and last slice, add [a], 
%           change nerve [n], edit [e], fit [f], propagate [p], copy [c], 
%           delete [D], save [s], boundry [b]       
%       DATA, volumetric data. This may be a name of a folder containing
%               tif images, a name of the tiff file containing stacked tif
%               stacked images, or a 3D array.
%       Name-Value pairs:
%           'tracks', previously tracked and saved nerves from GUI. This is 
%               an array of size NR_POINTS-by-NR_NERVES-by-NR_SLICES-by_2
%               containing x and y coordinates of the nerve outlines.
%           'nr_points', number of point along each nerve outline, defaults
%               to 90.
%           'z_multiplier', scaling of z axis used only for visualization,
%               defaults to 1.
%           'zoom_width', width of the drawing window, defaults to 100.
%           'regularization_propagation', regularization of the curve when
%               propagating, a vector with two numbers indicating
%               elasticity and rigidity of the curve, defaults to [0.5,1].
%           'regularization_drag', regularization of the curve when
%               dragging during editing, a vector with two numbers
%               indicatinng elasticity and rigidity, defaults to [2,10].
%           'range', a vector defining a normal-direction search range of 
%               the curve when propagating, needs to reflect how much 
%               nerves move between slices, defaults to -10:0.5:10.  
%           
%   Author: vand@dtu.dk, 2019, 2020


% PARSING INPUTS
if any(strcmpi(varargin,'TRACKS'))
    XY = varargin{find(strcmpi(varargin,'TRACKS'))+1};
    X = XY(:,:,:,1);
    Y = XY(:,:,:,2);
else
    X = [];
    Y = [];
end

if isempty(X) && any(strcmpi(varargin,'NR_POINTS'))
    nr_points = varargin{find(strcmpi(varargin,'NR_POINTS'))+1};
else
    nr_points = 90;
end

if any(strcmpi(varargin,'Z_MULTIPLIER'))
    z_multiplier = varargin{find(strcmpi(varargin,'Z_MULTIPLIER'))+1};
else
    z_multiplier = 1;
end

if any(strcmpi(varargin,'ZOOM_WIDTH'))
    margin = ceil(varargin{find(strcmpi(varargin,'ZOOM_WIDTH'))+1}/2);
else
    margin = 50; % marging around nerve position in drawing window
end

if any(strcmpi(varargin,'REGULARIZATION_PROPAGATION'))
    regularization_propagation = varargin{find(strcmpi(varargin,'REGULARIZATION_PROPAGATION'))+1};
else
    regularization_propagation = [0.5,1];
end

if any(strcmpi(varargin,'REGULARIZATION_DRAG'))
    regularization_drag = varargin{find(strcmpi(varargin,'REGULARIZATION_DRAG'))+1};
else
   regularization_drag = [2,10];
end

if any(strcmpi(varargin,'RANGE'))
    range = varargin{find(strcmpi(varargin,'RANGE'))+1};
    range = range(:);
else
   range = (-10:0.5:10)'; % range for surface displacement
end

% figuring out what type of volumetric data is given
if ischar(data) % either collection of tif images in a folder or a tif stack
    if isfolder(data) % folder of tif images
        image_list = dir([data,'/*.tif']);
        nr_slices = length(image_list);
        readslice = @(z) imread([data,'/',image_list(z).name]);
        disp('yep')
    else % a single stacked tif image
        nr_slices = length(imfinfo(data));
        readslice = @(z) imread(data,'Index',z);       
    end
elseif numel(size(data))==3
    nr_slices = size(data,3);
    readslice = @(z) data(:,:,z);
else
    warning('Can''t figure out data format')
end

% SETTING UP
NR_NERVES = size(X,2);

CURRENT_NERVE = [];
boundry_options = {'dark inside', 'any', 'bright inside'};
CURRENT_BOUNDARY_OPTION = 2; % initial boundary option is 'any'
B = regularization_matrix(nr_points,regularization_propagation(1),regularization_propagation(2)); % regularization matrix
title_string = 'Keyboard: add [a], change nerve [n], edit [e], fit [f], propagate [p], copy [c], Delete [D], save [s], boundry [b]';

% SETTING UP THE FIGURES
fig_main = figure('Units','Normalized','Position',[0.0 0.1 0.5 0.8],...
    'KeyPressFcn',@key_press,'Name','Overview window');
fig_edit = figure('Units','Normalized','Position',[0.6 0.5 0.35 0.4],'Name','Drawing window');
fig_surf = figure('Units','Normalized','Position',[0.6 0.1 0.35 0.3],'Name', '3D visulization window');
CURRENT_SLICE = 1; % starting in the first slice
CURRENT_IMAGE = readslice(CURRENT_SLICE);
figure(fig_main)
imagesc(CURRENT_IMAGE), axis image ij, colormap gray, hold on
update_drawing
figure(fig_surf)
update_surf
update_drawing

%%%%%%%%%% CALLBACK FUNCTIONS %%%%%%%%%%
    function key_press(~,object)
        % keyboard commands
        key = object.Key;
        switch key
            case 'uparrow'
                CURRENT_SLICE = min(CURRENT_SLICE+1,nr_slices);
                update_drawing
            case 'downarrow'
                CURRENT_SLICE = max(CURRENT_SLICE-1,1);
                update_drawing
            case 'rightarrow'
                CURRENT_SLICE = min(CURRENT_SLICE+10,nr_slices);
                update_drawing
            case 'leftarrow'
                CURRENT_SLICE = max(CURRENT_SLICE-10,1);
                update_drawing
            case 'pageup'
                CURRENT_SLICE = max(CURRENT_SLICE+50,1);
                update_drawing
            case 'pagedown'
                CURRENT_SLICE = min(CURRENT_SLICE-50,nr_slices);
                update_drawing
            case 'home'
                CURRENT_SLICE = 1;
                update_drawing
            case 'end'
                CURRENT_SLICE = nr_slices;
                update_drawing
            case 'a'
                add_nerve
                update_surf
                update_drawing
            case 'n'
                change_nerve
                update_drawing
            case 'e'
                edit_nerve
                update_surf
                update_drawing
            case 'f'
                fit_nerve
                update_surf
                update_drawing
            case 'p'
                propagate_nerve
                update_surf
                update_drawing
            case 'c'
                copy_nerve
                update_surf
                update_drawing
            case 'd'
                if strcmp(object.Modifier,'shift') % only capital letters
                    delete_nerve
                    update_surf
                    update_drawing
                end
            case 'b'
                CURRENT_BOUNDARY_OPTION = mod(CURRENT_BOUNDARY_OPTION,3)+1;
                disp(['Boundary changed to ',boundry_options{CURRENT_BOUNDARY_OPTION}]);
                title({title_string,['Slice ',num2str(CURRENT_SLICE),', nerve ',num2str(CURRENT_NERVE),', boundry ',boundry_options{CURRENT_BOUNDARY_OPTION}],' '})
            case 's'
                xlabel('Saving.')
                drawnow
                [X,Y] = fix_snake_twisting(X,Y);
                XY = cat(4,X,Y);
                save('NERVES_XY.mat','XY')
                disp('Ok, saved!')
                xlabel('Saved.')
        end
    end

%%%%%%%%%% HELPING FUNCTIONS %%%%%%%%%%
    function update_drawing
        figure(fig_main)
        CURRENT_IMAGE = readslice(CURRENT_SLICE);
        cla, imagesc(CURRENT_IMAGE)
        if ~isempty(X)
            text(mean(Y(:,:,CURRENT_SLICE)),mean(X(:,:,CURRENT_SLICE)),num2str((1:size(X,2))'),...
                'HorizontalAlignment','center','VerticalAlignment','middle',...
                'Color','r')
            plot(Y([1:end,1],:,CURRENT_SLICE),X([1:end,1],:,CURRENT_SLICE),'r')
            plot(Y([1:end,1],CURRENT_NERVE,CURRENT_SLICE),X([1:end,1],CURRENT_NERVE,CURRENT_SLICE),'r','LineWidth',2)
        end
        title({title_string,['Slice ',num2str(CURRENT_SLICE),', nerve ',num2str(CURRENT_NERVE),', boundary ',boundry_options{CURRENT_BOUNDARY_OPTION}],' '})
        drawnow
    end

    function update_surf
        figure(fig_surf), clf
        surf_nerves([size(CURRENT_IMAGE),nr_slices],X,Y,z_multiplier)
        drawnow
    end

    function add_nerve
        xlabel('Adding nerve from the current slice. Click at the nerve to add.')
        drawnow
        [y,x,~] = ginput(1);
        xlabel([])
        xlabel('Adding nerve from the current slice. Use drawing window.')
        figure(fig_edit)
        imagesc(CURRENT_IMAGE), colormap gray, axis image,
        axis([y-margin,y+margin,x-margin,x+margin]), hold on
        S = add_nerve_gui(fig_edit,nr_points);
        if ~isempty(S)
            NR_NERVES = NR_NERVES+1;
            CURRENT_NERVE = NR_NERVES;
            X(:,CURRENT_NERVE,:) = repmat(S(:,2),[1,1,nr_slices]);
            Y(:,CURRENT_NERVE,:) = repmat(S(:,1),[1,1,nr_slices]);
            figure(fig_main)
            xlabel(['Added nerve number ',num2str(CURRENT_NERVE),'.'])
        else
            figure(fig_main)
            xlabel('Something went wrong. Did not add the nerve.')
        end
    end

    function change_nerve
        xlabel('Changing nerve. Click at the nerve to change to.')
        drawnow
        [y,x,~] = ginput(1);
        dist = (y-mean(Y(:,:,CURRENT_SLICE))).^2+(x-mean(X(:,:,CURRENT_SLICE))).^2;
        CURRENT_NERVE = find(dist==min(dist),1);
        xlabel(['Changed current nerve to nerve ',num2str(CURRENT_NERVE),'.'])
    end

    function edit_nerve
        xlabel('Editing current nerve in current slice. Use drawing window.')
        drawnow
        S = [Y(:,CURRENT_NERVE,CURRENT_SLICE),X(:,CURRENT_NERVE,CURRENT_SLICE)];
        y = mean(Y(:,CURRENT_NERVE,CURRENT_SLICE));
        x = mean(X(:,CURRENT_NERVE,CURRENT_SLICE));
        figure(fig_edit)
        imagesc(CURRENT_IMAGE), colormap gray, axis image,
        axis([y-margin,y+margin,x-margin,x+margin]), hold on
        S = edit_nerve_gui(fig_edit,S,regularization_drag);
        X(:,CURRENT_NERVE,CURRENT_SLICE) = S(:,2);
        Y(:,CURRENT_NERVE,CURRENT_SLICE) = S(:,1);
        figure(fig_main)
        xlabel('Edited current nerve in current slice.')
    end

    function delete_nerve
        xlabel('Deleting current nerve in all slices.');
        drawnow
        X(:,CURRENT_NERVE,:) = [];
        Y(:,CURRENT_NERVE,:) = [];
        NR_NERVES = NR_NERVES-1;
        CURRENT_NERVE = [];
        xlabel('Deleted current nerve in all slices.')
    end

    function fit_nerve
        xlabel('Fitting current nerve in current slice.')
        drawnow
        F = griddedInterpolant(double(CURRENT_IMAGE),'linear'); % interpolant in a new image
        S = [X(:,CURRENT_NERVE,CURRENT_SLICE),Y(:,CURRENT_NERVE,CURRENT_SLICE)];
        S = fit_one_nerve(F,S,range,B,boundry_options{CURRENT_BOUNDARY_OPTION});
        X(:,CURRENT_NERVE,CURRENT_SLICE) = S(:,1);
        Y(:,CURRENT_NERVE,CURRENT_SLICE) = S(:,2);
        xlabel('Fitted current nerve in current slice.')
    end

    function propagate_nerve
        xlabel('Propagating current nerve from current slice.')
        drawnow
        direction{1} = CURRENT_SLICE:nr_slices;
        direction{2} = CURRENT_SLICE:-1:1;
        for d = 1%:2
            for k = 2:numel(direction{d})
                I_this = readslice(direction{d}(k));
                F = griddedInterpolant(double(I_this),'linear');
                S = [X(:,CURRENT_NERVE,direction{d}(k-1)),Y(:,CURRENT_NERVE,direction{d}(k-1))];
                S = fit_one_nerve(F,S,range,B,boundry_options{CURRENT_BOUNDARY_OPTION});
                X(:,CURRENT_NERVE,direction{d}(k)) = S(:,1);
                Y(:,CURRENT_NERVE,direction{d}(k)) = S(:,2);
            end
        end
        xlabel('Propagated current nerve from current slice.')
    end

    function copy_nerve
        xlabel('Copying current nerve from current slice.')
        drawnow
        X(:,CURRENT_NERVE,CURRENT_SLICE:end) = repmat(X(:,CURRENT_NERVE,CURRENT_SLICE),[1 1 nr_slices-CURRENT_SLICE+1]);
        Y(:,CURRENT_NERVE,CURRENT_SLICE:end) = repmat(Y(:,CURRENT_NERVE,CURRENT_SLICE),[1 1 nr_slices-CURRENT_SLICE+1]);
        xlabel('Copyed current nerve from current slice.')
    end
end


