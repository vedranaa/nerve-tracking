function s = grid_cut(s_cost, r_cost, delta_xy, wrap_xy, delta_lu)
%GRID_CUT detects terrain-like surfaces in a volumetric data.
%
% Detected surfaces are terrain-like, i.e. height z is a function of the
% position (x,y). Only on-surface costs, only in-region costs or both type
% of costs may be used. When  using in-region costs for multiple surfaces,
% surfaces are non-intersecting and ordered, so that the first surface has
% the smallest z values, and the last surface has the largest z values.
%
% S = GRID_CUT(S_COST,R_COST,DELTA_XY,WRAP_XY,DELTA_LU)
%
% S_COST is a size (X,Y,Z,K) surface cost function. Cost (x,y,z,k) is an
%       inverse to likelihood of a voxel (x,y,z) containing surface k.
%       K is the number of surfaces and Z is up. When using only in-region
%       costs, S_COST should either contain only zeros or be empty.
% R_COST is a size (X,Y,Z,K+1) region cost function. Cost (x,y,z,k) is an
%       inverse to likelihood of a voxel (x,y,z) being in a region between
%       the surface k and k+1, where the first and the last region are
%       boundedend with the volume boundary. When using only on-surface
%       costs, R_COST should either contain only zeros or be empty.
% DELTA_XY is a size (K,2) array of stiffness parameters for x and y. If a
%       size (1,2) array is given, the same stiffness parameteres are used
%       for all surfaces. If size (K,1) array is given, the same stiffness
%       is used for x and y.
% WRAP_XY is a length 2 array of boolean wrap options for x and y. If not
%       given defaults to false.
% DELTA_LU is a size (K-1,2) array of lower and upper surface overlaps, 
%       [dl du]. The constraint is: dl <= surf_k - surf_k+1 <= du. When 
%       using in-region costs, the surfaces are non-intersecting and 
%       ordered which requires dl > 0 and du >= dl. If a size (1,2) array 
%       is given, the  same overlap parameteres are used for all surfaces. 
%       If not given, defaults to "no constraint" (dl=-Z, du=Z) when using 
%       only on-surface costs and to "no overlap" (dl=1, du=Z) otherwise.
% S is a size (X,Y,K) matrix of z coordinates for K segmented surfaces.
%
% Based on:
%  "Optimal surface segmentation in volumetric images-a graph-theoretic
%   approach."  Li, Wu, Chen and Sonka. PAMI 2006.
%  "Incorporation of Regional Information in Optimal 3-D Graph Search with
%   Application for Intraretinal Layer Segmentation of Optical Coherence
%   Tomography Images". Haeker, Wu, Abramoff, Kardon and Sonka. IPMI 2007.
%
% Author: Vedrana Andersen Dahl, vand@dtu.dk, 2013
%
% NOTE: needs Kolmogorovs implementation of the algorithm from
%		"An Experimental Comparison of Min-Cut/Max-Flow Algorithms for
%       Energy Minimization in Vision."
%		Yuri Boykov and Vladimir Kolmogorov. PAMI 2004

% assigning an unique index to each vertex in the first 3D graph (first surface)

if nargin<5
    delta_lu = [];
end
if nargin<4
    wrap_xy = [];
end
[s_cost, r_cost, delta_xy, wrap_xy, delta_lu] = assign_defaults...
    (s_cost, r_cost, delta_xy, wrap_xy, delta_lu);
[X,Y,Z,K] = size(s_cost);
dimension = [X Y Z];
indices = reshape(1:prod(dimension),dimension);
base = indices(:,:,1);
next_surface = prod(dimension); % adding to indices is a shift to next surface
layers = (0:(K-1))*next_surface;

wrap = [wrap_xy 0]; % we do not wrap in z direction

