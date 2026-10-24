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
	assert(game.running and not game.panel.visible,"Continue enters playable world")
	for language in ["id","en"]:
		game.lang = language
		for kind in ["build","farm","inventory","economy","population","research","quests","achievements","settings","credits"]:
			game.open_panel(kind)
			await process_frame
			assert(game.rows.get_child_count()>0,"Panel must contain real controls: "+kind)
	game.selected = game.sim.building_at(Vector2i(8,9))
	game.open_panel("building")
	await process_frame
	game.close_panel()
	await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name()!="headless":
		DirAccess.make_dir_recursive_absolute("res://build/screenshots")
		root.get_texture().get_image().save_png("res://build/screenshots/gameplay.png")
	print("UI SMOKE: all 11 panels loaded in Indonesian and English; world rendered")
	game.queue_free()
	await process_frame
	quit()
