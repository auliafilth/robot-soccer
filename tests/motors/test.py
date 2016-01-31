import rcv3.roboclaw as r

r.Open('/dev/ttySAC0', 38400)

def readPIDQ():
	PIDQ = []
	PIDQ.append(r.ReadM1VelocityPID(0x80))
	PIDQ.append(r.ReadM2VelocityPID(0x80))
	PIDQ.append(r.ReadM1VelocityPID(0x81))
	return PIDQ

def setAllPIDQ(p,i,d,q):
	r.SetM1VelocityPID(0x80,p,i,d,q)
	r.SetM2VelocityPID(0x80,p,i,d,q)
	r.SetM1VelocityPID(0x81,p,i,d,q)

def spin(speed):
	r.SpeedM1(0x80, speed)
	r.SpeedM2(0x80, -speed)
#	r.SpeedM1(0x81, speed)

def forward(speed):
	r.SpeedM1(0x80, speed)
	r.SpeedM2(0x80, speed)

def stop():
	r.ForwardM1(0x80, 0)
	r.ForwardM2(0x80, 0)
	r.ForwardM1(0x81, 0)
