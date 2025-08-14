class_name MessageQueue

var _messages: Array = [load("res://Neuro_integration/Adesi-NeuroIntegration/neuro-sdk/messages/outgoing/startup.gd").new()] # [OutgoingMessage]

func size() -> int:
	return _messages.size()

func enqueue(message) -> void:
	for existing_message in _messages:
		if existing_message.merge(message):
			return
	_messages.append(message)

func dequeue():
	if size() == 0:
		return null

	var message = _messages[0]
	_messages.pop_at(0)

	return message