% EDGES WHICH ARE THE SAME FOR ALL SURFACES:
% intracolumn arcs pointing down, Equation (2)
Ea1 = displacement_to_edges(indices, [0 0 -1], wrap); % first surface
Ea = repmat(Ea1,[K 1]) + kron(layers(:),ones(size(Ea1))); % all surfaces
Ea = [Ea,ones(size(Ea,1),1)*[inf,0]]; % assigning [inf 0] weight
% base edges, part of intercolumn arcs, Equation (3)
erxb1 = displacement_to_edges(base, [1 0 0], wrap);
eryb1 = displacement_to_edges(base, [0 1 0], wrap);
Erb1 = [erxb1; eryb1]; % first surface
Erb = repmat(Erb1,[K 1]) + kron(layers(:),ones(size(Erb1))); % all surfaces
% assigning [inf inf] weight, base edges are in both directions
Erb = [Erb,ones(size(Erb,1),1)*[inf,inf]];

% EDGES WHICH DEPEND ON SURFACE STIFFNESS:
% slanted edges, part of intercolumn arcs, Equation (3)
Erpm = []; % preallocation length could be computed from X,Y,Z,delta and wrap
for k = 1:K
    erxp = displacement_to_edges(indices, [1 0 -delta_xy(k,1)], wrap);
    erxm = displacement_to_edges(indices, [-1 0 -delta_xy(k,1)], wrap);
    eryp = displacement_to_edges(indices, [0 1 -delta_xy(k,2)], wrap);
    erym = displacement_to_edges(indices, [0 -1 -delta_xy(k,2)], wrap);
    erpm  = [erxp; erxm; eryp; erym] + layers(k);
    Erpm = [Erpm;erpm];
end
% assigning [inf 0] weight, slanted edges are in one direction
Erpm = [Erpm,ones(size(Erpm,1),1)*[inf,0]];
Er = [Erpm; Erb]; % all inter edges, for all surfaces
E = [Ea;Er]; % all intracolumn and intercolumn edges, for all surfaces

% EDGES WHICH DEPEND ON DISTANCE BETWEEN SURFACES:
% intersurface arc, Equation (4)
if K>1 % only if we have more than 1 surface
    Es = []; % preallocation length could be computed
    for k = 1:K-1
        esl = displacement_to_edges(indices, [0 0 delta_lu(k,1)], wrap);
        esl = esl + ones(size(esl,1),1)*layers([k,k+1]);
        esu = displacement_to_edges(indices, [0 0 -delta_lu(k,2)], wrap);
        esu = esu + ones(size(esu,1),1)*layers([k+1,k]);
        es = [esl;esu];
        Es = [Es;es];
    end
    Es = [Es,ones(size(Es,1),1)*[inf,0]]; % assigning [inf 0] weight
    
    % intersurface base edges
    esb = [layers(1:end-1)',layers(2:end)']+1; %first vertex in all surfaces
    Esb = [esb,ones(K-1,1)*[inf,inf]]; % assigning [inf inf]
    E = [E;Es;Esb]; % all intracolumn, intercolumn and intersurface edges, for all surfaces
end

% EDGES WHICH DEPEND ON SURFACE LIKELIHOOD:
% up to here we do not use s_cost -- consider efficient algorithm if solving
% multiple problems of the same size
% vertex s_cost, Equation (1), done simulatniously for all surfaces
w_on = -1*ones([dimension,K]); % to prevent empty solution, see second half of section 4.1
w_on(:,:,2:end,:) = double(s_cost(:,:,2:end,:))-double(s_cost(:,:,1:end-1,:));
% In case of layered surfaces vertices which can't be realized should be removed, 
% i.e. topmost vertices of lower surface and lowest vertices of higher surface.
% Instead of removing vertices, I assign inf weight to topmost vertices. 
% And this only when delta_lu are both positive (both negative can be 
% avoided by proper ordering of surfaces).
if K>1 % only if we have more than 1 surface
    for k=1:K-1 % assigning inf on-surface weights instead of removing vertices
        if delta_lu(k,1)>0 && delta_lu(k,1)<= delta_lu(k,2) % bit clumsy
            w_on(:,:,end-delta_lu(k,1)+1:end,k) = inf;                        
        end    
    end
end

% In-region cost, converting to double to avoid problems when using images
w_in = double(r_cost(:,:,:,1:end-1))-double(r_cost(:,:,:,2:end));
% There are issues concerning in-region cost e.g. a better way of preventing
% empty solutions or topmost solutions. 
w_in(:,:,1,:) = -inf; % preventing empty solution

w = w_on + w_in;

