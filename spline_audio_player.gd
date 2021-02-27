extends Path
class_name SplineAudioPlayer
tool

export(Array, NodePath) var player_listeners
export var current_player : int
export var create_audio_player : bool
export var sound_range = 10.0
var start : bool
var sounddict = {}
var update_sounds : bool
var child_sounds : Array = []
var check_points : Array = [[], []]
var follow_nodes : int
var listeners : Array = []

func start():
	child_sounds = get_child(0).get_children()
	for l in player_listeners:
		listeners.append(get_node(l))
	yield(get_tree(),"idle_frame")
	for i in 5:
		add_child(PathFollow.new())
	for c in child_sounds:
		sounddict[c.name] = [c]
		for i in 5:
			sounddict[c.name].append(c.duplicate())
			get_child(i+1).add_child(sounddict[c.name][i+1])
	follow_nodes = get_children().size()
	
	#check points
	get_child(0).unit_offset = 1
	while get_child(0).offset > 0.5:
		get_child(0).offset -= 0.5
		check_points[0].append(get_child(0).get_child(0).global_transform.origin)
		check_points[1].append(get_child(0).offset)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint() && create_audio_player:
		create_audio_player = false
		if get_child_count() <= 0:
			var follow = PathFollow.new()
			add_child(follow)
			follow.owner = owner
		var newAudio = AudioStreamPlayer3D.new()
		get_child(0).add_child(newAudio)
		newAudio.owner = owner
	elif !Engine.is_editor_hint():
		if !start:
			start = true
			start()
		else:
			update_sounds = !update_sounds
			if update_sounds:
				update(delta)
	else:
		start = false
	pass

func update(delta: float):
	for c in child_sounds:
		for sound in sounddict[c.name].size():
			if sound > 0:
				if sounddict[c.name][sound].stream != c.stream:
					sounddict[c.name][sound].stream = c.stream
				sounddict[c.name][sound].attenuation_model = c.attenuation_model
				sounddict[c.name][sound].unit_db = c.unit_db
				sounddict[c.name][sound].unit_size = c.unit_size
				sounddict[c.name][sound].max_db = c.max_db
				sounddict[c.name][sound].pitch_scale = c.pitch_scale
				if sounddict[c.name][sound].playing != c.playing:
					sounddict[c.name][sound].playing = c.playing
				sounddict[c.name][sound].stream_paused = c.stream_paused
				sounddict[c.name][sound].max_distance = c.max_distance
				sounddict[c.name][sound].out_of_range_mode = c.out_of_range_mode
				sounddict[c.name][sound].bus = c.bus
				sounddict[c.name][sound].area_mask = c.area_mask
				if c.emission_angle_enabled:
					sounddict[c.name][sound].emission_angle_enabled = c.emission_angle_enabled
					sounddict[c.name][sound].emission_angle_degrees = c.emission_angle_degrees
					sounddict[c.name][sound].emission_angle_filter_attenuation_db = c.emission_angle_filter_attenuation_db
				sounddict[c.name][sound].attenuation_filter_cutoff_hz = c.attenuation_filter_cutoff_hz
				sounddict[c.name][sound].attenuation_filter_db = c.attenuation_filter_db
				sounddict[c.name][sound].doppler_tracking = c.doppler_tracking
	
	var dist = check_points[0][0].distance_to(listeners[current_player].global_transform.origin)
	var dist2 = 99999.0
	var closestInd = 0
	var closest2Ind = -1
	var valid_dist = check_points[0].size()*0.25
	for point in check_points[0].size():
		var dist_check = check_points[0][point].distance_to(listeners[current_player].global_transform.origin)
		if dist_check < dist:
			var p_dist = point - closestInd
			if p_dist < -valid_dist*0.2 || p_dist > valid_dist*0.2:
				dist2 = dist
				closest2Ind = closestInd
			dist = dist_check
			closestInd = point
	
	if dist2 > 15:
		for follow in 6:
			get_child(follow).offset = check_points[1][closestInd] + sound_range*(follow-2.5)
	else:
		for follow in 3:
			get_child(follow).offset = check_points[1][closestInd] + sound_range*(follow-1.5)
		for follow in 3:
			get_child(follow+3).offset = check_points[1][closest2Ind] + sound_range*(follow-1.5)
	pass