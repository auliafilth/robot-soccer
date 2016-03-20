function varargout = main(varargin)
% MAIN MATLAB code for main.fig
%      MAIN, by itself, creates a new MAIN or raises the existing
%      singleton*.
%
%      H = MAIN returns the handle to a new MAIN or the handle to
%      the existing singleton*.
%
%      MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN.M with the given input arguments.
%
%      MAIN('Property','Value',...) creates a new MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help main

% Last Modified by GUIDE v2.5 15-Mar-2016 22:18:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main_OpeningFcn, ...
                   'gui_OutputFcn',  @main_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before main is made visible.
function main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main (see VARARGIN)

% Clear globals
global ball
ball = [];
global bot
bot = [];

global view_resp
view_resp = false;

% Choose default command line output for main
handles.output = hObject;

set(gcf,'toolbar','figure');

% Setup Position Plot
handles.plot_position = plot(handles.fig_position,0,0);
hold(handles.fig_position,'on');
handles.plot_ball_vision = plot(handles.fig_position,0,0,'ro');
handles.plot_ball_estimate = plot(handles.fig_position,0,0,'gx');
handles.plot_bot_vision = plot(handles.fig_position,0,0,'k*');
set(handles.fig_position,'XLim',[-2 2],'YLim',[-1.6 1.6]);
daspect(handles.fig_position, [1 1 1]);
xlabel(handles.fig_position, 'width (meters)');
ylabel(handles.fig_position, 'height (meters)');
set(handles.fig_position, 'XGrid', 'on', 'YGrid', 'on');
set(handles.fig_position, 'ButtonDownFcn', @fig_position_ButtonDownFcn);

% Setup Velocity Plot
handles.plot_velocity = quiver(handles.fig_velocity,0,0,0,0,0);
set(handles.fig_velocity,'XLim',[-1.5 1.5],'YLim',[-1.5 1.5]);
daspect(handles.fig_velocity, [1 1 1]);
xlabel(handles.fig_velocity,'x (m/s)');
ylabel(handles.fig_velocity,'y (m/s)');
set(handles.fig_velocity, 'XGrid', 'on', 'YGrid', 'on');

% Setup Tables
set(handles.table_desired_position,'Data', {0 0 0});
set(handles.table_velocity,'Data', {0 0 0});
set(handles.table_position,'Data', {0 0 0});
set(handles.table_error,'Data', {0 0 0});
set(handles.table_ball_vision,'Data', {0 0 0});
set(handles.table_ball_estimate,'Data', {0 0 0});

% Setup ROS Subscribers
handles.sub.vision_robot_position = rossubscriber('/ally1/ally1_state', 'playground/RobotState', {@robotStateCallback,handles});
handles.sub.desired_position = rossubscriber('/ally1/desired_position', 'geometry_msgs/Pose2D', {@desiredPositionCallback,handles});
handles.sub.vel_cmds = rossubscriber('/ally1/vel_cmds', 'geometry_msgs/Twist', {@velCmdsCallback,handles});
handles.sub.error = rossubscriber('/ally1/pidinfo', 'playground/PIDInfo', {@pidInfoCB,handles});
handles.sub.ball_state = rossubscriber('/ally1/ball_state', 'playground/BallState', {@ballStateCallback,handles});

% And Publishers
handles.pub.desired_position = rospublisher('/ally1/desired_position', 'geometry_msgs/Pose2D', 'IsLatching', false);

% Setup Service Calls
handles.srv.get_battery = rossvcclient('/motion/main_battery');

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clear handles.sub
clear handles.pub

% The GUI is no longer waiting, just close it
delete(hObject);

function robotStateCallback(src, msg, handles)

    if ~ishandle(handles.plot_position) || ~ishandle(handles.plot_position)
        return
    end
    
    % Save for when we are clicking to drive
    global pos
    pos = [msg.Xhat msg.Yhat msg.Thetahat];
    
    global bot
    bot = [bot msg];

    x = get(handles.plot_position,'XData');
    y = get(handles.plot_position,'YData');
    x = [x msg.Xhat];
    y = [y msg.Yhat];
    set(handles.plot_position,'XData',x,'YData',y);
    
    set(handles.fig_position, 'ButtonDownFcn', @fig_position_ButtonDownFcn);

    set(handles.table_position,'Data', {msg.Xhat msg.Yhat msg.Thetahat});
    
