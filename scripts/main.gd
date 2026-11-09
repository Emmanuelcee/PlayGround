extends Node3D

const CAR_SCRIPT = preload("res://scripts/car.gd")
const MODES := ["QUICK RACE", "CAREER", "FREE DRIVE", "DRIFT CHALLENGE", "POLICE CHASE", "TOURNAMENT", "MULTIPLAYER"]
const TRACKS := ["NEON HARBOR", "ALPINE PASS", "DUST DEVIL", "PACIFIC RUN", "AFTER HOURS"]
const DRIFT_CHALLENGE_SECONDS := 120.0
const POLICE_CHASE_SECONDS := 90.0
const CARS := [
	{"name":"VORTEX GT", "class":"SPORT", "speed":66.0, "accel":26.0, "handling":1.0, "color":"#db4e45", "price":0},
	{"name":"NOVA R8", "class":"SUPERCAR", "speed":76.0, "accel":29.0, "handling":0.96, "color":"#35a8c8", "price":1800},
	{"name":"FALCON XR", "class":"MUSCLE", "speed":70.0, "accel":31.0, "handling":0.82, "color":"#e8aa45", "price":2400},
	{"name":"ZENITH S", "class":"HYPER", "speed":84.0, "accel":31.0, "handling":1.04, "color":"#d5d9df", "price":3800},
	{"name":"NIGHTSHADE", "class":"SPORT", "speed":73.0, "accel":27.0, "handling":1.12, "color":"#7657b9", "price":3200},
	{"name":"TORQUE RS", "class":"RALLY", "speed":68.0, "accel":29.0, "handling":1.22, "color":"#68ad72", "price":2800},
	{"name":"APEX V12", "class":"HYPER", "speed":88.0, "accel":32.0, "handling":0.93, "color":"#f0e5d6", "price":6200},
	{"name":"ECLIPSE GT", "class":"SPORT", "speed":74.0, "accel":28.0, "handling":1.1, "color":"#e56ca3", "price":3600},
	{"name":"BLAZE 900", "class":"SUPERCAR", "speed":81.0, "accel":30.0, "handling":1.02, "color":"#ef7646", "price":5200},
	{"name":"PHANTOM Z", "class":"HYPER", "speed":91.0, "accel":33.0, "handling":0.98, "color":"#4d637f", "price":8500},
	{"name":"LAMBORGHINI REVUELTO", "class":"HYBRID HYPERCAR", "speed":96.0, "accel":37.0, "handling":1.05, "color":"#d5e43a", "price":16000, "style":"wedge"},
	{"name":"FERRARI 296 GTB", "class":"HYBRID SUPERCAR", "speed":92.0, "accel":35.0, "handling":1.16, "color":"#d72d38", "price":13500, "style":"gt"},
	{"name":"PORSCHE 911 TURBO S", "class":"SPORTS CAR", "speed":92.0, "accel":36.0, "handling":1.18, "color":"#f2eee6", "price":12800, "style":"gt"},
	{"name":"MCLAREN 750S", "class":"SUPERCAR", "speed":94.0, "accel":36.0, "handling":1.12, "color":"#f08b35", "price":14500, "style":"wedge"},
	{"name":"NISSAN GT-R NISMO", "class":"SPORTS CAR", "speed":87.0, "accel":33.0, "handling":1.04, "color":"#4a4e56", "price":10200, "style":"gt"},
	{"name":"CHEVROLET CORVETTE Z06", "class":"SUPERCAR", "speed":92.0, "accel":35.0, "handling":1.08, "color":"#20a97a", "price":11400, "style":"wedge"},
	{"name":"FORD MUSTANG DARK HORSE", "class":"MUSCLE", "speed":85.0, "accel":32.0, "handling":0.96, "color":"#3367ad", "price":8800, "style":"muscle"},
	{"name":"MERCEDES-AMG GT", "class":"GRAND TOURER", "speed":89.0, "accel":34.0, "handling":1.1, "color":"#a7b3bd", "price":11900, "style":"gt"}
]
const PAINTS := ["#db4e45", "#35a8c8", "#e8aa45", "#d5d9df", "#7657b9", "#68ad72", "#f0e5d6", "#e56ca3", "#ef7646", "#4d637f"]

var save := ConfigFile.new()
var credits := 2500
var owned := [0]
var selected_car := 0
var selected_track := 0
var selected_mode := 0
var engine_level := 0
var paint_index := 0
var wheel_style := 0
var tournament_round := 0
var quality := 1
var target_fps := 60
var night := false
var rainy := false
var racing := false
var race_paused := false
var elapsed := 0.0
var race_time := 0.0
var drift_score := 0
var race_progress := 0
var lap := 1
var laps_total := 3
var player: StreetCar
var opponents: Array[StreetCar] = []
var route: Array[Vector3] = []
var route_index := 0
var opponent_progress: Array[int] = []
var opponent_route_indices: Array[int] = []
var rain_particles: GPUParticles3D
var countdown_remaining := 3.0
var camera: Camera3D
var ui: CanvasLayer
var menu_root: Control
var race_hud: Control
var message_label: Label
var speed_label: Label
var nitro_bar: ProgressBar
var touch_values := {"left":false,"right":false,"gas":false,"brake":false,"nitro":false,"drift":false}
var style := {}
var last_drift := false
var career_races := 0
var best_time := 0.0

func _ready() -> void:
	_load_progress()
	_build_environment()
	_build_track()
	_build_ui()
	_show_home()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _load_progress() -> void:
	if save.load("user://progress.cfg") == OK:
		credits = int(save.get_value("profile", "credits", credits))
		owned = save.get_value("profile", "owned", owned)
		selected_car = int(save.get_value("profile", "car", 0))
		engine_level = int(save.get_value("profile", "engine", 0))
		paint_index = int(save.get_value("profile", "paint", 0))
		career_races = int(save.get_value("profile", "career", 0))
		best_time = float(save.get_value("profile", "best", 0.0))
	selected_car = clampi(selected_car, 0, CARS.size() - 1)
	if not owned.has(0): owned.append(0)

