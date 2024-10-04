extends Node
class_name SystemHandler

# SYSTEM LIST #
var star_systems = {}
@export var chosen_system: String = "11 Com"

var root: Node3D = Node3D.new()

# THREADS #
var loading_thread: Thread

# MATERIALS #
var star_shader = preload("res://Materials/StarShader.tres")

func ra_dec_to_xyz(ra: float, dec: float, dist: float):
	var ra_rad = deg_to_rad(ra * 15)
	var dec_rad = deg_to_rad(dec)
	var array = []
	array.append(dist * cos(dec_rad) * cos(ra_rad))
	array.append(dist * cos(dec_rad) * sin(ra_rad))
	array.append(dist * sin(dec_rad))
	return array

func _ready():
	loading_thread = Thread.new()
	loading_thread.start(_start_systems)
	loading_thread.wait_to_finish()
	
	root.name = "StarSystems"
	add_child(root)
	
	_change_system("24 Sex")

func _change_system(new_system: String):
	chosen_system = new_system
	
	for system in root.get_children():
		root.remove_child(system)
		system.queue_free()
		
	var system_node: Node3D = Node3D.new()
	system_node.name = chosen_system
	root.add_child(system_node)
	
	var system_bodies: Dictionary = star_systems.get(chosen_system)
	for body_name in system_bodies:
		var base_body: Node3D = system_bodies[body_name]
		var body = base_body.duplicate()
		system_node.add_child(body)
		
		$Camera3D.global_position = body.transform.origin
		$Camera3D.global_position.z += 5
		$Camera3D.look_at(body.transform.origin)

func _start_systems():
	var stars = preload("res://Data/StarData.csv")
	var data = preload("res://Data/ExoplanetData.csv")
	
	for star in stars.records:
		var system: Dictionary = star_systems.get_or_add(star.sy_name, {})
		
		if not star_systems.get(star.sy_name).get(star.hostname):
			var coords = ra_dec_to_xyz(float(star.ra), float(star.dec), float(star.sy_dist));
			
			var star_node = Node3D.new()
			star_node.name = star.hostname
			
			var mesh: MeshInstance3D = MeshInstance3D.new()
			mesh.mesh = SphereMesh.new()
			star_node.add_child(mesh)
			
			var star_material: ShaderMaterial = ShaderMaterial.new()
			star_material.shader = star_shader
			
			var star_color: Color = Color("EDEFCA")
			
			if star.st_spectype.containsn("M"):
				star_color = Color("DD1821")
			elif star.st_spectype.containsn("K"):
				star_color = Color("E75814")
			elif star.st_spectype.containsn("G"):
				star_color = Color("DFDD90")
			elif star.st_spectype.containsn("F"):
				star_color = Color("ECEEC9")
			elif star.st_spectype.containsn("A"):
				star_color = Color("F9F9F9")
			elif star.st_spectype.containsn("B"):
				star_color = Color("A1B0D9")
			elif star.st_spectype.containsn("O"):
				star_color = Color("3F2481")
			
			star_material.set_shader_parameter("StarColor", star_color)
			mesh.mesh.surface_set_material(0, star_material)
			
			var flicker_particle: GPUParticles3D = load("res://Resources/StarFlicker.tscn").instantiate()
			var process_material: ParticleProcessMaterial = flicker_particle.process_material
			process_material.color = star_color
			star_node.add_child(flicker_particle)
			
			system[star.hostname] = star_node
			star_node.transform.origin = Vector3(coords[0], coords[1], coords[2])
	
	#for planet in data.records:
		#if root.find_child(planet.hostname):
			#var star: Node3D = root.find_child(planet.hostname)
			#
			#var coords = ra_dec_to_xyz(float(planet.ra), float(planet.dec), float(planet.sy_dist));
			#
			#var shape = Node3D.new()
			#shape.name = planet.pl_name
			#
			#var mesh = MeshInstance3D.new()
			#mesh.mesh = SphereMesh.new()
			#mesh.mesh.radius = float(0.2)
			#shape.add_child(mesh)
			#
			#star.add_child(shape)
			#shape.global_position = Vector3(coords[0], coords[1], coords[2])