%     % Predicted (red X)
%     set(handles.plot_ball_estimate,'XData', msg.XhatFuture, 'YData', msg.YhatFuture);
%     set(handles.table_ball_estimate,'Data', {msg.XhatFuture msg.YhatFuture});
    
    % Estimated (black asterisk)
    if msg.Correction
        set(handles.plot_bot_vision,'XData', msg.VisionX, 'YData', msg.VisionY);
    end
    
function desiredPositionCallback(src, msg, handles)
    if ~ishandle(handles.table_desired_position)
        return
    end

    set(handles.table_desired_position,'Data', {msg.X msg.Y msg.Theta});

function velCmdsCallback(src, msg, handles)
    if ~ishandle(handles.plot_velocity) || ~ishandle(handles.table_velocity)
        return
    end

    vx = msg.Linear.X;
    vy = msg.Linear.Y;
    w  = msg.Angular.Z;

    set(handles.plot_velocity,'XData',0,'YData',0,'UData',vx,'VData',vy);

    set(handles.table_velocity,'Data', {vx vy w});
    
function pidInfoCB(src, msg, handles)
    global view_resp
    global view_resp_start
    
    persistent step_resp_plot
    
    if ~ishandle(handles.table_error) %|| isempty(step_resp_plot) || ~ishandle(step_resp_plot(1,1))
        return
    end

    set(handles.table_error,'Data', {msg.Error.X msg.Error.Y msg.Error.Theta});
    
    % Select the plots to subplot (if you want theta, add it)
    labelYs = {'x-position (m)', 'y-position (m)', 'theta (deg)'};
%     labelYs = {'x-position (m)', 'y-position (m)'};

    % How many subplots should there be?
    N = length(labelYs);
    
    if view_resp
        
        desired = [msg.Desired.X msg.Desired.Y msg.Desired.Theta];
        actual = [msg.Actual.X msg.Actual.Y msg.Actual.Theta];
        
        if view_resp_start
            view_resp_start = false;
            
            % clear the figure
            figure(2);
            clf;
            
            % Initialize handles
            step_resp_plot = zeros(2,N);
            ax = zeros(1,N);
            
            % Setup the subplots
            for i = 1:N
                ax(i) = subplot(N,1,i);
                step_resp_plot(1,i) = plot(0,desired(i));
                hold on;
                step_resp_plot(2,i) = plot(0,actual(i));
                ylabel(labelYs(i));
                xlabel('samples (n)');
                if i == 1
                    title('Step Response');
                end
            end
            
            % Make the zoom linked in the x-direction
%             linkaxes(ax(:), 'x');
        else
            for i = 1:N
                % Update the YData vector for actual
                ydat = [get(step_resp_plot(2,i),'YData') actual(i)];
                t = (0:(length(ydat)-1));
                set(step_resp_plot(2,i),'XData',t,'YData',ydat);

                % Update the YData vector for desired
                ydat = [get(step_resp_plot(1,i),'YData') desired(i)];
                t = (0:(length(ydat)-1));
                set(step_resp_plot(1,i),'XData',t,'YData',ydat);
            end
        end
        
        
    end
    
function ballStateCallback(src, msg, handles)
    if ~ishandle(handles.table_ball_estimate) ...
            ||  ~ishandle(handles.table_ball_vision)
        return
    end
    
    % For grabbing ball data to analyze later
    global ball
    ball = [ball msg];

    % Predicted (red X)
    set(handles.plot_ball_estimate,'XData', msg.XhatFuture, 'YData', msg.YhatFuture);
    set(handles.table_ball_estimate,'Data', {msg.XhatFuture msg.YhatFuture});
    
    % Estimated (green circle)
    set(handles.plot_ball_vision,'XData', msg.Xhat, 'YData', msg.Yhat);
    set(handles.table_ball_vision,'Data', {msg.Xhat msg.Yhat});
    
    % Plot vision measured?
    % You'd have to use the bool 'Correction' to know if you should plot it
    % or not, as these come in faster than the camera. basically, if you
    % just straight plot these measurements it will jump between its
    % position and 0
    


% --- Executes on button press in btn_clear_position.
function btn_clear_position_Callback(hObject, eventdata, handles)
% hObject    handle to btn_clear_position (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.plot_position,'XData',0,'YData',0)


