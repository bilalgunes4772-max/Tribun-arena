extends Node3D
## Procedural low-poly stadium and animated footballer visuals.
## Designed for Godot 4.4 Compatibility renderer and offline mobile play.

const FIELD_X := 50.0
const FIELD_Z := 30.0
var footballers: Array[Node3D] = []
var ball_mesh: Node3D
var view: Camera3D
var field_lights: Array[OmniLight3D] = []
var rng := RandomNumberGenerator.new()
var home_color := Color("#f0f4ff")
var away_color := Color("#ea526f")
var gold := Color("#f9cb69")

func _ready() -> void:
	rng.seed = 1903
	build_ground()
	build_stadium()
	build_goals()
	build_lighting()
	make_ball()
	make_camera()

func mat(c: Color, rough: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metallic
	return m

func block(name: String, size: Vector3, pos: Vector3, color: Color, owner_node: Node3D = self) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	inst.mesh = mesh
	inst.material_override = mat(color)
	owner_node.add_child(inst)
	inst.position = pos
	return inst

func orb(size: float, pos: Vector3, color: Color, owner_node: Node3D = self) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	inst.mesh = mesh
	inst.material_override = mat(color)
	owner_node.add_child(inst)
	inst.position = pos
	return inst

func bar(a: Vector3, b: Vector3, radius: float, color: Color, owner_node: Node3D = self) -> MeshInstance3D:
	var delta := b-a
	var length := delta.length()
	var inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 8
	inst.mesh = mesh
	inst.material_override = mat(color)
	owner_node.add_child(inst)
	inst.position = (a+b)*0.5
	inst.quaternion = Quaternion(Vector3.UP,delta.normalized())
	return inst

func line(a: Vector2, b: Vector2, width: float = 0.16) -> void:
	var start := Vector3(a.x,0.065,a.y)
	var ending := Vector3(b.x,0.065,b.y)
	var mid := (start+ending)*0.5
	var vec := ending-start
	var inst := block("Pitch marking",Vector3(vec.length(),0.022,width),mid,Color("#f1f6ec"))
	inst.rotation.y = -atan2(vec.z,vec.x)

func arc(center: Vector2, radius: float, start_angle: float = 0.0, end_angle: float = TAU) -> void:
	var segments := 48
	for i in range(segments):
		var a := lerpf(start_angle,end_angle,float(i)/segments)
		var b := lerpf(start_angle,end_angle,float(i+1)/segments)
		line(center+Vector2(cos(a),sin(a))*radius,center+Vector2(cos(b),sin(b))*radius,0.13)

func build_ground() -> void:
	block("Terrain",Vector3(180,1,142),Vector3(0,-0.57,0),Color("#172a2b"))
	block("Track",Vector3(119,0.08,83),Vector3(0,-0.02,0),Color("#263b35"))
	block("Pitch",Vector3(100,0.12,60),Vector3(0,0,0),Color("#246743"))
	for i in range(10):
		if i%2==0:
			block("Grass stripe",Vector3(10,0.008,60),Vector3(-45+i*10,0.068,0),Color("#2d7d4e"))
	for i in range(-4,5):
		block("Grass micro-pattern",Vector3(100,0.005,0.08),Vector3(0,0.073,float(i)*6.0),Color(0.4,0.75,0.5,0.14))
	line(Vector2(-50,-30),Vector2(50,-30))
	line(Vector2(50,-30),Vector2(50,30))
	line(Vector2(50,30),Vector2(-50,30))
	line(Vector2(-50,30),Vector2(-50,-30))
	line(Vector2(0,-30),Vector2(0,30))
	arc(Vector2.ZERO,9.15)
	for side in [-1.0,1.0]:
		var outer_x: float = side*50.0
		var inner_x: float = side*33.5
		line(Vector2(outer_x,-20.16),Vector2(inner_x,-20.16))
		line(Vector2(inner_x,-20.16),Vector2(inner_x,20.16))
		line(Vector2(inner_x,20.16),Vector2(outer_x,20.16))
		var gx: float = side*44.5
		line(Vector2(outer_x,-9.1),Vector2(gx,-9.1))
		line(Vector2(gx,-9.1),Vector2(gx,9.1))
		line(Vector2(gx,9.1),Vector2(outer_x,9.1))
		orb(0.22,Vector3(side*39.0,0.13,0),Color.WHITE)
	arc(Vector2.ZERO,0.3)

func build_goals() -> void:
	for side in [-1.0,1.0]:
		var near_x: float = side*50.0
		var far_x: float = side*53.0
		var left_z := -5.1
		var right_z := 5.1
		var white := Color("#f4f6f8")
		bar(Vector3(near_x,0,left_z),Vector3(near_x,2.65,left_z),0.105,white)
		bar(Vector3(near_x,0,right_z),Vector3(near_x,2.65,right_z),0.105,white)
		bar(Vector3(near_x,2.65,left_z),Vector3(near_x,2.65,right_z),0.11,white)
		bar(Vector3(near_x,2.65,left_z),Vector3(far_x,2.3,left_z),0.055,white)
		bar(Vector3(near_x,2.65,right_z),Vector3(far_x,2.3,right_z),0.055,white)
		bar(Vector3(far_x,2.3,left_z),Vector3(far_x,2.3,right_z),0.045,white)
		for i in range(13):
			var z := left_z+float(i)*0.85
			bar(Vector3(far_x,0,z),Vector3(far_x,2.3,z),0.018,Color(0.88,0.94,1.0,0.8))
			bar(Vector3(near_x,2.65,z),Vector3(far_x,2.3,z),0.015,Color("#a5caca"))
		for j in range(5):
			var y := float(j)*0.57
			bar(Vector3(far_x,y,left_z),Vector3(far_x,y,right_z),0.018,Color("#b0d4d3"))
		block("Goal ground",Vector3(2.8,0.02,10.4),Vector3(side*51.5,-0.005,0),Color("#e2e7dd"))

func build_stadium() -> void:
	var concrete := Color("#111b29")
	var fascia := Color("#253449")
	var seats := [Color("#0e5365"),Color("#f6c56b"),Color("#172b42"),Color("#cd5367"),Color("#b7d8db")]
	for side in [-1,1]:
		for tier in range(5):
			var z := float(side)*(38.0+tier*3.5)
			block("Tribune seating",Vector3(133,1.0,3.3),Vector3(0,2.5+tier*2.3,z),concrete)
			block("Seat color band",Vector3(129,0.15,2.6),Vector3(0,3.06+tier*2.3,z),seats[tier%seats.size()])
		for tier in range(5):
			var x := float(side)*(61.0+tier*2.2)
			block("End stand",Vector3(2.3,1.0,94),Vector3(x,2.6+tier*2.2,0),fascia)
	for side in [-1,1]:
		for zside in [-1,1]:
			var x := float(side)*58.0
			var z := float(zside)*35.0
			block("Corner pillar",Vector3(2.0,17.0,2.0),Vector3(x,8.5,z),Color("#1b2934"))
			block("Floodlight top",Vector3(10,1.1,2),Vector3(x,17.7,z),Color("#ecf4ed"))
			for j in range(5):
				block("Light segment",Vector3(1.55,0.65,0.2),Vector3(x-3.7+j*1.9,17.8,z-1.15),Color("#fdfbd8"))
	# Illuminated ad boards and architectural trim
	for side in [-1,1]:
		for i in range(10):
			var x := -49.5+float(i)*11.0
			block("LED sideline",Vector3(10.6,0.9,0.23),Vector3(x,0.48,float(side)*32.0),Color("#132e41") if i%2==0 else Color("#e0bd74"))
	for side in [-1,1]:
		for i in range(5):
			var z := -25.0+float(i)*12.5
			block("LED goal line",Vector3(0.25,0.9,12),Vector3(float(side)*55.0,0.48,z),Color("#bcd6d4"))
	build_crowd()
	block("North skybox wall",Vector3(180,9,0.8),Vector3(0,16,-63),Color("#0c192a"))
	block("South skybox wall",Vector3(180,9,0.8),Vector3(0,16,63),Color("#0c192a"))

func build_crowd() -> void:
	var crowd_mesh := BoxMesh.new()
	crowd_mesh.size = Vector3(0.5,0.7,0.45)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = crowd_mesh
	mm.instance_count = 1650
	var color_pal := [Color("#d1e2e3"),Color("#e4ac5a"),Color("#3889a2"),Color("#a12e51"),Color("#e8f3f7"),Color("#22354b")]
	for i in range(mm.instance_count):
		var is_side := i<1300
		var p := Vector3.ZERO
		if is_side:
			var k := int(i/2)
			var side := -1.0 if i%2==0 else 1.0
			var tier := k%5
			p = Vector3(rng.randf_range(-63,63),3.68+float(tier)*2.3,side*(38.0+float(tier)*3.5))
		else:
			var side := -1.0 if i%2==0 else 1.0
			var tier := i%4
			p = Vector3(side*(61.0+float(tier)*2.2),3.8+float(tier)*2.2,rng.randf_range(-43,43))
		mm.set_instance_transform(i,Transform3D(Basis().scaled(Vector3(0.8,rng.randf_range(0.8,1.4),0.8)),p))
		mm.set_instance_color(i,color_pal[rng.randi_range(0,color_pal.size()-1)])
	var audience := MultiMeshInstance3D.new()
	audience.name = "Crowd of 1650"
	audience.multimesh = mm
	var crowd_mat := StandardMaterial3D.new()
	crowd_mat.vertex_color_use_as_albedo = true
	crowd_mat.roughness = 1.0
	audience.material_override = crowd_mat
	add_child(audience)

func build_lighting() -> void:
	var environment := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color("#102338")
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color("#9cb0c6")
	sky.ambient_light_energy = 0.9
	sky.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.environment = sky
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-57,-22,0)
	sun.light_color = Color("#e6eaff")
	sun.light_energy = 1.3
	sun.shadow_enabled = false
	add_child(sun)
	for x in [-51.0,51.0]:
		for z in [-39.0,39.0]:
			var light := OmniLight3D.new()
			light.position = Vector3(x,20,z)
			light.omni_range = 64
			light.light_energy = 1.0
			light.light_color = Color("#e4efff")
			light.shadow_enabled = false
			add_child(light)
			field_lights.append(light)

