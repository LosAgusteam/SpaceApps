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

# SOUNDS # 
var active_sounds = 0
var max_sounds = 15
var sounds_array = ["oldusty", "ooze", "keys", "strings", "ritmicos"];

func calculate_pitch(mass: float, min_mass: float = 0.000001, max_mass: float = 1.0) -> int:
	# Limitar la masa para que no salga del rango definido
	mass = max(min_mass, min(mass, max_mass))
	
	# Calcular el valor inversamente proporcional entre 1 y 28
	# Queremos que la masa mínima dé el valor máximo (28) y la masa máxima dé el valor mínimo (1)
	var pitch = 28 - ((mass - min_mass) / (max_mass - min_mass)) * (28 - 1)
	print(pitch)
	# Redondeamos el resultado y lo convertimos en entero
	return int(round(pitch))

	
func random_pitch() -> float:
	var random_index = randi() % 28 + 1 # Número aleatorio entre 1 y 28
	return random_index
	
func calculate_timber(radius: float, min_radius: float = 1000.0, max_radius: float = 10000000.0) -> float:
	# Limitar la masa para que no salga del rango definido
	radius = max(min_radius, min(radius, max_radius))
	
	# Calcular el valor inversamente proporcional entre 1 y 28
	# Queremos que la masa mínima dé el valor máximo (28) y la masa máxima dé el valor mínimo (1)
	var timber = sounds_array.size() - ((radius - min_radius) / (max_radius - min_radius)) * (sounds_array.size() - 1)
	print(timber)
	# Redondeamos el resultado y lo convertimos en entero
	return int(round(timber) - 1)

func temperature_to_sound(temperature: float, audio: AudioStreamPlayer3D):
	if(temperature > 100000.0):
		audio.bus = "High Bus"
	elif(temperature > 10000.0):
		audio.bus = "Mid Bus"
	else:
		audio.bus = "Low Bus"
	
func random_timber()->int:
	var random_index = randi() % sounds_array.size() + 0
	return random_index

func get_audio_file(pitch: float, library: int) -> String:
	# Assuming the audio files are named based on the pitch value
	print("TImbre: ", sounds_array[library])
	#return "res://Sounds/ritmicos/" + str(pitch) + ".wav"
	return "res://Sounds/" + sounds_array[library] + "/" + str(pitch) + ".wav"
	
func get_audio_file_prueba() -> String:
	# Assuming the audio files are named based on the pitch value
	var random_index = randi() % 5 + 1
	return "res://Sounds/melodias/" + str(random_index) + ".wav"

func play_audio(audio: AudioStreamPlayer3D):
	if active_sounds < max_sounds:
		audio.play()
		active_sounds += 1

#Fixed Sounds
var audio_player_hyperdrive: AudioStreamPlayer
var audio_player_waves: AudioStreamPlayer

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

func _ready():
	loading_thread = Thread.new()
	loading_thread.start(_start_systems)
	loading_thread.wait_to_finish()
	
	root.name = "StarSystems"
	add_child(root)
	
	#perdon por esto juan
	audio_player_hyperdrive = AudioStreamPlayer.new()
	add_child(audio_player_hyperdrive)
	audio_player_hyperdrive.stream = load("res://Sounds/ambient/hyperdrive.mp3")
	audio_player_hyperdrive.bus = "MainBus"  # Asignar el bus
	#audio_player_hyperdrive.volume_db = -50  # Ajustar volumen (-10 dB)
	audio_player_hyperdrive.play()

	audio_player_waves = AudioStreamPlayer.new()
	add_child(audio_player_waves)
	audio_player_waves.stream = load("res://Sounds/ambient/waves.mp3")
	audio_player_waves.bus = "MainBus"  # Asignar el bus
	#audio_player_waves.volume_db = -50  # Ajustar volumen (-10 dB)
	audio_player_waves.play()
	
	#_change_system("11 Com")
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
		var base_body = system_bodies[body_name]
		var body = base_body.duplicate()
		system_node.add_child(body)
		
		if base_body is Star3D:
			#play_audio(body.star_audio)
			
			for audio_player in body.get_children():
				if audio_player is AudioStreamPlayer3D:
					audio_player.play()
			
			print("estrella")
			body.global_position = body.star_position
			$Camera3D.global_position = body.global_position
			$Camera3D.global_position.z += 5
			$Camera3D.look_at(body.global_position)
		
		elif base_body is Planet3D:
			var center = system_bodies[body.host_star].star_position
			var direction = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			var distance = randf_range(body.orbit_radius / 2, body.orbit_radius) * 2.5
			var end_pos = center + direction * distance
			body.global_position = end_pos
			for audio_player in body.get_children():
				if audio_player is AudioStreamPlayer3D:
					audio_player.play()

func _start_systems():
	var stars = preload("res://Data/StarData.csv")
	var data = preload("res://Data/ExoplanetData.csv")
	
	for star in stars.records:
		var system: Dictionary = star_systems.get_or_add(star.sy_name, {})
		
		if not star_systems.get(star.sy_name).get(star.hostname):
			var coords = ra_dec_to_xyz(float(star.ra), float(star.dec), float(star.sy_dist));
			
			var star_node = Star3D.new()
			star_node.name = star.hostname
			
			var mesh: MeshInstance3D = MeshInstance3D.new()
			mesh.mesh = SphereMesh.new()
			star_node.add_child(mesh)
			
			var star_material: ShaderMaterial = ShaderMaterial.new()
			star_material.shader = star_shader
			# Create the audio player
			var star_audio = AudioStreamPlayer3D.new()
			var star_pitch = calculate_pitch(float(star.st_mass))
			var random_pitch = random_pitch()
			##var star_timber = calculate_timber(float(star.st_rad))
			var star_timber = random_timber()
			star_audio.stream = load(get_audio_file(star_pitch, star_timber)) # Assign the .wav file based on pitch
			star_audio.autoplay = false # Disable autoplay
			star_audio.max_distance = 2000 # Set max audible distance
			star_audio.volume_db = -10 # Lower the volume
			star_audio.unit_size = 1.0 # Control sound attenuation
			star_node.add_child(star_audio)
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
			var coords = ra_dec_to_xyz(float(planet.ra), float(planet.dec), float(planet.sy_dist));
			
			var planet_node = Planet3D.new()
			planet_node.name = planet.pl_name
			
			var mesh = MeshInstance3D.new()
			mesh.mesh = SphereMesh.new()
			planet_node.add_child(mesh)
			var planet_audio = AudioStreamPlayer3D.new()
			var planet_pitch = calculate_pitch(float(planet.pl_bmasse))
			##var planet_timber = calculate_timber(float(planet.pl_radj))
			var planet_timber = random_timber()
			var random_pitch = random_pitch()
			planet_audio.stream = load(get_audio_file(planet_pitch, planet_timber)) # Assign the .wav file based on pitch
			planet_audio.autoplay = false # Disable autoplay
			planet_audio.max_distance = 2000 # Set max audible distance
			planet_audio.volume_db = -10 # Lower the volume
			planet_audio.unit_size = 1.0 # Control sound attenuation
			planet_node.add_child(planet_audio)
			planet_node.host_star = planet.hostname
			planet_node.orbit_radius = float(planet.pl_orbsmax)
			
			system[planet.pl_name] = planet_node
