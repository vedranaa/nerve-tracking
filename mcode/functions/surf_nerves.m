function m = surf_nerves(dim,X,Y,z_multiplier)
% Helping function for drawing 3D visualization of nerves for  
% nerve_tracking_gui.

hold on
Z = (1:size(X,3))*z_multiplier;
dim(3) = dim(3)*z_multiplier;

plot3(dim(1)*[0 1 1 0 0;0 1 1 0 0;0 0 0 0 0;1 1 1 1 1]',...
    dim(2)*[0 0 0 0 0;1 1 1 1 1;0 1 1 0 0;0 1 1 0 0]',...
    dim(3)*[0 0 1 1 0;0 0 1 1 0;0 0 1 1 0;0 0 1 1 0]','k-')
view(97.5,15), axis equal vis3d off
lightangle(-65,25);
lightangle(90,20);

Zf = repmat(Z,[size(X,1)+1,1]);

nr_nerves = size(X,2);
colors = lines(nr_nerves);
for n = 1:nr_nerves
    m = surf(squeeze(X([1:end,1],n,:)),squeeze(Y([1:end,1],n,:)),Zf);
    set(m,'EdgeColor','none','FaceColor',colors(n,:),'FaceLighting','gouraud')
    m.AmbientStrength = 0.3;
    m.DiffuseStrength = 0.8;
    m.SpecularStrength = 0.9;
    m.SpecularExponent = 25;
    m.BackFaceLighting = 'unlit';
end
