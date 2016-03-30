import numpy as np

import Skills
import Utilities
import Constants

class ShootState:
    setup   = 0
    attack  = 1
    shoot   = 2

class TrickState:
    setvars = 0
    setup   = 1
    attack  = 2
    shoot   = 3


_shoot_state        = ShootState.setup
_trick_state        = TrickState.setvars
_steal_ball_state   = ShootState.setup

_wait_steal_timer   = 0
_WAIT_STEAL_MAX     = 20

_offensive  = 0
_defensive  = 1
_neutral    = 2

_trick_x_before = None
_trick_y_before = None
_trick_x_after  = None
_trick_y_after  = None


##########################################
# Plays mainly for "attacker" position:  #
##########################################

def shoot_on_goal(me, ball, distance_from_center):
    """ this sets up for a shot at a distance from the center. Distance from center should be between -1 and 1 (really like .75 and -.75).
        0 signifies straight on, 1 is top corner and -1 is bottom corner
        it also attacks the ball then actuates the kicker"""

    global _shoot_state

    # this is the desired setup point, the whole state machine needs it so it is
    # calculated here
    desired_setup_position = Skills.set_up_kick_facing_goal(ball, distance_from_center)#!!!!!!should we try and do future? So it predicts
    # get the distance to the ball
    (x_pos, y_pos) = Utilities.get_front_of_robot(me)
    distance_from_kicker_to_ball = Utilities.get_distance_between_points(x_pos, y_pos, ball.xhat, ball.yhat) # ****changed from _future

    #########################
    ### transition states ###
    #########################
    if _shoot_state == ShootState.setup:
        # if the robot is close enough to the correct angle and its in front of the ball change to the attack state
        if Utilities.robot_close_to_point(me, *desired_setup_position) and not Utilities.is_ball_behind_robot(me, ball): 
            _shoot_state = ShootState.attack

    elif _shoot_state == ShootState.attack:
        # if the ball is behind the robot, go back to set up
        if (Utilities.is_ball_behind_robot(me, ball)):
            _shoot_state = ShootState.setup
        # if the ball is close enough, go to the shoot state
        elif(distance_from_kicker_to_ball <=  Constants.kickable_distance):
            _shoot_state = ShootState.shoot

    elif _shoot_state == ShootState.shoot:
        # If the ball is still close to the kicker, we need to kick until it is far away.
        if distance_from_kicker_to_ball > Constants.kickable_distance:
            _shoot_state = ShootState.setup 
    # default state, go to setup
    else:
        _shoot_state = ShootState.setup

    ###############################
    ### Moore Outputs in states ###
    ###############################
    # go to the desired setup location
    if(_shoot_state == ShootState.setup):
        return desired_setup_position

    # attack the ball
    elif  _shoot_state == ShootState.attack:
        return Skills.attack_ball(me, ball)

    # GGGGGOOOOOOOOOOOAAAAAAAAAALLLLLLLLLLLL!!!!!!!!!!!!!!!!!!
    elif _shoot_state == ShootState.shoot:
        print "KICKING"
        Skills.kick()
        return Skills.attack_ball_with_kick(me, ball) # keep attacking the ball as you kick

    # wait for state machine to start
    else:
        print ('default')
        return (me.xhat, me.yhat, me.thetahat)


def shoot_off_the_wall(me, ball):
    global _trick_state
    global _trick_x_before, _trick_x_after, _trick_y_before, _trick_y_after

    (x,y) = Utilities.get_front_of_robot(me)
    distance_from_kicker_to_ball = Utilities.get_distance_between_points(x, y, ball.xhat, ball.yhat)
    set_up_distance = Constants.robot_half_width + 0.30

    y_tweak_value = 8.0/10.0 # Ideally, we should aim for goal pos mirrored above/below us, but it won't be perfect so this should handle that
    if ball.yhat > 0:
        theta_c = Utilities.get_angle_between_points(ball.xhat, ball.yhat, Constants.field_length/2, Constants.field_width*y_tweak_value-ball.yhat)
    else:
        theta_c = Utilities.get_angle_between_points(ball.xhat, ball.yhat, Constants.field_length/2, -Constants.field_width*y_tweak_value+ball.yhat)
    theta_c = Utilities.rad_to_deg(theta_c)

    #########################
    ### transition states ###
    #########################
    if _trick_state == TrickState.setvars:
        # Assign desired positions
        _trick_x_before = ball.xhat-set_up_distance*np.cos(theta_c)
        _trick_y_before = ball.yhat-set_up_distance*np.sin(theta_c)

        _trick_x_after = ball.xhat+set_up_distance*np.cos(theta_c)
        _trick_y_after = ball.yhat+set_up_distance*np.sin(theta_c)
        # Transition to setup state
        _trick_state = TrickState.setup

    elif _trick_state == TrickState.setup:
        if Utilities.robot_close_to_point(me, _trick_x_before, _trick_y_before, theta_c):
            _trick_state = TrickState.attack

    elif _trick_state == TrickState.attack:
        if(distance_from_kicker_to_ball <= Constants.kickable_distance):
            _trick_state = TrickState.shoot

    elif _trick_state == TrickState.shoot:
        if distance_from_kicker_to_ball > Constants.kickable_distance:
            _trick_state == TrickState.setvars

    else:
        _trick_state = TrickState.setvars

    
    ###############################
    ### Moore Outputs in states ###
    ###############################
    if _trick_state == TrickState.setup:
        return (_trick_x_before, _trick_y_before, theta_c)

    elif _trick_state == TrickState.attack:
        return (_trick_x_after, _trick_y_after, theta_c)

    elif _trick_state == TrickState.shoot:
        Skills.kick()
        return (_trick_x_after, _trick_y_after, theta_c)

    else:
        return (_trick_x_before, _trick_y_before, theta_c)


