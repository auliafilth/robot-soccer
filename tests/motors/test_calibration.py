import wheelbase as w
import motion
import time
import numpy as np

w.init()

scale = .3
time_between = 1

motion.drive(scale,0,0)
time.sleep(time_between)

motion.stop()
time.sleep(time_between)

motion.drive(-scale,0,0)
time.sleep(time_between)

motion.stop()
time.sleep(time_between)

motion.drive(scale*np.cos(2*np.pi/3),scale*np.sin(2*np.pi/3),0)
time.sleep(time_between)

motion.stop()
time.sleep(time_between)

motion.drive(-np.cos(2*np.pi/3)*scale,-np.sin(2*np.pi/3)*scale,0)
time.sleep(time_between)

motion.stop()
time.sleep(time_between)

motion.drive(np.cos(-2*np.pi/3)*scale,np.sin(-2*np.pi/3)*scale,0)
time.sleep(time_between)

motion.stop()
time.sleep(time_between)

motion.drive(-np.cos(-2*np.pi/3)*scale,-np.sin(-2*np.pi/3)*scale,0)

time.sleep(time_between)
motion.stop()