% --- Executes on button press in btn_set_desired_position.
function btn_set_desired_position_Callback(hObject, eventdata, handles)
% hObject    handle to btn_set_desired_position (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
c = get(handles.table_desired_position,'Data');
desired = cell2mat(c);

msg = rosmessage(handles.pub.desired_position);
msg.X = desired(1);
msg.Y = desired(2);
msg.Theta = desired(3);
send(handles.pub.desired_position, msg);


% --- Executes on button press in chk_point_move.
function chk_point_move_Callback(hObject, eventdata, handles)
% hObject    handle to chk_point_move (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chk_point_move


% --- Executes on mouse press over axes background.
function fig_position_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to fig_position (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    handles = guidata(hObject);
    
    if get(handles.chk_point_move,'Value') == 1
        % Get the x,y point of the click
        point = eventdata.IntersectionPoint(1:2);
        
        % Create the first point of the line
        h1 = line('XData',point(1),'YData',point(2));
        set(h1,'Color','r');
        
        hObject.Parent.Parent.WindowButtonMotionFcn = {@winBtnMotionCB,h1,point};
        hObject.Parent.Parent.WindowButtonUpFcn = {@winBtnUpCB,h1};
    end

function winBtnMotionCB(hObject, eventdata, h1, p_init)

    % Get the x,y point that the mouse is hovering over.
    point = hObject.CurrentAxes.CurrentPoint(1,1:2);
    
    % Create a new line
    xdat = [p_init(1) point(1)];
    ydat = [p_init(2) point(2)];
    
    set(h1,'XData',xdat,'YData',ydat);
    
function winBtnUpCB(hObject, eventdata, h1)
    global pos;
    
    handles = guidata(hObject);

    % Clear the callbacks
    hObject.WindowButtonMotionFcn = '';
    hObject.WindowButtonUpFcn = '';

    % Get the line so we can calc angle
    xdat = get(h1,'XData');
    ydat = get(h1,'YData');

    if length(xdat) == 2

        theta = atan2(diff(ydat),diff(xdat));

        % Take care of the fact that atan2 returns [-pi, pi]
        if theta < 0
            theta = theta + 2*pi;
        end

        % Convert to degrees
        theta = theta*180/pi;
        
    else
        theta = pos(2);

    end

    delete(h1);
    
    % The set point is always the first place there was a click
    point = [xdat(1) ydat(1)];
        
    set(handles.table_desired_position,'Data', {0 0 0});

    msg = rosmessage(handles.pub.desired_position);
    msg.X = point(1);
    msg.Y = point(2);
    msg.Theta = theta;
    send(handles.pub.desired_position, msg);


% --- Executes on button press in chk_node_controller.
function chk_node_controller_Callback(hObject, eventdata, handles)
% hObject    handle to chk_node_controller (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles = guidata(hObject);
    if get(handles.chk_node_controller,'Value') == 1
        disp('Not implemented... Oops.');
    end


% --- Executes on button press in btn_update_status.
function btn_update_status_Callback(hObject, eventdata, handles)
% hObject    handle to btn_update_status (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles = guidata(hObject);
    
    req = rosmessage(handles.srv.get_battery);
    resp = call(handles.srv.get_battery,req,'Timeout',1);
    
    set(handles.lbl_battery,'String',[resp.Message 'v']);
    


% --- Executes on button press in btn_stop_moving.
function btn_stop_moving_Callback(hObject, eventdata, handles)
% hObject    handle to btn_stop_moving (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    c = get(handles.table_position,'Data');
    desired = cell2mat(c);

    msg = rosmessage(handles.pub.desired_position);
    msg.X = desired(1);
    msg.Y = desired(2);
    msg.Theta = desired(3);
    send(handles.pub.desired_position, msg);


% --- Executes on button press in btn_step_resp.
function btn_step_resp_Callback(hObject, eventdata, handles)
% hObject    handle to btn_step_resp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global view_resp
global view_resp_start

view_resp_start = true;
view_resp = ~view_resp;

disp(view_resp);


% --- Executes on button press in btn_kick.
function btn_kick_Callback(hObject, eventdata, handles)
% hObject    handle to btn_kick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    handles = guidata(hObject);
    
    kick = rossvcclient('/kick');
    req = rosmessage(kick);
    resp = call(kick,req,'Timeout',3);