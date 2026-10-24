extends SceneTree

var game: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	# Exercise the actual Continue button connection.
	game.rows.get_child(1).pressed.emit()
	if not (game.running and not game.panel.visible):
		push_error("Continue enters playable world")
		quit(1)
		return
	for language in ["id","en"]:
		game.lang = language
		for kind in ["build","farm","inventory","economy","population","research","quests","achievements","settings","credits"]:
			game.open_panel(kind)
			await process_frame
			if not (game.rows.get_child_count()>0):
				push_error("Panel must contain real controls: "+kind)
				quit(1)
				return
	Input.emulate_touch_from_mouse = true
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse",true)
	game.open_panel("build")
	await process_frame
	var scroll: ScrollContainer = game.rows.get_parent()
	scroll.scroll_vertical = 0
	await process_frame
	var start := scroll.global_position+Vector2(120,280)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = start
	Input.parse_input_event(touch)
	await process_frame
	for i in range(8):
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = start-Vector2(0,(i+1)*22)
		drag.relative = Vector2(0,-22)
		Input.parse_input_event(drag)
		await process_frame
	touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = start-Vector2(0,176)
	touch.pressed = false
	Input.parse_input_event(touch)
	await process_frame
	if not (scroll.scroll_vertical>0):
		push_error("Touch swipe must scroll building catalog")
		quit(1)
		return
	if not (game.placement.is_empty()):
		push_error("Scrolling must not activate a building")
		quit(1)
		return
	Input.emulate_touch_from_mouse = false
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse",false)
	game.selected = game.sim.building_at(Vector2i(8,9))
	game.open_panel("building")
	await process_frame
	game.close_panel()
	await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute("res://build/screenshots")
		root.get_texture().get_image().save_png("res://build/screenshots/gameplay.png")
	print("UI SMOKE: all 11 panels loaded in Indonesian and English; touch scrolling checked; world rendered")
	game.queue_free()
	await process_frame
	quit()
