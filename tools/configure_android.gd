@tool
extends SceneTree

func _initialize() -> void:
	call_deferred("configure")

func configure() -> void:
	await process_frame
	while EditorInterface.get_resource_filesystem().is_scanning():
		await process_frame
	var settings := EditorInterface.get_editor_settings()
	settings.set_setting("export/android/android_sdk_path",OS.get_environment("ANDROID_HOME"))
	settings.set_setting("export/android/java_sdk_path",OS.get_environment("JAVA_HOME"))
	print("Android tool paths configured (no credential values)")
	await create_timer(1.0).timeout
	quit()
