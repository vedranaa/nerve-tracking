function [X,Y] = fix_snake_twisting(X,Y)
% Shifts points along snake curves to prevent twisting of the mesh faces 
% arond the nerve. Function written to work on all nerves

for n = 1:size(X,2) % for each nerve
    Xn = squeeze(X(:,n,:)); % Xn is nr_points-by-nr_slices
    Yn = squeeze(Y(:,n,:)); 
    for s = 1:size(Xn,2)-1
        before = [Xn(:,s),Yn(:,s)];
        after = [Xn(:,s+1),Yn(:,s+1)];
        [U,~,V] = svd((before-mean(before))'*(after-mean(after)));
        R = V*U';
        shift = round(acos(R(1))/(2*pi)*size(Xn,1));
        Xn(:,s+1:end) = circshift(Xn(:,s+1:end),shift);
        Yn(:,s+1:end) = circshift(Yn(:,s+1:end),shift);
    end
    X(:,n,:) = Xn;
    Y(:,n,:) = Yn;
end
