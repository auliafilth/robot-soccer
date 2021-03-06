function h = main_ros_setup( h, ally,...
                        robotStateCB, desPosCB, velCB,...
                        pidInfoCB, ballStateCB)
%MAIN_ROS_SETUP Summary of this function goes here
%   Detailed explanation goes here
      
    % ROS namespace (see launch files to see more)
    ns = ['/ally', num2str(ally)];

   % Setup ROS Subscribers
    h.sub.my_state = rossubscriber(...
                [ns, '/ally', num2str(ally), '_state'],...
                'playground/RobotState', {robotStateCB,h,ally});
            
    h.sub.opp_state = rossubscriber(...
                [ns, '/opponent', num2str(ally), '_state'],...
                'playground/RobotState', {robotStateCB,h,0});
            
    h.sub.desired_position = rossubscriber(...
                [ns, '/desired_position'],...
                'geometry_msgs/Pose2D', {desPosCB,h,ally});
            
    h.sub.vel_cmds = rossubscriber(...
                [ns, '/vel_cmds'],...
                'geometry_msgs/Twist', {velCB,h,ally});
            
    h.sub.pidinfo = rossubscriber(...
                [ns, '/pidinfo'],...
                'playground/PIDInfo', {pidInfoCB,h,ally});
            
    h.sub.ball_state = rossubscriber(...
                [ns, '/ball_state'],...
                'playground/BallState', {ballStateCB,h,ally});

    % And Publishers
    h.pub.desired_position = rospublisher(...
                [ns, '/desired_position'],...
                'geometry_msgs/Pose2D', 'IsLatching', false);

    % Setup Service Calls
    % h.srv.get_battery = rossvcclient('/motion/main_battery');
    
end

function test(src, msg, h, ally)
    disp(msg);
end