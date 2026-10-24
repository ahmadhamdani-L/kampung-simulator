extends SceneTree

var game: Node

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not (not game.running and game.nav_buttons.all(func(b): return b.disabled)):
		push_error("Main menu must block gameplay navigation")
		quit(1)
		return
	# Exercise the actual Continue button connection.
	game.rows.get_child(1).pressed.emit()
	if not (game.running and not game.panel.visible and game.nav_buttons.all(func(b): return not b.disabled)):
		push_error("Continue enters playable world")
		quit(1)
		return
	game.show_menu()
	game.open_panel("settings")
	game.close_panel()
	if not (game.modal=="menu" and not game.running):
		push_error("Closing menu settings returns to the main menu")
		quit(1)
		return
	game.close_panel()
	if not game.running:
		push_error("Closing the main menu resumes gameplay")
		quit(1)
		return
	game.placement = "bamboo"
	game.world.placement = "bamboo"
	game.handle_back()
	if not (game.placement.is_empty() and game.world.placement.is_empty() and game.running and not game.panel.visible):
		push_error("Back cancels placement without opening the menu")
		quit(1)
		return
	game.handle_back()
	if not (game.modal=="menu" and not game.running):
		push_error("Back from gameplay opens the main menu")
		quit(1)
		return
	game.continue_game()
	await process_frame
	if not (game.world.camera.current and game.world.ground_root.get_child_count()<=4):
		push_error("3D world must render with an active camera and batched terrain")
		quit(1)
		return
	var instance_total := 0
	for terrain_batch in game.world.ground_root.get_children():
		instance_total += terrain_batch.multimesh.instance_count
	if instance_total!=1600:
		push_error("3D terrain must cover the full 40x40 world")
		quit(1)
		return
	var field_point := Vector3(8.0*game.world.TILE_SIZE,0,9.0*game.world.TILE_SIZE)
	if game.world.raycast_to_grid(game.world.camera.unproject_position(field_point))!=Vector2i(8,9):
		push_error("3D camera tap picking must hit the intended field")
		quit(1)
		return
	game.world.overlay = true
	game.world.overlay_kind = "road"
	game.world._sync_overlay()
	if game.world.overlay_root.get_child_count()==0:
		push_error("Road coverage overlay must render in 3D")
		quit(1)
		return
	game.world.overlay = false
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
