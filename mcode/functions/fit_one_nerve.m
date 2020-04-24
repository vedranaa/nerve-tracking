function S = fit_one_nerve(F,S,range,B,direction)
%F - interpolant
%S - snake
%range - radial range
%B - regularization matrix
%direction - indicates dark to bright or other options

normals = snake_normals(S);
unfolded = F(S(:,1)'+range*normals(:,1)',S(:,2)'+range*normals(:,2)');
unfolded = imfilter(unfolded,[-1;1],'replicate');
if strcmp(direction, 'dark inside')
    unfolded = -unfolded;
elseif strcmp(direction, 'any')
    unfolded = -abs(unfolded);
elseif strcmp(direction, 'bright inside')
else
    warning('Unknown direction option')
end
s_cost = permute(unfolded,[2 3 1]);
s_cost = (s_cost-min(s_cost(:)))/(max(s_cost(:))-min(s_cost(:)));
s = grid_cut(s_cost,[],1,[1,0]); 
S = B*distribute_points(B*(S+interp1(range,s).*normals));

%figure, imagesc(unfolded), hold on, plot(s), figure, 

end