Vp_ix = find(w(:)>=0); % positive vertices, to be connected to sink
Vm_ix = find(w(:)<0); % negative vertices, to be connected to source
Es = [Vm_ix, -w(Vm_ix), zeros(length(Vm_ix),1)]; % source edges
Et = [Vp_ix, zeros(length(Vp_ix),1), w(Vp_ix)]; % sink edges
Est = [Es;Et]; % all terminal edges

% FINDING GRAPH CUT USING MAGIC
Scut = GraphCutMex(prod(dimension)*K,Est,E);

% retreiving surfaces as the upper envelope of Scut
S = zeros(X,Y,Z,K);
S(Scut) = 1;
s = zeros(X,Y,K);
for ki = 1:K
    for x = 1:X
        for y = 1:Y
            s(x,y,ki) = find(S(x,y,:,ki),1,'last');
        end
    end
end
end

% NOTE: when some of the intersurface edges point upwards, i.e. when
% delta_l is positive, the lowest delta_l rows of a graph for higher
% surface can not appear in any feasible solution and can be removed.
% This has NOT been implemented here.

function edges = displacement_to_edges(indices, disp, wrap)
% indices -- 3D volume of indices
% disp -- length 3 vector of displacements, given as [x y,z]
% wrapping -- length 3 vector of boolean options, given as [wrapx wrapy wrapz]
% edges -- two columns of indices, each line is an edge.

[x_from,x_into] = displace_1D_indices(size(indices,1),disp(1),wrap(1));
[y_from,y_into] = displace_1D_indices(size(indices,2),disp(2),wrap(2));
[z_from,z_into] = displace_1D_indices(size(indices,3),disp(3),wrap(3));

indices_from = indices(x_from,y_from,z_from);
indices_into = indices(x_into,y_into,z_into);

edges = [indices_from(:),indices_into(:)];
end

function [from,into] = displace_1D_indices(dim,disp,wrap)
% dim -- length of the indices vector
% disp -- length of the displacement
% wrap -- boolean, indicating trimming or wrapping

indices = 1:dim;
if wrap
    from = indices([1-min(disp,0):end,1:-min(disp,0)]);
    into = indices([1+max(disp,0):end,1:max(disp,0)]);
else
    from = indices(1-min(disp,0):end-max(disp,0));
    into = indices(1+max(disp,0):end+min(disp,0));
end
end

function [s_cost, r_cost, delta_xy, wrap_xy, delta_lu] = assign_defaults...
    (s_cost, r_cost, delta_xy, wrap_xy, delta_lu)
% either cost_s or cost_r need to be given (not empty and not all zeros)
if isempty(s_cost)
    s_cost = zeros(size(r_cost)-[0,0,0,1]);
end
if isempty(r_cost)
    r_cost = zeros([size(s_cost,1),size(s_cost,2),size(s_cost,3),...
        size(s_cost,4)]+[0,0,0,1]); % to allow s_cost to be 3D
    regional = false;
elseif all(r_cost(:)==0)
    regional = false;
else
    regional = true;
end

[X,Y,Z,K] = size(s_cost);
[Xr,Yr,Zr,Krplus1] = size(r_cost);
if ~X==Xr || ~Y==Yr || ~Z==Zr || ~(K+1)==Krplus1
    error('Error using grid_cut. Dimensions of s_cost and r_cost must agree.')
end

% smoothness constraint may be given once for all surfaces
if size(delta_xy,1)==1
    delta_xy = ones(K,1)*delta_xy;
end
% smoothness constraint may be given once for both directions
if size(delta_xy,2)==1
    delta_xy = delta_xy*ones(1,2);
end

if isempty(wrap_xy) || (numel(wrap_xy)==1 && wrap_xy==0)
    wrap_xy = [0 0];
end

% overlap constraint defaults to no overlap in region case
% and no constraint in surface case
if isempty(delta_lu)
    if regional % no overlap
        delta_lu = [1 Z];
    else % no constraint
        delta_lu = [-Z Z];
    end
end

% overlap constraint may be given once for all surface pairs
if all(size(delta_lu)==[1,2])
    delta_lu = ones(K-1,1)*delta_lu;
end
end