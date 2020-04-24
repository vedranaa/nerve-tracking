function export_mesh(XY,filename,type,colors,z,invert)
%EXPORT_MESH   Exports results of nerve_fitting_gui as a obj meshes
%   EXPORT_MESH(XY,FILENAME,TYPE,COLORS,Z,INVERT)
%
%   XY is an arrays of size NR_POINTS-by-NR_NERVES-by-NR_SLICES-by-2
%   FILENAME, basic filename without extension, resulting filenames will 
%       contain nerve number
%   TYPE, a flag indicating mesh type 'quad' of 'tri'
%   COLORS, optional colors of mesh, a NR_NERVES-by-3 colormap
%   Z, optional height positions, an array with NR_SLICES elements, or a 
%       scalar indicating z multiplier
%   INVERT, boolean flag indicating inversion of face orientations

X = XY(:,:,:,1);
Y = XY(:,:,:,2);

nr_angles = size(X,1);
nr_slices = size(X,3);
nr_nerves = size(X,2);

if nargin<6
    invert = true; % usual option for nerve tracking gui
end

if nargin<5 || isempty(z)
    z = 1:nr_slices;
end
if numel(z)==1
    z = z*(1:nr_slices);
end

if nargin<4
    colors = [];
end

switch type
    case 'quad'
        % making quad face structure
        block = [1 2 nr_angles+2 nr_angles+1];
        line = repmat((0:nr_angles-2)',[1,4]) + repmat(block,[nr_angles-1,1]);
        line(end+1,:) = [nr_angles 1 nr_angles+1 2*nr_angles];
        addon = repmat(0:nr_angles:nr_angles*(nr_slices-2),[numel(line),1]);
        lines = repmat(line',[1,nr_slices-1]);
        faces = reshape(lines(:)+addon(:),4,[]);
        if invert
            faces = flip(faces);
        end
        
    case 'tri'
        % making tri face structure
        if nargin>4 && invert
            block = [1 2 nr_angles+2;
                1 nr_angles+2 nr_angles+1];
            last = [nr_angles 1 nr_angles+1; nr_angles nr_angles+1 2*nr_angles];
        else
            block = [1 nr_angles+2 2;
                1 nr_angles+1 nr_angles+2];
            last = [nr_angles nr_angles+1 1; nr_angles 2*nr_angles nr_angles+1];
        end
        t = repmat((0:nr_angles-2),[2,1]);
        line = repmat(t(:),[1,3]) + repmat(block,[nr_angles-1,1]);
        line(end+1:end+2,:) = last;
        addon = repmat(0:nr_angles:nr_angles*(nr_slices-2),[numel(line),1]);
        lines = repmat(line',[1,nr_slices-1]);
        faces = reshape(lines(:)+addon(:),3,[]);
        
end

Z = repmat(z(:)',[nr_angles,1]);
nopathname = filename(find(filename=='/',1,'last')+1:end);

for n=1:nr_nerves
    vertices = [reshape(X(:,n,:),[],1),reshape(Y(:,n,:),[],1),Z(:)]';
    fid = fopen([filename,num2str(n),'.obj'],'w');
    if ~isempty(colors)
        fprintf(fid,'mtllib %s.mtl\n',nopathname);
        fprintf(fid,'usemtl mtl%d\n',n);
    end
    fprintf(fid,'v %f %f %f\n',vertices);
    fprintf(fid,'f %d %d %d %d\n',faces);
    fclose(fid);
end

if ~isempty(colors)
    % saving mtl file
    fid = fopen([filename,'.mtl'],'w');
    fprintf(fid,'newmtl mtl%d\nKd %f %f %f\n\n',[(1:nr_nerves);colors']);
    fclose(fid);
end
end