func _save_progress() -> void:
	save.set_value("profile", "credits", credits)
	save.set_value("profile", "owned", owned)
	save.set_value("profile", "car", selected_car)
	save.set_value("profile", "engine", engine_level)
	save.set_value("profile", "paint", paint_index)
	save.set_value("profile", "career", career_races)
	save.set_value("profile", "best", best_time)
	save.save("user://progress.cfg")

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#101a37") if night else Color("#4779a1")
	sky_mat.sky_horizon_color = Color("#e18c65") if night else Color("#c8ddeb")
	sky_mat.ground_bottom_color = Color("#111722")
	sky_mat.ground_horizon_color = Color("#536070")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8fa6cd") if night else Color("#d0deef")
	env.ambient_light_energy = 0.65 if night else 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0) if not night else Vector3(-22, 38, 0)
	sun.light_color = Color("#ffd4ad") if not night else Color("#8eb6ff")
	sun.light_energy = 1.15 if not night else 0.38
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 180.0
	add_child(sun)

func _build_track() -> void:
	for child in get_children():
		if child.name.begins_with("Track_"): child.queue_free()
	var root := Node3D.new()
	root.name = "Track_" + TRACKS[selected_track]
	add_child(root)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(280, 220)
	ground.mesh = plane
	ground.position.y = -0.5
	ground.material_override = _mat(Color("#253a32") if selected_track != 2 else Color("#74634c"), 0.05, 0.9)
	root.add_child(ground)
	var floor_body := StaticBody3D.new()
	floor_body.name = "TrackFloor"
	floor_body.position.y = -1.0
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(280, 1, 220)
	floor_shape.shape = floor_box
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)
	route.clear()
	var points := 192
	var rx := 80.0
	var rz := 50.0
	if selected_track == 1: rz = 58.0
	if selected_track == 2: rx = 88.0; rz = 44.0
	if selected_track == 3: rx = 90.0; rz = 50.0
	if selected_track == 4: rx = 75.0; rz = 46.0
	for i in range(points):
		var a := TAU * float(i) / float(points)
		var zmod := sin(a * 2.0) * (5.0 if selected_track == 1 else 2.5)
		route.append(Vector3(rx * cos(a), 0, rz * sin(a) + zmod))
	_add_road(root)
	_add_props(root)

func _add_road(root: Node3D) -> void:
	var road_mesh := _ribbon_mesh(7.5, 0.02)
	var road := MeshInstance3D.new()
	road.mesh = road_mesh
	road.material_override = _mat(Color("#30363d") if not night else Color("#202532"), 0.25, 0.38)
	root.add_child(road)
	var edge := MeshInstance3D.new()
	edge.mesh = _ribbon_mesh(8.0, 0.0)
	edge.material_override = _mat(Color("#e4e6df"), 0.0, 0.8)
	root.add_child(edge)
	var center_line := MeshInstance3D.new()
	center_line.mesh = _ribbon_mesh(0.13, 0.045)
	center_line.material_override = _mat(Color("#d7c88f"), 0.0, 0.6)
	root.add_child(center_line)
	# Repeating reflective safety barriers define the drivable course and collide with cars.
	for side in [-1.0, 1.0]:
		for i in range(0, route.size(), 4):
			var tangent := (route[(i + 1) % route.size()] - route[(i - 1 + route.size()) % route.size()]).normalized()
			var lateral: Vector3 = Vector3(-tangent.z, 0, tangent.x) * side * 8.6
			var pos: Vector3 = route[i] + lateral + Vector3.UP * 0.58
			var barrier := StaticBody3D.new()
			barrier.position = pos
			barrier.rotation.y = atan2(tangent.x, tangent.z)
			barrier.collision_layer = 1
			barrier.collision_mask = 2
			var box := BoxShape3D.new()
			box.size = Vector3(0.35, 1.15, 5.2)
			var col := CollisionShape3D.new()
			col.shape = box
			barrier.add_child(col)
			var visual := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = box.size
			visual.mesh = bm
			visual.material_override = _mat(Color("#9faab4") if i % 8 < 4 else Color("#e35e50"), 0.55, 0.35)
			barrier.add_child(visual)
			root.add_child(barrier)

func _ribbon_mesh(width: float, y: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(route.size()):
		var p0: Vector3 = route[i]
		var p1: Vector3 = route[(i + 1) % route.size()]
		var tangent := (p1 - p0).normalized()
		var side := Vector3(-tangent.z, 0, tangent.x) * width
		var a := p0 + side + Vector3.UP * y
		var b := p0 - side + Vector3.UP * y
		var c := p1 + side + Vector3.UP * y
		var d := p1 - side + Vector3.UP * y
		st.set_normal(Vector3.UP); st.add_vertex(a); st.set_normal(Vector3.UP); st.add_vertex(c); st.set_normal(Vector3.UP); st.add_vertex(b)
		st.set_normal(Vector3.UP); st.add_vertex(c); st.set_normal(Vector3.UP); st.add_vertex(d); st.set_normal(Vector3.UP); st.add_vertex(b)
	st.generate_normals()
	return st.commit()

func _add_props(root: Node3D) -> void:
	var scenery := Node3D.new()
	scenery.name = "Scenery"
	root.add_child(scenery)
	var rng := RandomNumberGenerator.new()
	rng.seed = 101 + selected_track * 53
	var colors := [Color("#394653"), Color("#505b68"), Color("#66727a"), Color("#333c4c")]
	for i in range(84):
		var a := TAU * float(i) / 84.0 + rng.randf_range(-0.035, 0.035)
		var r := rng.randf_range(15.0, 27.0)
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Vector3((80.0 + r) * cos(a), 0, (50.0 + r) * sin(a))
		if selected_track == 2:
			pos += Vector3(12.0 * cos(a), 0, 4.0 * sin(a))
		var height := rng.randf_range(5.0, 19.0) if selected_track == 0 or selected_track == 4 else rng.randf_range(2.0, 8.0)
		var width := rng.randf_range(5.0, 10.0)
		var building := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(width, height, rng.randf_range(5.0, 10.0))
		building.mesh = box
		building.position = pos + Vector3(0, height * 0.5 - 0.1, 0)
		building.material_override = _mat(colors[rng.randi_range(0, colors.size() - 1)], 0.25, 0.72)
		scenery.add_child(building)
		if night and i % 2 == 0:
			var windows := MeshInstance3D.new()
			var window_mesh := BoxMesh.new()
			window_mesh.size = Vector3(width * 0.72, 0.11, 0.08)
			windows.mesh = window_mesh
			windows.position = building.position + Vector3(0, rng.randf_range(-height * 0.3, height * 0.3), box.size.z * 0.5 + 0.06)
			windows.material_override = _mat(Color("#ffcf78"), 0.1, 0.28, 1.5)
			scenery.add_child(windows)
	# Streetlights frame the course at night, coastal and urban locations.
	if night or selected_track == 0 or selected_track == 3:
		for i in range(0, route.size(), 12):
			var p: Vector3 = route[i]
			var tangent := (route[(i + 1) % route.size()] - route[(i - 1 + route.size()) % route.size()]).normalized()
			var side := Vector3(-tangent.z, 0, tangent.x)
			for sign_side in [-1.0, 1.0]:
				var pole := MeshInstance3D.new()
				var pole_mesh := CylinderMesh.new()
				pole_mesh.top_radius = 0.08
				pole_mesh.bottom_radius = 0.12
				pole_mesh.height = 7.0
				pole.mesh = pole_mesh
				pole.position = p + side * sign_side * 11.0 + Vector3.UP * 3.5
				pole.material_override = _mat(Color("#333a47"), 0.6, 0.4)
				scenery.add_child(pole)
				var lamp := MeshInstance3D.new()
				var lm := BoxMesh.new()
				lm.size = Vector3(0.65, 0.16, 0.3)
				lamp.mesh = lm
				lamp.position = pole.position + Vector3.UP * 3.5 + side * -sign_side * 1.0
				lamp.material_override = _mat(Color("#ffe2a4"), 0.1, 0.2, 1.4)
				scenery.add_child(lamp)

func _mat(color: Color, metallic := 0.1, roughness := 0.6, emission := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	menu_root = Control.new()
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(menu_root)
	race_hud = Control.new()
	race_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	race_hud.visible = false
	ui.add_child(race_hud)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 34)
	message_label.add_theme_color_override("font_color", Color("#f5f2ea"))
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-280, 48)
	message_label.size = Vector2(560, 60)
	race_hud.add_child(message_label)

