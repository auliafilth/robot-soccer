# Add this file to the bottom of your ~/.bashrc to include all of this goodness:
# i.e.,     `source /path/to/repo/scripts/odroid_setup.bash`

# For DIR, see http://stackoverflow.com/a/246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATH_TO_REPO="$DIR/.."

# Aliases
alias ll='ls -lh --color'
alias l='ls -alh --color'
alias ..='cd ..'
alias ...='cd ../..'
alias teleop='cd "%SCRIPTPATH"/tests/motors/ && ipython teleop.py'
alias gpio='cd /sys/class/gpio/ && cd gpio200'

# ROS
source /opt/ros/indigo/setup.bash
export ROS_MASTER_URI=http://ronald:11311
source $PATH_TO_REPO/ros/devel/setup.bash

# Killbot
# alias killbot='$PATH_TO_REPO/scripts/killbot.py'
alias battery='$PATH_TO_REPO/scripts/battery.py'
alias kick='$PATH_TO_REPO/scripts/kick.py'

function killbot() {
    killall roslaunch
    $PATH_TO_REPO/scripts/killbot.py
}

# Setup GPIO (kicker == gpio200)
#echo 200 > /sys/class/gpio/export
#echo out > /sys/class/gpio/gpio200/direction
#echo 0 > /sys/class/gpio/gpio200/value
