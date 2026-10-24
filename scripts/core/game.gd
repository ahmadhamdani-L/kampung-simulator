extends Node2D

const Sim = preload("res://scripts/core/simulation.gd")
const Save = preload("res://scripts/persistence/save_manager.gd")
const World = preload("res://scripts/world/world_view.gd")
var sim := Sim.new()
var saver := Save.new()
var world: VillageWorld
var ui: CanvasLayer
var hud: Label
var status: Label
var toast_label: Label
var panel: PanelContainer
var rows: VBoxContainer
var panel_title: Label
var modal := ""
var selected: Dictionary = {}
var placement := ""
var tick_accum := 0.0
var save_accum := 0.0
var hud_accum := 0.0
var running := false
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var ambient: AudioStreamPlayer
var confirmation: ConfirmationDialog
var confirm_action: Callable
var lang := "id"
var menu_art: TextureRect

func _ready() -> void:
	get_tree().auto_accept_quit = false
	world = World.new()
	world.sim = sim
	add_child(world)
	world.tile_clicked.connect(on_tile)
	sim.notification.connect(notify)
	create_theme()
	create_audio()
	create_ui()
	if saver.load_game(sim):
		lang = str(sim.state.settings.language)
		saver.save_game(sim)
		world.pan = Vector2(get_viewport_rect().size.x*0.5,70)
	apply_audio()
	show_menu()

func t(id: String, en: String) -> String:
	return en if lang=="en" else id

func create_theme() -> void:
	var theme := Theme.new()
	theme.default_font_size = 17
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("28534d")
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	theme.set_stylebox("normal","Button",normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("3c7062")
	theme.set_stylebox("hover","Button",hover)
	var pressed := normal.duplicate()
	pressed.bg_color = Color("a67b42")
	theme.set_stylebox("pressed","Button",pressed)
	var disabled := normal.duplicate()
	disabled.bg_color = Color("344844")
	theme.set_stylebox("disabled","Button",disabled)
	theme.set_color("font_color","Button",Color("fff5dc"))
	theme.set_color("font_color","Label",Color("f6efd9"))
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("142f2e")
	surface.set_corner_radius_all(18)
	surface.content_margin_left = 22
	surface.content_margin_right = 22
	surface.content_margin_top = 18
	surface.content_margin_bottom = 18
	theme.set_stylebox("panel","PanelContainer",surface)
	ui = CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.name = "Interface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme
	ui.add_child(root)
	menu_art = TextureRect.new()
	menu_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_art.texture = load("res://assets/menu-art.png")
	menu_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(menu_art)
	menu_art.hide()

func create_audio() -> void:
	for bus_name in ["Music","SFX","Ambient"]:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,bus_name)
		AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.stream = load("res://assets/audio/village.wav")
	add_child(music)
	music.finished.connect(func(): music.play())
	music.play()
	sfx = AudioStreamPlayer.new()
	sfx.bus = "SFX"
	sfx.stream = load("res://assets/audio/chime.wav")
	add_child(sfx)
	ambient = AudioStreamPlayer.new()
	ambient.bus = "Ambient"
	ambient.stream = load("res://assets/audio/birds.wav")
	add_child(ambient)
	ambient.finished.connect(func(): ambient.play())
	ambient.play()

func apply_audio() -> void:
	for pair in [["Music","music"],["SFX","sfx"],["Ambient","ambient"]]:
		var value := float(sim.state.settings.get(pair[1],0.3))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(pair[0]),linear_to_db(maxf(0.0001,value)))