func _clear_menu() -> void:
	for child in menu_root.get_children(): child.queue_free()

func _panel(parent: Control, rect: Rect2, color := Color(0.035, 0.055, 0.085, 0.92)) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = Color("#354354")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)
	return panel

func _label(parent: Control, text: String, pos: Vector2, size: Vector2, font_size := 18, color := Color("#eef2f6"), bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold: label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.5))
	parent.add_child(label)
	return label

func _button(parent: Control, text: String, rect: Rect2, callback: Callable, accent := false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#df563f") if accent else Color("#172433")
	normal.border_color = Color("#ff9b67") if accent else Color("#3d5267")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	var hover := normal.duplicate()
	hover.bg_color = Color("#f27650") if accent else Color("#24374a")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("#fffaf3"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _header(parent: Control, eyebrow: String, title: String, subtitle: String) -> void:
	_label(parent, eyebrow, Vector2(58, 34), Vector2(600, 24), 13, Color("#ff9d73"), true)
	_label(parent, title, Vector2(56, 58), Vector2(850, 58), 36, Color("#f4f3ef"), true)
	_label(parent, subtitle, Vector2(60, 118), Vector2(1000, 30), 15, Color("#aab6c4"))

func _show_home() -> void:
	_clear_menu()
	menu_root.visible = true
	race_hud.visible = false
	var bg := ColorRect.new()
	bg.color = Color("#09121e")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(bg)
	var glow := ColorRect.new()
	glow.position = Vector2(600, 0)
	glow.size = Vector2(680, 720)
	glow.color = Color(0.22, 0.31, 0.43, 0.18)
	menu_root.add_child(glow)
	_header(menu_root, "ANDROID RACING EXPERIENCE  /  SEASON 2026", "ULTIMATE STREET RACERS", "Own the night. Build your legend. Drive the streets.")
	_panel(menu_root, Rect2(56, 190, 520, 440))
	_label(menu_root, "YOUR GARAGE", Vector2(82, 214), Vector2(300, 22), 13, Color("#ff9d73"), true)
	_label(menu_root, CARS[selected_car].name, Vector2(82, 250), Vector2(430, 42), 30, Color("#f3f5f7"), true)
	_label(menu_root, "%s  /  %d KM/H  /  ENGINE %d" % [CARS[selected_car].class, int((CARS[selected_car].speed + engine_level * 3.5) * 3.6), engine_level + 1], Vector2(84, 294), Vector2(420, 26), 14, Color("#aebaca"))
	_draw_car_preview(menu_root, Vector2(320, 420), CARS[selected_car].color)
	_label(menu_root, "◈  %s CR" % _format_credits(credits), Vector2(84, 555), Vector2(220, 34), 20, Color("#f6d58a"), true)
	_button(menu_root, "OPEN GARAGE  →", Rect2(80, 590, 214, 48), _show_garage)
	_panel(menu_root, Rect2(610, 190, 610, 440))
	_label(menu_root, "PICK YOUR NEXT RUN", Vector2(640, 214), Vector2(400, 22), 13, Color("#ff9d73"), true)
	_label(menu_root, "MODE", Vector2(644, 258), Vector2(100, 24), 12, Color("#8292a3"))
	_button(menu_root, "‹  " + MODES[selected_mode] + "  ›", Rect2(640, 282, 255, 46), _cycle_mode)
	_label(menu_root, "LOCATION", Vector2(925, 258), Vector2(120, 24), 12, Color("#8292a3"))
	_button(menu_root, "‹  " + TRACKS[selected_track] + "  ›", Rect2(920, 282, 265, 46), _cycle_track)
	var mode_copy := "3 laps · 5 rivals · earn credits and unlock cars"
	if selected_mode == 2: mode_copy = "Open roads · cruise at your own pace · no finish line"
	if selected_mode == 3: mode_copy = "120-second drift session · link slides · beat your best score"
	if selected_mode == 4: mode_copy = "90-second pursuit · stay ahead of the patrol · survive"
	if selected_mode == 5: mode_copy = "Three rounds · podium points · championship reward"
	if selected_mode == 6: mode_copy = "Online multiplayer is planned for a future update"
	_label(menu_root, mode_copy, Vector2(645, 345), Vector2(545, 38), 14, Color("#b9c3cf"))
	_button(menu_root, "START ENGINE  →", Rect2(642, 407, 540, 66), _start_race, true)
	_button(menu_root, "SETTINGS", Rect2(642, 488, 168, 48), _show_settings)
	_button(menu_root, "CAREER", Rect2(822, 488, 168, 48), _show_career)
	_button(menu_root, "WEATHER: " + ("RAIN" if rainy else "CLEAR"), Rect2(1002, 488, 180, 48), _toggle_weather)
	_label(menu_root, "CAREER  %02d RACES     BEST  %s" % [career_races, _format_time(best_time)], Vector2(646, 563), Vector2(500, 24), 13, Color("#8e9ba8"))
	_label(menu_root, "LANDSCAPE  ·  3D  ·  AUTOSAVE ENABLED", Vector2(646, 596), Vector2(480, 20), 11, Color("#637488"))

func _format_credits(value: int) -> String:
	var digits := str(value)
	var formatted := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length() - i) % 3 == 0:
			formatted += ","
		formatted += digits[i]
	return formatted

func _format_time(value: float) -> String:
	if value <= 0.0: return "--:--.---"
	return "%02d:%02d.%03d" % [int(value / 60.0), int(value) % 60, int((value - floor(value)) * 1000.0)]

func _draw_car_preview(parent: Control, center: Vector2, color_hex: String) -> void:
	var shadow := ColorRect.new()
	shadow.position = center - Vector2(195, -56)
	shadow.size = Vector2(390, 18)
	shadow.color = Color(0, 0, 0, 0.32)
	parent.add_child(shadow)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-186,10),Vector2(-151,-4),Vector2(-98,-12),Vector2(-58,-45),Vector2(45,-45),Vector2(97,-11),Vector2(160,-3),Vector2(188,10),Vector2(179,31),Vector2(-175,31)])
	body.position = center
	body.color = Color(color_hex)
	parent.add_child(body)
	var glass := Polygon2D.new()
	glass.polygon = PackedVector2Array([Vector2(-66,-12),Vector2(-43,-39),Vector2(32,-39),Vector2(75,-12)])
	glass.position = center
	glass.color = Color("#172936")
	parent.add_child(glass)
	for x in [-122, 118]:
		var wheel := ColorRect.new()
		wheel.position = center + Vector2(x - 20, 12)
		wheel.size = Vector2(40, 35)
		wheel.color = Color("#10151d")
		parent.add_child(wheel)

