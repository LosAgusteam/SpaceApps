extends Node
class_name SystemHandler

# SYSTEM LIST #
var star_systems = {}
@export var chosen_system: String

var root: Node3D = Node3D.new()

# THREADS #
var loading_thread: Thread

# MATERIALS #
var star_shader = preload("res://Materials/StarShader.tres")
var rocky_planet_shader = preload("res://Materials/RockPlanetShader.tres")
var gas_planet_shader = preload("res://Materials/GasPlanetShader.tres")
var orbit_shader = preload("res://Materials/OrbitShader.gdshader")

# PLANET COLOR DATA #
const V_0 = 3.63e-20
const Ks_0 = 4.283e-21
const Gaia_0 = 2.54e-20

func ra_dec_to_xyz(ra: float, dec: float, dist: float):
	var ra_rad = deg_to_rad(ra * 15)
	var dec_rad = deg_to_rad(dec)
	var array = []
	array.append(dist * cos(dec_rad) * cos(ra_rad))
	array.append(dist * cos(dec_rad) * sin(ra_rad))
	array.append(dist * sin(dec_rad))
	return array

func _process(delta: float) -> void:
	var environment: Environment = $WorldEnvironment.environment
	var rotation_factor: float = delta / 120.0
	environment.sky_rotation += Vector3(rotation_factor, rotation_factor, 0)

func _ready():
	loading_thread = Thread.new()
	loading_thread.start(_start_systems)
	loading_thread.wait_to_finish()
	
	for system_name in star_systems.keys():
		$HUD/SystemPanel/OptionButton.add_item(system_name)
	
	root.name = "StarSystems"
	add_child(root)
	
	_change_system("11 Com")

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
		var base_body = system_bodies[body_name]
		var body = base_body.duplicate()
		system_node.add_child(body)
		
		if base_body is Star3D:
			body.global_position = body.star_position
			
			$Camera3D.global_position = body.global_position
			$Camera3D.global_position.z += 5
			$Camera3D.look_at(body.global_position)
		
		elif base_body is Planet3D:
			var center: Vector3 = system_bodies[body.host_star].star_position
			var direction = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			var distance = body.orbit_radius * 2.5
			var end_pos: Vector3 = center + direction * distance
			body.global_position = end_pos
			
			var orbit_direction = (end_pos - center).normalized()
			var rotation_basis = Basis.looking_at(orbit_direction, Vector3.UP)
			var rotation_quat: Quaternion = Quaternion(rotation_basis) # Rotation as a quaternion
			
			var orbit_display_mesh = MeshInstance3D.new()
			orbit_display_mesh.mesh = PlaneMesh.new()
			orbit_display_mesh.scale = Vector3.ONE * distance
			
			body.add_child(orbit_display_mesh)
			orbit_display_mesh.global_position = center
			orbit_display_mesh.rotation = rotation_quat.get_euler()
			
			var orbit_material: ShaderMaterial = ShaderMaterial.new()
			orbit_material.shader = orbit_shader
			orbit_display_mesh.mesh.surface_set_material(0, orbit_material)

func _start_systems():
	var stars = preload("res://Data/StarData.csv")
	var data = preload("res://Data/ExoplanetData.csv")
	
	for star in stars.records:
		var system: Dictionary = star_systems.get_or_add(star.sy_name, {})
		if star.sy_pnum == 0:
			continue
		
		if not star_systems.get(star.sy_name).get(star.hostname):
			var coords = ra_dec_to_xyz(float(star.ra), float(star.dec), float(star.sy_dist));
			
			var star_node = Star3D.new()
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
			
			star_node.star_position = Vector3(coords[0], coords[1], coords[2])
			
			system[star.hostname] = star_node
	
	for planet in data.records:
		if star_systems.get(planet.hostname):
			
			var system: Dictionary = star_systems.get(planet.hostname)
			if float(planet.pl_orbsmax) * 2.5 <= 0:
				star_systems.erase(planet.hostname)
				continue
			
			var coords = ra_dec_to_xyz(float(planet.ra), float(planet.dec), float(planet.sy_dist));
			
			var planet_node = Planet3D.new()
			planet_node.name = planet.pl_name
			
			var mesh = MeshInstance3D.new()
			mesh.mesh = SphereMesh.new()
			mesh.mesh.radius= 0.2
			mesh.mesh.height = 0.395
			planet_node.add_child(mesh)
			
			var planet_material: ShaderMaterial = ShaderMaterial.new()
			
			if float(planet.pl_bmassj) < 1:
				planet_material.shader = rocky_planet_shader
			else:
				planet_material.shader = gas_planet_shader
			
			var V_flux = _mag_to_flux(float(planet.sy_vmag), V_0)
			var Ks_flux = _mag_to_flux(float(planet.sy_kmag), Ks_0)
			var Gaia_flux = _mag_to_flux(float(planet.sy_gaiamag), Gaia_0)
			
			var max_flux = max(Gaia_flux, V_flux, Ks_flux)
			var R_norm = Gaia_flux / max_flux
			var G_norm = V_flux / max_flux
			var B_norm = Ks_flux / max_flux
			
			print(int(R_norm * 255), int(G_norm * 255), int(B_norm * 255))
			
			var planet_color = Color(int(R_norm * 255), int(G_norm * 255), int(B_norm * 255))
			planet_material.set_shader_parameter("PlanetColor", planet_color.darkened(0.99))
			mesh.mesh.surface_set_material(0, planet_material)
			
			planet_node.host_star = planet.hostname
			planet_node.orbit_radius = float(planet.pl_orbsmax)
			
			system[planet.pl_name] = planet_node


func _on_system_selected(index: int) -> void:
	var system_name = $HUD/SystemPanel/OptionButton.get_item_text(index)
	_change_system(system_name)

func _mag_to_flux(mag, F0):
	return F0 * 10**(-mag / 2.5)