def steal_ball_from_opponent(me, opponent, ball):
    """
    Using xhat_future and yhat_future to predict where the ball will be, and 
    put itself in front of the opponent, facing opponent's goal, ready to kick the 
    ball towards their goal
    """
    global _steal_ball_state
    global _wait_steal_timer, _WAIT_STEAL_MAX

    # WE ARE USING FUTURE POSITIONS SO WE WILL BE WHERE THE BALL IS HOPEFULLY BEFORE THE OPPONENT
    theta_des = Utilities.get_angle_between_points(ball.xhat_future, ball.yhat_future, opponent.xhat, opponent.yhat)
    x_des = ball.xhat_future - Constants.steal_ball_dist*np.cos(theta_des)
    y_des = ball.yhat_future - Constants.steal_ball_dist*np.sin(theta_des)
    # but we need the kicker to get the current position so it will kick correctly
    (x,y) = Utilities.get_front_of_robot(me)
    distance_from_kicker_to_ball = Utilities.get_distance_between_points(x, y, ball.xhat, ball.yhat)

    #########################
    ### transition states ###
    #########################
    if _steal_ball_state == ShootState.setup:
        opp_dist_from_ball = Utilities.get_distance_between_points(opponent.xhat, opponent.yhat, ball.xhat_future, ball.yhat_future)
        if Utilities.robot_close_to_point(me, x_des, y_des, theta_des):
            _wait_steal_timer = _wait_steal_timer + 1
            if (opp_dist_from_ball >= Constants.steal_ball_dist or _wait_steal_timer >= _WAIT_STEAL_MAX):
                _wait_steal_timer = 0
                _steal_ball_state = ShootState.attack
    elif _steal_ball_state == ShootState.attack:
        if distance_from_kicker_to_ball <= Constants.kickable_distance:
            _steal_ball_state = ShootState.shoot
    elif _steal_ball_state == ShootState.shoot:
        if distance_from_kicker_to_ball > Constants.kickable_distance:
            _steal_ball_state = ShootState.setup
    else:
        _steal_ball_state = ShootState.setup

    ###############################
    ### Moore Outputs in states ###
    ###############################
    if _steal_ball_state == ShootState.setup:
        return (x_des, y_des, theta_des)
    elif _steal_ball_state == ShootState.attack:
        return Skills.attack_ball_with_kick(me, ball)
    elif _steal_ball_state == ShootState.shoot:
        Skills.kick()
        return Skills.attack_ball_with_kick(me, ball)
    else:
        return (me.xhat, me.yhat, Utilities.rad_to_deg(me.thetahat))


def stay_open_for_pass(me, my_teammate, ball, r_l_toggle):
    """
    Teammate stays open for pass along y = 1.05 line, and stops at 
    x = 1.0 line waiting for the ball to be passed to it
    """
    print "staying open for pass......."
    x_limit_for_pass = 1.00
    y_c = Constants.open_for_pass_y_pos*r_l_toggle
    x_c = ball.xhat + 0.50
    if (x_c > x_limit_for_pass): x_c = x_limit_for_pass
    theta_c = 90*r_l_toggle
    return (x_c, y_c, theta_c)
    

def pass_to_teammate(me, my_teammate, ball):
    x_limit_for_pass = 1.00
    theta = Utilities.get_angle_between_points(me.xhat, me.yhat, x_limit_for_pass, Constants.open_for_pass_y_pos)
    (x_pos, y_pos) = Utilities.get_front_of_robot(me)
    dist_to_ball = Utilities.get_distance_between_points(x_pos, y_pos, ball.xhat, ball.yhat)
    
    if (Utilities.close(me.thetahat, theta, tolerance = 10) and dist_to_ball <= Constants.kickable_distance):
        return Skills.attack_ball(me, ball)
    else:
        return Skills.go_behind_ball_facing_target(ball, Constants.kickable_distance, x_limit_for_pass, Constants.open_for_pass_y_pos)

        

##########################################
# Plays mainly for "defender" position:  #
##########################################

def stay_at_midfield_follow_ball(me, opponent1, opponent2, ball):
    x_c = Constants.half_field
    y_c = ball.yhat_future
    theta = Utilities.get_angle_between_points(me.xhat, me.yhat, Constants.goal_position_opp[0], Constants.goal_position_opp[1])
    theta = Utilities.rad_to_deg(theta)
    return (x_c, y_c, theta)

def stay_between_points_at_distance(x1, y1, x2, y2, distance):
    """
    Distance should be between 0 and 1, scaled from the first point
    example follow ball 2/3 distance from goal to ball
    """
    theta = Utilities.get_angle_between_points(x1, y1, x2, y2)
    c = Utilities.get_distance_between_points(x1, y1, x2, y2)
    cprime = c*(1-distance)

    # aprime is the length of the simalar triangle with hypotenuse cprime
    aprime = cprime*np.cos(theta)
    # bprime is the height of the simalar triangle with hypotenuse cprime
    bprime = cprime*np.sin(theta)

    x_desired = x2 - aprime
    y_desired = y2 - bprime
    theta = Utilities.rad_to_deg(theta)

    return (x_desired, y_desired, theta)

##########################################
# Plays mainly for "goalie" position:    #
##########################################