func _show_garage() -> void:
	_clear_menu()
	menu_root.visible = true
	race_hud.visible = false
	var bg := ColorRect.new(); bg.color = Color("#09121e"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(bg)
	_header(menu_root, "VEHICLE WORKSHOP  /  %d MACHINES" % CARS.size(), "THE GARAGE", "Tune your build. Paint your signature. Take it to the street.")
	_panel(menu_root, Rect2(55, 188, 1170, 460))
	_button(menu_root, "‹", Rect2(82, 364, 58, 58), _prev_car)
	_button(menu_root, "›", Rect2(1140, 364, 58, 58), _next_car)
	_draw_car_preview(menu_root, Vector2(640, 345), CARS[selected_car].color if paint_index == 0 else PAINTS[paint_index])
	_label(menu_root, "%02d  /  %02d" % [selected_car + 1, CARS.size()], Vector2(588, 217), Vector2(110, 26), 14, Color("#ff9d73"))
	_label(menu_root, CARS[selected_car].name, Vector2(430, 465), Vector2(420, 42), 28, Color("#f4f3ef"), true)
	var owned_car := owned.has(selected_car)
	var data: Dictionary = CARS[selected_car]
	var top_speed: float = data.speed + engine_level * 3.5
	_label(menu_root, "%s  ·  TOP SPEED %d  ·  ENGINE %d/5" % [data.class, int(top_speed * 3.6), engine_level + 1], Vector2(432, 505), Vector2(470, 24), 14, Color("#aebaca"))
	_label(menu_root, "OWNED" if owned_car else "LOCKED  ·  %s CR" % _format_credits(int(data.price)), Vector2(432, 536), Vector2(350, 24), 14, Color("#8fd4aa") if owned_car else Color("#f4cc7d"))
	_button(menu_root, "BUY VEHICLE", Rect2(80, 570, 210, 48), _buy_car, true if not owned_car else false).visible = not owned_car
	_button(menu_root, "PAINT  ◉", Rect2(326, 570, 174, 48), _cycle_paint, owned_car)
	_button(menu_root, "ENGINE UPGRADE  ·  %s CR" % _format_credits(900 + engine_level * 650), Rect2(514, 570, 290, 48), _upgrade_engine, owned_car and engine_level < 4)
	_button(menu_root, "WHEELS  ·  STYLE %d" % (wheel_style + 1), Rect2(818, 570, 178, 48), _cycle_wheels, owned_car)
	_button(menu_root, "BACK", Rect2(1014, 570, 180, 48), _show_home)

func _show_settings() -> void:
	_clear_menu()
	var bg := ColorRect.new(); bg.color = Color("#09121e"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(bg)
	_header(menu_root, "DEVICE PROFILE  /  PERFORMANCE", "GAME SETTINGS", "Designed for landscape Android phones, from entry-level to flagship.")
	_panel(menu_root, Rect2(76, 195, 1128, 412))
	_label(menu_root, "GRAPHICS PRESET", Vector2(115, 235), Vector2(300, 24), 14, Color("#ff9d73"), true)
	_button(menu_root, "‹  " + ["LOW", "MEDIUM", "HIGH", "ULTRA"][quality] + "  ›", Rect2(112, 274, 280, 58), _cycle_quality)
	_label(menu_root, "FRAME RATE", Vector2(468, 235), Vector2(260, 24), 14, Color("#ff9d73"), true)
	_button(menu_root, "%d FPS  ·  TAP TO CHANGE" % target_fps, Rect2(464, 274, 280, 58), _cycle_fps)
	_label(menu_root, "LIGHTING", Vector2(820, 235), Vector2(200, 24), 14, Color("#ff9d73"), true)
	_button(menu_root, "NIGHT" if night else "DAYLIGHT", Rect2(816, 274, 280, 58), _toggle_night)
	_label(menu_root, "Current profile: %s · %d FPS cap · %s weather" % [["Low", "Medium", "High", "Ultra"][quality], target_fps, "rainy" if rainy else "clear"], Vector2(116, 378), Vector2(700, 26), 16, Color("#d0d6df"))
	_label(menu_root, "High/Ultra settings add scenery detail and richer reflections. Low reduces scene detail for affordable phones. Rain is a visual prototype effect.", Vector2(116, 419), Vector2(940, 50), 14, Color("#8998a9"))
	_button(menu_root, "BACK TO STREET", Rect2(116, 516, 300, 56), _show_home, true)
	_button(menu_root, "TOGGLE WEATHER  ·  " + ("RAIN" if rainy else "CLEAR"), Rect2(442, 516, 300, 56), _toggle_weather)

func _show_career() -> void:
	_clear_menu()
	var bg := ColorRect.new(); bg.color = Color("#09121e"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(bg)
	_header(menu_root, "SEASON 2026  /  DRIVER PROGRESSION", "YOUR CAREER", "Every finish brings you closer to the ultimate street machine.")
	_panel(menu_root, Rect2(76, 195, 1128, 412))
	_label(menu_root, "RACES COMPLETED     %02d" % career_races, Vector2(120, 250), Vector2(460, 45), 26, Color("#f2f1ed"), true)
	_label(menu_root, "GARAGE VALUE         %s CR" % _format_credits(credits), Vector2(120, 316), Vector2(480, 38), 20, Color("#f5d38d"))
	_label(menu_root, "PERSONAL BEST         %s" % _format_time(best_time), Vector2(120, 370), Vector2(480, 38), 20, Color("#f2f1ed"))
	_label(menu_root, "NEXT OBJECTIVE", Vector2(680, 249), Vector2(300, 25), 13, Color("#ff9d73"), true)
	_label(menu_root, "Complete races to earn credits. Unlock any of the %d cars, tune the engine, and build your own stable." % CARS.size(), Vector2(680, 285), Vector2(430, 90), 17, Color("#b9c3cf"))
	_button(menu_root, "START CAREER RACE  →", Rect2(680, 400, 390, 58), func(): selected_mode = 1; _start_race(), true)
	_button(menu_root, "BACK", Rect2(116, 516, 240, 56), _show_home)

func _prev_car() -> void:
	selected_car = (selected_car - 1 + CARS.size()) % CARS.size()
	_show_garage()

func _next_car() -> void:
	selected_car = (selected_car + 1) % CARS.size()
	_show_garage()

func _buy_car() -> void:
	var cost := int(CARS[selected_car].price)
	if not owned.has(selected_car) and credits >= cost:
		credits -= cost
		owned.append(selected_car)
		_save_progress()
	_show_garage()

func _cycle_paint() -> void:
	paint_index = (paint_index + 1) % PAINTS.size()
	_save_progress()
	_show_garage()

func _upgrade_engine() -> void:
	var cost := 900 + engine_level * 650
	if engine_level < 4 and credits >= cost:
		credits -= cost
		engine_level += 1
		_save_progress()
	_show_garage()

func _cycle_wheels() -> void:
	wheel_style = (wheel_style + 1) % 4
	_show_garage()

func _cycle_mode() -> void:
	selected_mode = (selected_mode + 1) % MODES.size()
	_show_home()

func _cycle_track() -> void:
	selected_track = (selected_track + 1) % TRACKS.size()
	_build_track()
	_show_home()

func _cycle_quality() -> void:
	quality = (quality + 1) % 4
	var shadow_distance: float = [70.0, 110.0, 160.0, 220.0][quality]
	for child in get_children():
		if child is DirectionalLight3D:
			child.directional_shadow_max_distance = shadow_distance
	Engine.max_fps = target_fps
	_show_settings()

func _cycle_fps() -> void:
	target_fps = 30 if target_fps == 60 else 60
	Engine.max_fps = target_fps
	_show_settings()

func _toggle_night() -> void:
	night = not night
	for child in get_children():
		if child is WorldEnvironment or child is DirectionalLight3D: child.queue_free()
	_build_environment()
	_build_track()
	_show_settings()

func _toggle_weather() -> void:
	rainy = not rainy
	if menu_root.visible: _show_home()

func _start_race() -> void:
	if selected_mode == 6:
		_show_future()
		return
	for actor in get_tree().get_nodes_in_group("race_cars"):
		actor.queue_free()
	opponents.clear()
	opponent_progress.clear()
	opponent_route_indices.clear()
	elapsed = 0.0
	race_time = 0.0
	drift_score = 0
	race_progress = 0
	route_index = 0
	lap = 1
	laps_total = 1 if selected_mode == 2 or selected_mode == 3 or selected_mode == 4 else 3
	last_drift = false
	countdown_remaining = 3.0
	_build_track()
	var data: Dictionary = CARS[selected_car]
	player = CAR_SCRIPT.new()
	player.name = "PlayerCar"
	player.car_name = data.name
	player.body_style = str(data.get("style", "sport"))
	player.max_speed = float(data.speed) + engine_level * 3.5
	player.acceleration = float(data.accel) + engine_level * 1.8
	player.handling = float(data.handling)
	player.is_player = true
	player.set_paint(Color(data.color if paint_index == 0 else PAINTS[paint_index]))
	player.add_to_group("race_cars")
	add_child(player)
	_place_car(player, 0, 0.0)
	var colors := ["#45a9ca", "#e9b64d", "#a878d0", "#70c28a", "#e47663"]
	for i in range(5):
		var rival: StreetCar = CAR_SCRIPT.new()
		rival.name = "Rival_%d" % (i + 1)
		rival.car_name = ["KAI", "MILA", "REX", "JUNO", "ASH"][i]
		rival.max_speed = float(data.speed) * (0.72 + i * 0.025)
		rival.acceleration = float(data.accel) * 0.84
		rival.handling = float(data.handling) * 0.88
		rival.set_paint(Color(colors[i]))
		rival.add_to_group("race_cars")
		add_child(rival)
		_place_car(rival, 0, float(i + 1) * 2.3 * (-1.0 if i % 2 == 0 else 1.0), -6.0 - float(i / 2) * 4.0)
		opponents.append(rival)
		opponent_progress.append(0)
		opponent_route_indices.append(0)
	_create_camera()
	_build_race_hud()
	menu_root.visible = false
	race_hud.visible = true
	race_hud.move_to_front()
	race_hud.set_process(true)
	racing = true
	race_paused = false
	if rainy: _create_rain()
	if selected_mode == 0 or selected_mode == 1 or selected_mode == 5:
		message_label.text = "3   ·   GET READY"
	else:
		message_label.text = MODES[selected_mode]
	message_label.visible = true

func _show_future() -> void:
	_clear_menu()
	var bg := ColorRect.new(); bg.color = Color("#09121e"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu_root.add_child(bg)
	_header(menu_root, "COMING IN A FUTURE UPDATE", "THE GRID IS GROWING", "Multiplayer matchmaking is planned. The complete local racing prototype is ready now.")
	_panel(menu_root, Rect2(76, 195, 1128, 412))
	_label(menu_root, "ONLINE RACING", Vector2(118, 258), Vector2(400, 40), 27, Color("#f4f3ef"), true)
	_label(menu_root, "Choose any other mode to race against five AI drivers, explore the course, tune your garage, and earn credits.", Vector2(118, 315), Vector2(880, 55), 17, Color("#b9c3cf"))
	_button(menu_root, "BACK TO THE GRID", Rect2(118, 438, 320, 58), _show_home, true)

func _place_car(car: StreetCar, point_index: int, lane: float, behind := 0.0) -> void:
	var index := posmod(point_index, route.size())
	var point: Vector3 = route[index]
	var tangent := (route[(index + 1) % route.size()] - route[(index - 1 + route.size()) % route.size()]).normalized()
	var side := Vector3(-tangent.z, 0, tangent.x)
	car.global_position = point + side * lane - tangent * behind + Vector3.UP * 0.25
	car.rotation.y = atan2(-tangent.x, -tangent.z)

func _create_camera() -> void:
	if is_instance_valid(camera): camera.queue_free()
	camera = Camera3D.new()
	camera.name = "RaceCamera"
	camera.current = true
	camera.fov = 72.0
	camera.near = 0.1
	camera.far = 500.0
	add_child(camera)
	camera.global_position = player.global_position + Vector3(0, 6, 12)
	camera.look_at(player.global_position + Vector3(0, 1, 0), Vector3.UP)

func _build_race_hud() -> void:
	for child in race_hud.get_children():
		if child != message_label: child.queue_free()
	_panel(race_hud, Rect2(24, 20, 250, 94), Color(0.025,0.04,0.07,0.8))
	_label(race_hud, TRACKS[selected_track] + "  /  " + MODES[selected_mode], Vector2(44, 36), Vector2(230, 20), 12, Color("#ff9d73"), true)
	_label(race_hud, "LAP", Vector2(44, 65), Vector2(40, 20), 12, Color("#93a1b2"))
	var lap_label := _label(race_hud, "1 / %d" % laps_total, Vector2(86, 59), Vector2(110, 30), 20, Color("#f2f1ed"), true)
	lap_label.name = "LapLabel"
	var time_label := _label(race_hud, "00:00.000", Vector2(44, 88), Vector2(220, 20), 12, Color("#c0cad5"))
	time_label.name = "TimeLabel"
	var rank_label := _label(race_hud, "1ST / 6", Vector2(1072, 34), Vector2(160, 33), 22, Color("#f1f0ec"), true)
	rank_label.name = "RankLabel"
	_panel(race_hud, Rect2(1020, 20, 232, 95), Color(0.025,0.04,0.07,0.8))
	var sp := _label(race_hud, "000", Vector2(1062, 53), Vector2(110, 48), 36, Color("#f4f3ef"), true)
	sp.name = "SpeedLabel"
	_label(race_hud, "KM/H", Vector2(1164, 69), Vector2(60, 20), 11, Color("#91a0b0"))
	var nitro_title := _label(race_hud, "NITRO", Vector2(1055, 92), Vector2(48, 16), 10, Color("#72d6f1"), true)
	var bar := ProgressBar.new()
	bar.position = Vector2(1100, 93); bar.size = Vector2(128, 12); bar.max_value = 100; bar.value = 100; bar.show_percentage = false
	bar.add_theme_stylebox_override("fill", _bar_style(Color("#5bc9e9")))
	bar.add_theme_stylebox_override("background", _bar_style(Color("#1b2b3a")))
	bar.name = "NitroBar"
	race_hud.add_child(bar)
	for child in race_hud.get_children():
		if child is Label and child.text.begins_with("000"): speed_label = child
	nitro_bar = bar
	var pause := _button(race_hud, "Ⅱ", Rect2(1192, 132, 58, 46), _pause_race)
	pause.add_theme_font_size_override("font_size", 22)
	_add_touch_controls()

func _bar_style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new(); box.bg_color = color; box.set_corner_radius_all(5); return box

func _add_touch_controls() -> void:
	_touch_button("◀", Rect2(24, 0, 92, 82), Vector2(0, 1), Vector2(24, -106), "left")
	_touch_button("▶", Rect2(24, 0, 92, 82), Vector2(0, 1), Vector2(128, -106), "right")
	_touch_button("BRAKE", Rect2(24, 0, 88, 64), Vector2(1, 1), Vector2(-232, -91), "brake")
	_touch_button("DRIFT", Rect2(24, 0, 88, 64), Vector2(1, 1), Vector2(-332, -91), "drift")
	_touch_button("NITRO", Rect2(24, 0, 108, 72), Vector2(1, 1), Vector2(-132, -183), "nitro")
	_touch_button("ACCEL", Rect2(24, 0, 132, 92), Vector2(1, 1), Vector2(-152, -84), "gas", true)

func _touch_button(text: String, rect: Rect2, anchor: Vector2, offset: Vector2, key: String, accent := false) -> void:
	var button := Button.new()
	button.text = text
	button.anchor_left = anchor.x; button.anchor_right = anchor.x
	button.anchor_top = anchor.y; button.anchor_bottom = anchor.y
	button.offset_left = offset.x; button.offset_top = offset.y
	button.offset_right = offset.x + rect.size.x; button.offset_bottom = offset.y + rect.size.y
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16 if not accent else 18)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08,0.12,0.17,0.78) if not accent else Color(0.83,0.27,0.19,0.86)
	sb.border_color = Color(0.64,0.73,0.83,0.45); sb.set_border_width_all(1); sb.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", sb)
	button.add_theme_stylebox_override("pressed", _bar_style(Color(0.28,0.37,0.46,0.9)))
	button.button_down.connect(func(): touch_values[key] = true)
	button.button_up.connect(func(): touch_values[key] = false)
	race_hud.add_child(button)

func _pause_race() -> void:
	if not racing or race_paused: return
	race_paused = true
	for child in race_hud.get_children():
		if child.name == "PauseOverlay": child.queue_free()
	var shade := ColorRect.new(); shade.name = "PauseOverlay"; shade.color = Color(0.01,0.02,0.04,0.78); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); race_hud.add_child(shade)
	_panel(race_hud, Rect2(390, 205, 500, 300), Color(0.035,0.055,0.085,0.98))
	_label(race_hud, "RACE PAUSED", Vector2(454, 246), Vector2(360, 48), 30, Color("#f3f2ef"), true)
	_button(race_hud, "RESUME DRIVE", Rect2(460, 326, 350, 54), _resume_race, true)
	_button(race_hud, "QUIT TO GARAGE", Rect2(460, 395, 350, 48), _quit_race)

func _resume_race() -> void:
	race_paused = false
	for child in race_hud.get_children():
		if child.name == "PauseOverlay" or child is Panel and child.position == Vector2(390,205): child.queue_free()
		elif child is Label and child.position == Vector2(454,246): child.queue_free()
		elif child is Button and (child.text == "RESUME DRIVE" or child.text == "QUIT TO GARAGE"): child.queue_free()

func _quit_race() -> void:
	race_paused = false
	_race_cleanup()
	_show_home()

func _race_cleanup() -> void:
	racing = false
	race_paused = false
	for actor in get_tree().get_nodes_in_group("race_cars"): actor.queue_free()
	if is_instance_valid(camera): camera.queue_free()
	if is_instance_valid(rain_particles): rain_particles.queue_free()
	rain_particles = null
	for key in touch_values.keys(): touch_values[key] = false

func _process(delta: float) -> void:
	if not racing: return
	if race_paused:
		if is_instance_valid(player):
			player.throttle = 0.0; player.steer = 0.0; player.braking = true; player.using_nitro = false
		for rival in opponents:
			if is_instance_valid(rival):
				rival.throttle = 0.0; rival.steer = 0.0; rival.braking = true; rival.using_nitro = false
		return
	elapsed += delta
	if countdown_remaining > 0.0:
		countdown_remaining = maxf(0.0, countdown_remaining - delta)
		message_label.text = "3   ·   GET READY" if countdown_remaining > 1.8 else ("2   ·   GET READY" if countdown_remaining > 0.8 else "1   ·   GET READY")
		player.throttle = 0.0; player.steer = 0.0; player.braking = true
		for rival in opponents:
			rival.throttle = 0.0; rival.steer = 0.0; rival.braking = true
		return
	if message_label.visible and message_label.text.contains("GET READY"):
		message_label.text = "GO!"
		message_label.visible = true
	if elapsed > 3.5 and message_label.text == "GO!":
		message_label.visible = false
	race_time += delta
	var steer_input := float(touch_values.left) * -1.0 + float(touch_values.right)
	var gas_input := float(touch_values.gas)
	var brake_input := bool(touch_values.brake)
	var nitro_input := bool(touch_values.nitro)
	var drift_input := bool(touch_values.drift)
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): steer_input -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): steer_input += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): gas_input = 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): brake_input = true
	if Input.is_key_pressed(KEY_SPACE): drift_input = true
	if Input.is_key_pressed(KEY_SHIFT): nitro_input = true
	player.throttle = gas_input
	player.steer = clampf(steer_input, -1.0, 1.0)
	player.braking = brake_input
	player.drifting = drift_input
	player.using_nitro = nitro_input
	if player.speed > 13.0 and drift_input and absf(steer_input) > 0.25:
		drift_score += int(delta * absf(steer_input) * player.speed * 0.9)
	if player.speed < 4.0: drift_score = maxi(0, drift_score - 1)
	_update_ai(delta)
	_update_camera(delta)
	_update_race_progress(delta)
	_update_hud()
	if selected_mode == 2 and int(race_time) > 0 and int(race_time) % 70 == 0 and int(race_time - delta) % 70 != 0:
		credits += 75
		_save_progress()
		message_label.text = "+75 CR  ·  OPEN ROAD BONUS"
		message_label.visible = true
	elif elapsed > 1.7 and message_label.text.contains("GET READY"):
		message_label.visible = false
	if selected_mode == 3 and race_time >= DRIFT_CHALLENGE_SECONDS:
		_finish_race()
	elif selected_mode == 4 and race_time >= POLICE_CHASE_SECONDS:
		_finish_race()
	elif selected_mode != 2 and selected_mode != 3 and selected_mode != 4 and laps_total > 0 and race_progress >= route.size() * laps_total:
		_finish_race()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not event.echo and racing:
		if race_paused:
			_resume_race()
		else:
			_pause_race()