func create_ui() -> void:
	var root: Control = ui.get_child(0)
	var top := PanelContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_right = -18
	top.offset_top = 14
	top.offset_bottom = 90
	root.add_child(top)
	var top_box := HBoxContainer.new()
	top_box.add_theme_constant_override("separation",24)
	top.add_child(top_box)
	var brand := Label.new()
	brand.text = "KAMPUNG\nDari desa jadi kota"
	brand.add_theme_font_size_override("font_size",20)
	brand.add_theme_color_override("font_color",Color("f2d38e"))
	top_box.add_child(brand)
	hud = Label.new()
	hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_box.add_child(hud)
	button(top_box,"☰",show_menu)
	var bottom := HBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 18
	bottom.offset_right = -18
	bottom.offset_top = -72
	bottom.offset_bottom = -18
	bottom.add_theme_constant_override("separation",8)
	root.add_child(bottom)
	for item in [["Bangun","Build","build"],["Bertani","Farm","farm"],["Gudang","Stock","inventory"],["Ekonomi","Trade","economy"],["Warga","People","population"],["Riset","Research","research"],["Misi","Quests","quests"],["Prestasi","Awards","achievements"]]:
		var key: String = item[2]
		var b := button(bottom,t(item[0],item[1]),func(): open_panel(key))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status = Label.new()
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	status.offset_left = 28
	status.offset_top = -102
	status.offset_bottom = -78
	root.add_child(status)
	toast_label = Label.new()
	toast_label.position = Vector2(28,104)
	toast_label.add_theme_font_size_override("font_size",21)
	toast_label.add_theme_color_override("font_color",Color("ffdf8b"))
	root.add_child(toast_label)
	var side := VBoxContainer.new()
	side.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	side.offset_left = -85
	side.offset_right = -25
	side.offset_top = -100
	side.offset_bottom = 100
	root.add_child(side)
	button(side,"+",func(): world.target_zoom = minf(1.7,world.target_zoom*1.2))
	button(side,"−",func(): world.target_zoom = maxf(0.3,world.target_zoom/1.2))
	button(side,"⌂",func(): world.pan = Vector2(640,60); world.target_zoom = 0.85)
	button(side,"≋",func(): world.overlay = not world.overlay; notify(t("Overlay akses jalan","Road access overlay")))
	panel = PanelContainer.new()
	panel.position = Vector2(760,108)
	panel.size = Vector2(490,490)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	panel.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	panel_title = Label.new()
	panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_title.add_theme_font_size_override("font_size",25)
	title_row.add_child(panel_title)
	button(title_row,"×",close_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(436,380)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",9)
	scroll.add_child(rows)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Kampung Simulator"
	confirmation.confirmed.connect(func(): confirm_action.call())
	root.add_child(confirmation)
	update_hud()

func button(parent: Node, text_value: String, action: Callable, disabled: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size.y = 48
	b.disabled = disabled
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func label(text_value: String) -> Label:
	var l := Label.new()
	l.text = text_value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 425
	rows.add_child(l)
	return l

func clear_rows() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()

func close_panel() -> void:
	menu_art.hide()
	panel.hide()
	modal = ""

func notify(message: String) -> void:
	if toast_label==null: return
	toast_label.text = message
	toast_label.modulate.a = 1
	if sfx!=null: sfx.play()
	var tween := create_tween()
	tween.tween_interval(3)
	tween.tween_property(toast_label,"modulate:a",0.0,1)

func confirm(text_value: String, action: Callable) -> void:
	confirm_action = action
	confirmation.dialog_text = text_value
	confirmation.popup_centered(Vector2i(500,180))

func show_menu() -> void:
	menu_art.show()
	modal = "menu"
	panel.show()
	clear_rows()
	panel_title.text = "KAMPUNG SIMULATOR"
	label(t("Dari desa jadi kota\nBangun masa depan kampungmu.","From village to city\nBuild your village's future."))
	button(rows,t("Lanjutkan","Continue"),func(): running = true; close_panel(); notify(t("Ketuk sawah untuk menanam. Misi memandu perkembanganmu.","Tap a field to plant. Quests guide your progress.")))
	button(rows,t("Permainan baru","New game"),func(): confirm(t("Mulai ulang kampung? Simpanan saat ini diganti.","Start a new village? Current progress will be replaced."),func(): sim.new_game(); running = true; save_game(); close_panel()))
	button(rows,t("Pengaturan","Settings"),func(): open_panel("settings"))
	button(rows,"Bahasa Indonesia / English",func(): lang = "en" if lang=="id" else "id"; sim.state.settings.language = lang; show_menu())
	button(rows,t("Kredit","Credits"),func(): open_panel("credits"))
	button(rows,t("Simpan & keluar","Save & quit"),func(): if save_game(): get_tree().quit())

func open_panel(kind: String) -> void:
	if running: menu_art.hide()
	modal = kind
	panel.show()
	clear_rows()
	panel_title.text = {"build":t("Bangun kampung","Build your village"),"farm":t("Lumbung desa","Village farming"),"inventory":t("Gudang","Inventory"),"economy":t("Pasar & ekonomi","Market & economy"),"population":t("Warga kampung","Village residents"),"research":t("Riset & teknologi","Research & technology"),"quests":t("Misi kampung","Village quests"),"achievements":t("Prestasi","Achievements"),"settings":t("Pengaturan","Settings"),"credits":t("Kredit","Credits"),"building":t("Bangunan","Building")}.get(kind,kind)
	match kind:
		"build":
			label(t("Pilih bangunan, lalu ketuk lahan. Hubungkan ke jalan utama.","Choose a building, then tap land. Connect it to the main road."))
			button(rows,t("Perluas wilayah · Rp %d","Expand land · Rp %d")%(int(sim.state.land)*300),func(): action_result(sim.expand()); open_panel("build"))
			for id in sim.content.buildings:
				var d: Dictionary = sim.content.buildings[id]
				var unlocked: bool = int(d.level)<=int(sim.state.level)
				var key: String = id
				button(rows,"%s · Rp %d%s"%[d.name_en if lang=="en" else d.name,int(d.price),"" if unlocked else " · Lv %d"%int(d.level)],func(): placement = key; world.placement = key; close_panel(); notify(t("Ketuk lahan · Batal: Esc","Tap land · Cancel: Esc")),not unlocked)
		"farm":
			label(t("Benih dan pupuk tersedia di pasar. Sawah perlu akses jalan. Panen manual saat matang.","Buy seeds and fertilizer at market. Fields need road access. Harvest when ready."))
			for b in sim.state.buildings:
				if not sim.content.crops.has(b.type) and not sim.content.livestock.has(b.type): continue
				var instance: Dictionary = b
				button(rows,"%s · %s"%[sim.content.buildings[b.type].name,b.crop if sim.content.crops.has(b.type) else "%d hewan · %d produk"%[int(b.animals),int(b.stored)]],func(): selected = instance; open_panel("building"))
		"inventory":
			label(t("Kapasitas %d unit","Capacity %d units")%sim.storage_capacity())
			for id in sim.state.inventory: label("%s                         %d"%[sim.content.products[id].name,int(sim.state.inventory[id])])
		"economy":
			label(t("Kas Rp %d · Laba terkumpul Rp %d\nHarga mengikuti stok dan peristiwa. Pajak tiap 120 detik.","Cash Rp %d · Cumulative profit Rp %d\nPrices follow stock and events. Taxes every 120 seconds.")%[int(sim.state.money),int(sim.state.profit)])
			for id in sim.content.products:
				var key: String = id
				label("%s · %d stok · Rp %d/u"%[sim.content.products[id].name,int(sim.state.inventory.get(id,0)),sim.price(id)])
				var row := HBoxContainer.new()
				rows.add_child(row)
				button(row,t("Jual 5","Sell 5"),func(): action_result(sim.trade(key,5)); open_panel("economy"))
				button(row,t("Beli 5","Buy 5"),func(): action_result(sim.trade(key,5,true)); open_panel("economy"))
			button(rows,t("Kerja bakti · bantuan darurat","Community work · emergency aid"),func(): action_result(sim.recovery()); open_panel("economy"))
		"population":
			label(t("Penduduk %d / %d\nPekerja %d · Lowongan %d\nKebahagiaan %d%%\nKesehatan %d · Pendidikan %d\nKeamanan %d\nAir %d · Listrik %d\nPemeliharaan Rp %d / hari", "Residents %d / %d\nWorkers %d · Jobs %d\nHappiness %d%%\nHealth %d · Education %d\nSecurity %d\nWater %d · Power %d\nMaintenance Rp %d / day")%[int(sim.state.population),sim.metrics.housing,sim.metrics.workers,sim.metrics.jobs,int(sim.state.happiness),sim.metrics.health,sim.metrics.education,sim.metrics.security,sim.metrics.water,sim.metrics.power,sim.metrics.maintenance])
			label(t("Sediakan beras, rumah, pekerjaan, dan layanan. Warga baru datang setiap hari saat bahagia.","Provide rice, homes, jobs and services. Happy villages attract residents each day."))
			button(rows,t("Tampilkan akses jalan","Show road access"),func(): world.overlay = true; close_panel())
		"research":
			for id in sim.content.technologies:
				var d: Dictionary = sim.content.technologies[id]
				var key: String = id
				label("%s · +%d%% %s\nLv %d · Rp %d · %s"%[d.name,int(float(d.bonus)*100),d.effect,int(d.level),int(d.price),str(d.dependencies)])
				button(rows,t("Dipelajari","Completed") if id in sim.state.research else t("Teliti","Research"),func(): action_result(sim.research(key)); open_panel("research"),id in sim.state.research)
		"quests":
			label(t("Panduan: bangun → tanam → panen → jual → kembangkan. Hadiah diklaim sekali.","Guide: build → plant → harvest → sell → expand. Rewards can be claimed once."))
			for q in sim.content.quests:
				if not sim.quest_available(q): continue
				var key: String = q.id
				var done: bool = sim.state.quests.get(q.id,false)
				label("%s\n%s / %d · Rp %d + %d XP"%[q.name,str(sim.quest_progress(q)),int(q.objectives[0].count),int(q.rewards.money),int(q.rewards.xp)])
				button(rows,t("Selesai","Completed") if done else t("Klaim hadiah","Claim reward"),func(): action_result(sim.claim_quest(key)); open_panel("quests"),not sim.quest_ready(q))
			var contract := sim.repeatable()
			button(rows,"%s · %d %s → Rp %d"%[contract.name,contract.amount,contract.product,contract.reward],func(): action_result(sim.claim_contract()); open_panel("quests"))
		"achievements":
			for name_value in ["First Harvest","First Business","100 Residents","First Factory","Millionaire Village","Happy Village","Industrial Leader","Metropolitan Founder"]: label(("✓ " if name_value in sim.state.achievements else "○ ")+name_value)
			button(rows,"Prestige · Level 250",func(): confirm("Reset village for permanent starting capital bonus?",func(): action_result(sim.prestige()); open_panel("achievements")),int(sim.state.level)<250)
		"building": show_building()
		"settings":
			button(rows,t("Simpan sekarang","Save now"),save_game)
			button(rows,"Bahasa Indonesia / English",func(): lang = "en" if lang=="id" else "id"; sim.state.settings.language = lang; open_panel("settings"))
			for key in ["music","sfx","ambient"]:
				label(key.to_upper())
				var slider := HSlider.new()
				slider.min_value = 0
				slider.max_value = 1
				slider.step = 0.05
				slider.value = float(sim.state.settings[key])
				slider.custom_minimum_size.y = 40
				var bus_key: String = key
				slider.value_changed.connect(func(v: float): sim.state.settings[bus_key] = v; apply_audio())
				rows.add_child(slider)
			var check := CheckButton.new()
			check.text = t("Kurangi animasi","Reduced motion")
			check.button_pressed = bool(sim.state.settings.reduced_motion)
			check.toggled.connect(func(v: bool): sim.state.settings.reduced_motion = v)
			rows.add_child(check)
			label(t("Iklan dinonaktifkan · dapat dimainkan offline.\nData hanya disimpan di perangkat.","Ads disabled · fully playable offline.\nGame data stays on your device."))
		"credits":
			label("Kampung Simulator: Dari Desa Jadi Kota\nDream Develop Digital\n\nOriginal procedural art and synthesized audio created for this project.\nGodot Engine · MIT License\n\nNo account. No server. No purchases.\nVersion 0.1.0 · Development candidate")

func show_building() -> void:
	if selected.is_empty() or not sim.state.buildings.has(selected): close_panel(); return
	var b: Dictionary = selected
	var d: Dictionary = sim.content.buildings[b.type]
	panel_title.text = d.name_en if lang=="en" else d.name
	label("Lv %d · (%d, %d)\n%s\n%s\n%.0fs"%[int(b.upgrade),int(b.x),int(b.y),d.description,t("Terhubung jalan","Road connected") if sim.connected(b) else t("Perlu jalan","Needs road"),float(b.construction)])
	if sim.content.crops.has(b.type):
		label("%s · %.0f / %ds"%[b.crop,float(b.progress),int(sim.content.crops[b.type].seconds)])
		button(rows,t("Tanam · 1 benih","Plant · 1 seed"),func(): action_result(sim.plant(b)); open_panel("building"))
		button(rows,t("Tanam + pupuk","Plant + fertilizer"),func(): action_result(sim.plant(b,true)); open_panel("building"))
		button(rows,t("Panen","Harvest"),func(): action_result(sim.harvest(b)); open_panel("building"),b.crop!="READY")
	if sim.content.livestock.has(b.type):
		label("%d hewan · %d produk · %.0f%% sehat"%[int(b.animals),int(b.stored),float(b.health)])
		button(rows,t("Beli hewan · Rp 100","Buy animal · Rp 100"),func(): action_result(sim.acquire_animal(b)); open_panel("building"))
		button(rows,t("Kumpulkan produk","Collect products"),func(): action_result(sim.collect(b)); open_panel("building"))
	button(rows,t("Tingkatkan · Rp %d","Upgrade · Rp %d")%(int(d.price)*int(b.upgrade)),func(): action_result(sim.upgrade(b)); open_panel("building"))
	button(rows,t("Bongkar · kembali 35%","Demolish · 35% refund"),func(): confirm(t("Bongkar bangunan ini?","Demolish this building?"),func(): action_result(sim.demolish(b)); close_panel()),b.type=="hall")

func action_result(ok: bool) -> void:
	notify(t("Berhasil","Success") if ok else t("Belum bisa: cek stok, level, kapasitas, atau prasyarat.","Unavailable: check stock, level, capacity or prerequisites."))
	update_hud()

func on_tile(cell: Vector2i) -> void:
	if not running: return
	if not placement.is_empty():
		if sim.build(placement,cell): notify(sim.content.buildings[placement].name+" · dibangun")
		update_hud()
		return
	selected = sim.building_at(cell)
	if not selected.is_empty(): open_panel("building")

func save_game() -> bool:
	var ok := saver.save_game(sim)
	notify(t("Kampung tersimpan","Village saved") if ok else t("Simpan gagal","Save failed"))
	return ok

func update_hud() -> void:
	if hud==null: return
	var level := int(sim.state.level)
	var era: String = sim.content.levels[mini(level-1,299)].era
	hud.text = "Rp %s     •     %d %s     •     %d%% %s\nLv %d · %s     |     %d XP"%[format_number(int(sim.state.money)),int(sim.state.population),t("warga","residents"),int(sim.state.happiness),t("bahagia","happy"),level,era,int(sim.state.xp)]
	var day := int(float(sim.state.time)/120)+1
	status.text = "%s %d   ·   %s   ·   %s"%[t("Hari","Day"),day,sim.state.event.get("name",t("Cerah","Sunny")),t("Geser untuk menjelajah · cubit untuk zoom","Drag to explore · pinch to zoom")]
	if not placement.is_empty(): status.text = t("Mode bangun: ","Build mode: ")+sim.content.buildings[placement].name+t(" · Esc / tombol kembali untuk batal"," · Esc / back to cancel")

func format_number(value: int) -> String:
	var source := str(value)
	var output := ""
	for i in source.length():
		if i>0 and (source.length()-i)%3==0: output += "."
		output += source[i]
	return output

func _process(dt: float) -> void:
	if not running: return
	tick_accum += dt
	save_accum += dt
	hud_accum += dt
	if tick_accum>=1:
		sim.tick(floorf(tick_accum))
		tick_accum = fmod(tick_accum,1)
	if hud_accum>=1:
		update_hud()
		hud_accum = 0
	if save_accum>=float(sim.content.balance.autosave_seconds):
		saver.save_game(sim)
		save_accum = 0

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		placement = ""
		world.placement = ""
		if panel.visible: close_panel()
		else: show_menu()

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if saver.save_game(sim): get_tree().quit()
	if what==NOTIFICATION_APPLICATION_PAUSED and running: saver.save_game(sim)
	if what==NOTIFICATION_APPLICATION_RESUMED and running:
		# Reload saved timestamp once, then checkpoint to prevent repeated offline grants.
		if saver.load_game(sim): saver.save_game(sim)
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:
		placement = ""
		world.placement = ""
		if panel.visible: close_panel()
		else: show_menu()

func _exit_tree() -> void:
	confirm_action = Callable()
