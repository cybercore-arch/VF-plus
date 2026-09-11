extends Node

@onready var pattern_manager = get_parent()

func execute(event: Dictionary):
	var attack_type = event.get("attack", "")
	var delay = event.get("delay", 2.0)
	var loop_duration = event.get("loop_duration", -1.0)
	
	var sub_event = event.duplicate()
	sub_event["type"] = attack_type
	sub_event.erase("attack")
	sub_event.erase("loop_duration")
	
	run_loop(attack_type, sub_event, delay, loop_duration)

func run_loop(attack_type: String, sub_event: Dictionary, delay: float, loop_duration: float):
	var start_time = Time.get_ticks_msec() / 1000.0
	
	while loop_duration == -1.0 or (Time.get_ticks_msec() / 1000.0) - start_time < loop_duration:
		if not is_inside_tree():
			return
			
		var attack_node: Node = null
		if pattern_manager.has_method("get_attack_node"):
			attack_node = pattern_manager.get_attack_node(attack_type)
		else:
			attack_node = pattern_manager.get_node_or_null(attack_type)
			
		if attack_node and attack_node.has_method("execute"):
			attack_node.execute(sub_event)
		else:
			print("loop: узел атаки '", attack_type, "' не найден!")
			
		await get_tree().create_timer(delay).timeout