func _update_ai(delta: float) -> void:
	for i in range(opponents.size()):
		var rival := opponents[i]
		if not is_instance_valid(rival): continue
		var nearest := _nearest_route_point(rival.global_position)
		var previous: int = opponent_route_indices[i]
		var step: int = (nearest - previous + route.size()) % route.size()
		if step < route.size() / 4:
			opponent_progress[i] += step
		elif step > route.size() * 3 / 4:
			opponent_progress[i] = maxi(0, opponent_progress[i] - (route.size() - step))
		opponent_route_indices[i] = nearest
		var target: Vector3
		if selected_mode == 4 and i == 0:
			target = player.global_position
		else:
			var target_i := posmod(nearest + 6, route.size())
			var tangent := (route[(target_i + 1) % route.size()] - route[(target_i - 1 + route.size()) % route.size()]).normalized()
			var side := Vector3(-tangent.z, 0, tangent.x)
			target = route[target_i] + side * float(i - 2) * 1.35
		var direction := (target - rival.global_position).normalized()
		var forward := -rival.global_transform.basis.z
		var angle := forward.signed_angle_to(direction, Vector3.UP)
		rival.steer = clampf(angle * 2.3, -1.0, 1.0)
		rival.throttle = 1.0
		rival.braking = absf(angle) > 0.95 and rival.speed > 20.0
		rival.drifting = absf(angle) > 0.45
		rival.using_nitro = rival.speed < rival.max_speed * 0.7 and i == 0
		if selected_mode == 4 and i == 0:
			rival.using_nitro = rival.global_position.distance_to(player.global_position) > 20.0

