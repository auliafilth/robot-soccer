# Add this file to the bottom of your ~/.bashrc to include all of this goodness:
# i.e.,     `source /path/to/repo/scripts/simulator.bash`

# For DIR, see http://stackoverflow.com/a/246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATH_TO_REPO="$DIR/.."

# What is the package name of all your robot code?
ROBOT_PKG='playground'

# Aliases
alias ll='ls -lh --color'
alias l='ls -alh --color'
alias ..='cd ..'
alias ...='cd ../..'

# ROS
source /opt/ros/indigo/setup.bash
export ROS_MASTER_URI=http://localhost:11311
source $PATH_TO_REPO/ros/devel/setup.bash

function killsim() {
    # must be called in the same terminal you started
    killall roslaunch

    # Kill all jobs
    # kill $(jobs -p)

    # # kill gazebo
    # kill `ps aux | grep gazebo | grep ros | awk '{ print $2; }'`

    # # kill al nodes
    # kill `ps aux | grep python | grep ros | awk '{ print $2;}'`
}

# Simulation Scripts (The user can put in bg with &)
function simulator_1v1() {
    # To launch the simulation environment in the background, with ally1
    # ready to go (delete home2 and away2 robots)
    roslaunch "$ROBOT_PKG" simulator.launch &
    sleep 9 # Otherwise there is a race condition

    # Delete unneccesary models
    rosservice call /gazebo/delete_model home2
    rosservice call /gazebo/delete_model away2

    roslaunch "$ROBOT_PKG" ally1.launch &
    export SIM_ROBOTS=1
}

function simulator_2v2() {
    # To launch the simulation environment in the background,
    # with ally1 and ally2 ready to go.
    roslaunch "$ROBOT_PKG" simulator.launch &
    sleep 6 # Otherwise there is a race condition
    roslaunch "$ROBOT_PKG" ally1.launch &
    sleep 2
    roslaunch "$ROBOT_PKG" ally2.launch &
    export SIM_ROBOTS=2
}

function sim_go() {
    if [[ $SIM_ROBOTS -eq 1 ]]; then
        roslaunch "$ROBOT_PKG" ai_ally1.launch &
    elif [[ $SIM_ROBOTS -eq 2 ]]; then
        roslaunch "$ROBOT_PKG" ai_ally1.launch &
        roslaunch "$ROBOT_PKG" ai_ally2.launch &
    else
        echo
        echo "ERROR!"
        echo "You must start the simulator first using:"
        echo "    For 1v1: simulator_1v1"
        echo "    For 2v2: simulator_2v2"
        echo
        echo "... noob."
        echo
    fi

    # Remove env var for next run
    unset SIM_ROBOTS
}