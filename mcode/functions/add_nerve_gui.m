function S = add_nerve_gui(fig,N)
% Helping gui for adding a new nerve in a drawing window when using 
% nerve_tracking_gui.

t = 0:2*pi/N:2*pi*(1-1/N); % radial parameter
cost = cos(t);
sint = sin(t);
C = []; % center point of the snake
r = 0; % radius of the snake
S = []; % snake

set(fig,'WindowButtonDownFcn',@button_down_initialize,'WindowButtonUpFcn',@button_up_initialize);
c = line('XData',[],'YData',[],'Color',[1 0 0],'LineStyle','none','Marker','x','LineWidth',2);
s = line('XData',[],'YData',[],'Color',[1 0 0],'LineStyle','-','Marker','none','LineWidth',2);
t = title('Adding. Click and drag. Right or double click when done.');
uiwait(fig) % waits with assigning output until a figure is closed

    function button_down_initialize(object,~)
        if strcmp(get(object, 'selectionType'), 'normal') % left-click
            cp = get(gca,'CurrentPoint');
            C = cp(1,1:2);
            set(c,'XData',C(1),'YData',C(2))
            drawnow
            set(fig,'WindowButtonMotionFcn',@button_motion_initialize)
        else % right or double click
            set(fig,'WindowButtonDownFcn',[],'WindowButtonUpFcn',[])
            set(c,'XData',[],'YData',[])
            set(s,'XData',[],'YData',[])
            set(t,'String','')
            uiresume(fig)
        end
    end

    function button_motion_initialize(~,~)
        cp = get(gca,'CurrentPoint');
        r = sum((C-cp(1,1:2)).^2).^0.5;
        S = r*[cost(:),sint(:)] + C;
        set(s,'XData',S([1:end,1],1),'YData',S([1:end,1],2))
        drawnow
    end

    function button_up_initialize(~,~)
        set(fig,'WindowButtonMotionFcn',[])
        set(c,'XData',[],'YData',[])
        set(s,'XData',S([1:end,1],1),'YData',S([1:end,1],2))
        drawnow
    end

end