func _nearest_route_point(position: Vector3) -> int:
	var best := 0
	var best_distance := INF
	for i in range(route.size()):
		var d := Vector2(position.x - route[i].x, position.z - route[i].z).length_squared()
		if d < best_distance:
			best_distance = d
			best = i
	return best

func _update_camera(delta: float) -> void:
	var forward := -player.global_transform.basis.z
	var target_position := player.global_position - forward * 11.0 + Vector3.UP * 5.2
	camera.global_position = camera.global_position.lerp(target_position, 1.0 - exp(-5.5 * delta))
	camera.look_at(player.global_position + forward * 5.0 + Vector3.UP * 1.0, Vector3.UP)

func _update_race_progress(_delta: float) -> void:
	var nearest := _nearest_route_point(player.global_position)
	var step := (nearest - route_index + route.size()) % route.size()
	if step < route.size() / 4:
		race_progress += step
	elif step > route.size() * 3 / 4:
		race_progress = maxi(0, race_progress - (route.size() - step))
	route_index = nearest
	lap = mini(laps_total, int(race_progress / route.size()) + 1)
	if selected_mode == 2:
		race_progress = maxi(race_progress, nearest)
		lap = 1

func _update_hud() -> void:
	var lap_label := race_hud.find_child("LapLabel", true, false) as Label
	var time_label := race_hud.find_child("TimeLabel", true, false) as Label
	var rank_label := race_hud.find_child("RankLabel", true, false) as Label
	var speed := race_hud.find_child("SpeedLabel", true, false) as Label
	if is_instance_valid(lap_label):
		if selected_mode == 2: lap_label.text = "OPEN"
		elif selected_mode == 3: lap_label.text = "DRIFT"
		else: lap_label.text = "%d / %d" % [lap, laps_total]
	if is_instance_valid(time_label):
		if selected_mode == 3:
			time_label.text = "%s LEFT   ·   %d PTS" % [_format_time(maxf(0.0, DRIFT_CHALLENGE_SECONDS - race_time)), drift_score]
		elif selected_mode == 4:
			time_label.text = "%s LEFT" % _format_time(maxf(0.0, POLICE_CHASE_SECONDS - race_time))
		else:
			time_label.text = _format_time(race_time)
	if is_instance_valid(speed): speed.text = "%03d" % int(absf(player.speed) * 3.6)
	if is_instance_valid(rank_label): rank_label.text = "%s  /  6" % _player_rank()
	if is_instance_valid(nitro_bar): nitro_bar.value = player.nitro

