class Robot(object):
	"""docstring for Robot"""
	BIG_MAC = 0
	HAPPY_MEAL = 1
	OPPONENT = 2
	def __init__(self, ally1=False, ally2=False):
		super(Robot, self).__init__()
		self.role = role

	def update_state(self, msg):
		self.xhat = msg.xhat
		self.yhat = msg.yhat
		self.thetahat = msg.thetahat
    	self.xhat_future = msg.xhat_future
    	self.yhat_future = msg.yhat_future
    	self.thetahat_future = msg.thetahat_future