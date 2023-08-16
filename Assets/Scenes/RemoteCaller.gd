extends Timer

var functionToCall: String

func callDelayed(functionName: String, delayAmount: float = 0.05) -> void:
	functionToCall = functionName
	self.start(delayAmount)

func _on_timeout() -> void:
	self.stop()
	get_parent().call(functionToCall)