func _player_rank() -> String:
	var ahead := 0
	for progress in opponent_progress:
		if progress > race_progress: ahead += 1
	return ["1ST", "2ND", "3RD", "4TH", "5TH", "6TH"][clampi(ahead, 0, 5)]

func _create_rain() -> void:
	if is_instance_valid(rain_particles): rain_particles.queue_free()
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 1400 if quality >= 2 else 600
	rain_particles.lifetime = 1.4
	rain_particles.visibility_aabb = AABB(Vector3(-35, -2, -35), Vector3(70, 32, 70))
	var particle_mesh := BoxMesh.new()
	particle_mesh.size = Vector3(0.025, 0.32, 0.025)
	var rain_material := _mat(Color(0.68, 0.82, 0.96, 0.68), 0.0, 0.25)
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_mesh.material = rain_material
	rain_particles.draw_pass_1 = particle_mesh
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.08, -1.0, 0.0)
	process_material.spread = 8.0
	process_material.initial_velocity_min = 22.0
	process_material.initial_velocity_max = 31.0
	process_material.gravity = Vector3(0.0, -9.8, 0.0)
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(28.0, 12.0, 28.0)
	rain_particles.process_material = process_material
	rain_particles.position = Vector3(0.0, 10.0, 0.0)
	add_child(rain_particles)
	rain_particles.emitting = true