func make_ball() -> void:
	ball_mesh = Node3D.new()
	ball_mesh.name = "Ball"
	add_child(ball_mesh)
	orb(0.44,Vector3.ZERO,Color("#f6f6f0"),ball_mesh)
	for i in range(6):
		var angle := float(i)*TAU/6.0
		var patch := orb(0.16,Vector3(sin(angle)*0.39,cos(angle)*0.22,cos(angle)*0.32),Color("#1c2734"),ball_mesh)
		patch.scale = Vector3(0.8,0.36,0.8)
	ball_mesh.position = Vector3(0,0.5,0)

func make_camera() -> void:
	view = Camera3D.new()
	view.name = "Broadcast Camera"
	view.projection = Camera3D.PROJECTION_ORTHOGONAL
	view.size = 83.0
	view.near = 0.1
	view.far = 350.0
	view.position = Vector3(0,76,63)
	add_child(view)
	view.look_at(Vector3(0,0,0),Vector3.UP)
	view.current = true

func create_footballer(team: int, number: int) -> Node3D:
	var root := Node3D.new()
	root.name = ("Home_" if team==0 else "Away_")+str(number)
	add_child(root)
	var kit := home_color if team==0 else away_color
	var shorts := Color("#121e38") if team==0 else Color("#faf2e6")
	var sock := Color("#e7eaf2") if team==0 else away_color
	var body := block("Jersey",Vector3(0.90,1.1,0.51),Vector3(0,1.55,0),kit,root)
	body.rotation.z = 0.03
	block("Collar",Vector3(0.34,0.08,0.55),Vector3(0,2.14,0),gold if team==0 else Color("#ffffff"),root)
	block("Shorts",Vector3(0.84,0.43,0.56),Vector3(0,0.91,0),shorts,root)
	orb(0.31,Vector3(0,2.41,0),Color("#dbad87"),root)
	var hair := orb(0.31,Vector3(0,2.57,-0.05),Color("#25242a"),root)
	hair.scale = Vector3(1.05,0.46,0.95)
	for side in [-1.0,1.0]:
		var sleeve := block("Sleeve",Vector3(0.30,0.36,0.45),Vector3(side*0.61,1.95,0),kit,root)
		sleeve.rotation.z = side*0.2
		var arm := block("Arm",Vector3(0.22,0.74,0.23),Vector3(side*0.68,1.43,0),Color("#daa77d"),root)
		arm.name = "Arm"+str(int(side))
		var leg := Node3D.new()
		leg.name = "Leg"+str(int(side))
		leg.position = Vector3(side*0.25,0.74,0)
		root.add_child(leg)
		block("Sock",Vector3(0.26,0.70,0.29),Vector3(0,-0.33,0),sock,leg)
		block("Boot",Vector3(0.30,0.18,0.57),Vector3(0,-0.69,-0.11),Color("#111827") if team==0 else Color("#ffe174"),leg)
	var ring := MeshInstance3D.new()
	ring.name = "Selection ring"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.96
	cyl.bottom_radius = 0.96
	cyl.height = 0.045
	cyl.radial_segments = 26
	ring.mesh = cyl
	ring.material_override = mat(Color("#fbd365"))
	ring.position.y = 0.09
	root.add_child(ring)
	ring.visible = false
	footballers.append(root)
	return root

