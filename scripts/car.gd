extends CharacterBody3D
class_name StreetCar

var car_name := "Vortex GT"
var body_style := "sport"
var paint := Color("#d94c43")
var max_speed := 64.0
var acceleration := 25.0
var handling := 1.0
var nitro_capacity := 100.0
var nitro := 100.0
var throttle := 0.0
var steer := 0.0
var braking := false
var drifting := false
var using_nitro := false
var speed := 0.0
var is_player := false
var wheel_nodes: Array[MeshInstance3D] = []
var body_mesh: MeshInstance3D

func _ready() -> void:
	_build_car()
	floor_snap_length = 1.0
	floor_max_angle = deg_to_rad(50)
	collision_layer = 2
	collision_mask = 1 | 2

func _build_car() -> void:
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.05, 1.05, 4.5)
	collider.shape = shape
	collider.position.y = 0.72
	add_child(collider)
	var body_size := Vector3(1.95, 0.72, 4.2)
	var cabin_size := Vector3(1.48, 0.62, 1.9)
	var cabin_position := Vector3(0, 1.43, -0.25)
	if body_style == "wedge":
		body_size = Vector3(1.98, 0.62, 4.3)
		cabin_size = Vector3(1.42, 0.49, 1.72)
		cabin_position = Vector3(0, 1.35, -0.18)
	elif body_style == "gt":
		body_size = Vector3(1.97, 0.76, 4.35)
		cabin_size = Vector3(1.55, 0.65, 1.96)
		cabin_position = Vector3(0, 1.46, 0.0)
	elif body_style == "muscle":
		body_size = Vector3(2.0, 0.82, 4.28)
		cabin_size = Vector3(1.58, 0.66, 1.78)
		cabin_position = Vector3(0, 1.5, 0.08)
	body_mesh = _box(body_size, Vector3(0, 0.8, 0), paint, 0.3)
	_box(cabin_size, cabin_position, Color("#a8c9d5"), 0.12, 0.32)
	_box(Vector3(1.86, 0.12, 0.5), Vector3(0, 1.0, -1.75), Color("#f5f3ed"), 0.3)
	_box(Vector3(1.78, 0.16, 0.48), Vector3(0, 0.96, 1.82), Color("#e65348"), 0.25)
	_box(Vector3(1.55, 0.12, 0.14), Vector3(0, 1.6, 0.85), Color("#252a31"), 0.2)
	if body_style == "wedge":
		_box(Vector3(1.72, 0.08, 0.28), Vector3(0, 1.05, 2.12), Color("#242a32"), 0.35)
	elif body_style == "muscle":
		_box(Vector3(0.62, 0.14, 0.72), Vector3(0, 1.23, -1.0), Color("#303640"), 0.35)
	for x in [-1.0, 1.0]:
		for z in [-1.42, 1.42]:
			var wheel := _cylinder(0.43, 0.28, Vector3(x, 0.43, z), Color("#161a20"))
			wheel.rotation.z = PI / 2
			wheel_nodes.append(wheel)
			var hub := _cylinder(0.2, 0.29, Vector3(x * 1.005, 0.43, z), Color("#a9b5c3"))
			hub.rotation.z = PI / 2
	# Headlamps and signature side accent
	for x in [-0.62, 0.62]:
		_box(Vector3(0.38, 0.12, 0.09), Vector3(x, 0.95, -2.12), Color("#dff7ff"), 0.1, 0.8)
		_box(Vector3(0.35, 0.13, 0.08), Vector3(x, 0.91, 2.12), Color("#ff453d"), 0.1, 0.6)

func _physics_process(delta: float) -> void:
	var forward := -global_transform.basis.z
	var grounded := is_on_floor()
	var accel := acceleration * (1.0 if grounded else 0.38)
	if throttle > 0.0:
		speed = move_toward(speed, max_speed, accel * throttle * delta)
	elif throttle < 0.0:
		speed = move_toward(speed, -max_speed * 0.25, accel * 0.65 * -throttle * delta)
	else:
		speed = move_toward(speed, 0.0, (3.4 if drifting else 5.2) * delta)
	if braking:
		speed = move_toward(speed, 0.0, 36.0 * delta)
	if using_nitro and nitro > 0.0 and throttle > 0.0:
		speed = minf(speed + 24.0 * delta, max_speed * 1.26)
		nitro = maxf(0.0, nitro - 31.0 * delta)
	else:
		nitro = minf(100.0, nitro + 9.0 * delta)
	var speed_ratio := clampf(absf(speed) / max_speed, 0.0, 1.2)
	var turn_rate := (1.45 if drifting else 1.12) * handling
	if absf(speed) > 0.4:
		rotation.y += steer * turn_rate * (0.32 + speed_ratio * 0.9) * delta * signf(speed)
	var side_velocity := velocity - forward * velocity.dot(forward)
	var grip := 2.4 if drifting else 9.5
	velocity = forward * speed + side_velocity * exp(-grip * delta)
	if not grounded:
		velocity.y -= 20.0 * delta
	else:
		velocity.y = -0.5
	move_and_slide()
	if get_slide_collision_count() > 0:
		speed *= 0.82
	for wheel in wheel_nodes:
		wheel.rotate_x(-speed * delta * 0.7)

func _box(size: Vector3, pos: Vector3, color: Color, metallic := 0.2, roughness := 0.35) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.65
	node.material_override = mat
	add_child(node)
	if pos.y > 0.7 and size.z > 3.0:
		body_mesh = node
	return node

func _cylinder(radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.72
	mat.roughness = 0.24
	node.material_override = mat
	add_child(node)
	return node

func set_paint(color: Color) -> void:
	paint = color
	if is_instance_valid(body_mesh):
		var mat := body_mesh.material_override as StandardMaterial3D
		mat.albedo_color = color