func _finish_race() -> void:
	if not racing: return
	racing = false
	var rank := 1
	for progress in opponent_progress:
		if progress > race_progress: rank += 1
	var reward := 350 + maxi(0, 6 - rank) * 150
	if selected_mode == 3: reward += drift_score / 25
	if selected_mode == 5:
		tournament_round += 1
		reward += 250
	credits += reward
	career_races += 1
	if best_time <= 0.0 or race_time < best_time: best_time = race_time
	_save_progress()
	for key in touch_values.keys(): touch_values[key] = false
	for actor in get_tree().get_nodes_in_group("race_cars"):
		if is_instance_valid(actor):
			actor.throttle = 0.0; actor.steer = 0.0; actor.braking = true; actor.using_nitro = false
	var shade := ColorRect.new()
	shade.name = "ResultsShade"
	shade.color = Color(0.01, 0.02, 0.04, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	race_hud.add_child(shade)
	_panel(race_hud, Rect2(360, 165, 560, 390), Color(0.035, 0.055, 0.085, 0.98))
	var result_title := "FINISH  /  %s" % ["1ST", "2ND", "3RD", "4TH", "5TH", "6TH"][clampi(rank - 1, 0, 5)]
	if selected_mode == 3: result_title = "DRIFT SESSION COMPLETE"
	elif selected_mode == 4: result_title = "PURSUIT SURVIVED"
	_label(race_hud, result_title, Vector2(430, 205), Vector2(430, 48), 30, Color("#f4f3ef"), true)
	_label(race_hud, "TIME    %s\nREWARD    +%s CR\nDRIFT SCORE    %d" % [_format_time(race_time), _format_credits(reward), drift_score], Vector2(432, 280), Vector2(420, 120), 20, Color("#c4cfda"))
	_button(race_hud, "RETURN TO GARAGE", Rect2(438, 457, 400, 56), _quit_race, true)