func update_visuals(actors: Array[Dictionary], ball_pos: Vector3, selected: int, dt: float, clock: float) -> void:
	for i in range(mini(footballers.size(),actors.size())):
		var data: Dictionary = actors[i]
		var node := footballers[i]
		var target: Vector2 = data["pos"] as Vector2
		var last := node.position
		node.position = Vector3(target.x,0,target.y)
		var moved := node.position-last
		if moved.length_squared()>0.005:
			node.rotation.y = lerp_angle(node.rotation.y,atan2(-moved.x,-moved.z),minf(1.0,dt*9.0))
		var animate := minf(1.0,moved.length()/maxf(dt,0.001)/7.0)
		var gait := sin(clock*12.0+float(i))*0.65*animate
		node.get_node("Leg-1").rotation.x = gait
		node.get_node("Leg1").rotation.x = -gait
		node.get_node("Arm-1").rotation.x = -gait*0.6
		node.get_node("Arm1").rotation.x = gait*0.6
		node.get_node("Selection ring").visible = i==selected
	if ball_mesh != null:
		ball_mesh.position = ball_pos
		ball_mesh.rotate_z(dt*3.0)
		ball_mesh.rotate_x(dt*1.2)

func aim_camera(ball_pos: Vector3, dt: float, is_match: bool) -> void:
	if view == null: return
	var target_x := clampf(ball_pos.x*0.19,-8.5,8.5) if is_match else 0.0
	var wanted := Vector3(target_x,76,63)
	view.position = view.position.lerp(wanted,minf(1.0,dt*2.1))
	view.look_at(Vector3(target_x,0,0),Vector3.UP)
