function S = edit_nerve_gui(fig,S,regularization_drag)
% Helping gui for editing a new nerve in a drawing window when using 
% nerve_tracking_gui.

k = 1/5; % a parameter determining the fraction of snake points which moves when one point is dragged
i = []; % point currently being dragged
S0 = []; % snake before each drag
N = size(S,1);
support_size = round(k*N/2); % one_sided spacial support for drag
support_weight = linspace(0,1,support_size+1);
support_weight = [support_weight,support_weight(end-1:-1:1)];
w = [];
B = regularization_matrix(N,regularization_drag(1),regularization_drag(2)); % regularization after each drag

set(fig,'WindowButtonDownFcn',@button_down_correct);
s = line('XData',S([1:end,1],1),'YData',S([1:end,1],2),'Color',[1 0 0],'LineStyle','-','Marker','none','LineWidth',2);
p = line('XData',[],'YData',[],'Color',[1 0 0],'LineStyle','none','Marker','o','LineWidth',2);
t = title('Editing. Click and drag. Right or double click when done.');
uiwait(fig) % waits with assigning output until a figure is closed

    function button_down_correct(object,~)
        if strcmp(get(object, 'selectionType'), 'normal') % left-click
            cp = get(gca,'CurrentPoint');
            d = sum((S-cp(1,1:2)).^2,2);
            md = min(d);
            if md<100 % one needs to click less then 100^0.5 = 10 px from snake
                i = find(d==md); % index of snake point being dragged
                S0 = S; % snake before each drag
                w = zeros(N,1);
                w(mod((i-support_size:i+support_size)-1,N)+1) = support_weight;
                set(p,'XData',S0(i,1),'YData',S0(i,2));
                set(fig,'WindowButtonMotionFcn',@button_motion_correct,'WindowButtonUpFcn',@button_up_correct)
            end
        else % right or double click
            set(s,'XData',[],'YData',[])
            set(p,'XData',[],'YData',[])
            set(fig,'WindowButtonDownFcn',[])
            set(t,'String','')
            uiresume(fig)
        end
    end

    function button_motion_correct(~,~)
        cp = get(gca,'CurrentPoint');
        P = cp(1,1:2);
        S = S0 + w*(P-S0(i,:));
        set(p,'XData',P(1),'YData',P(2));
        set(s,'XData',S([1:end,1],1),'YData',S([1:end,1],2))
        drawnow
    end

    function button_up_correct(~,~)
        set(fig,'WindowButtonMotionFcn',[],'WindowButtonUpFcn',[])
        SR = B*S; % regularized snake
        w = zeros(N,1);
        w(mod((i-support_size:i+support_size)-1,N)+1) = 1;
        w(mod([i-2*support_size:i-support_size,...
            i+support_size+1:i+2*support_size]-1,N)+1) = support_weight;
        S = (1-w).*S+w.*SR;
        S = distribute_points(S,'number',N);
        set(p,'XData',[],'YData',[])
        set(s,'XData',S([1:end,1],1),'YData',S([1:end,1],2))
        drawnow
    end
end