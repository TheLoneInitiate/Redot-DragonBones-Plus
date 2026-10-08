extends Node2D

@onready var dragon_bones_female: DragonBonesArmatureView = $DragonBonesArmatureView
@onready var sprite_2d: Sprite2D = $Sprite2D

var facing_forward: bool = true
var running: bool = false
var attacking: bool = false
var flinching: bool = false

var move_speed: float = 120.0
var base_walk_speed: float = 80.0
var attack_speed: float = 1.5

@export var rotation_offset: float = deg_to_rad(0)
@export var swing_length: float = 0.6

func _ready() -> void:
	dragon_bones_female.frame_event.connect(_on_frame_event)
	dragon_bones_female.animation_completed.connect(_on_animation_completed)
	play_run()

func _on_frame_event(_clip: String, event_name: String, _event_pos: Vector2) -> void:
	var bone_name := ""
	if event_name == "LeftFootTouched":
		bone_name = "LeftFoot"
	elif event_name == "RightFootTouched":
		bone_name = "FootRight"
	else:
		return
	var foot := dragon_bones_female.to_global(
		dragon_bones_female.get_armature().get_bone_global_pos(bone_name)
	)
	# You could use the event signal of foot touching ground to trigger dirt puff particles or footstep sounds

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("run"):
		running = true
	elif event.is_action_released("run"):
		running = false

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not attacking:
		play_attack()

	if event is InputEventKey and event.pressed and event.keycode == KEY_F and not flinching:
		flinching = true
		var arm := dragon_bones_female.get_armature()
		arm.fade_in_masked(
			"Flinch", -1.0, 1, 1, "hit",
			DragonBonesArmature.FADE_OUT_NONE,
			PackedStringArray(["Hip"])
		)
		arm.set_animation_weight("Flinch", 0.3)
		

	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		dragon_bones_female.get_armature().get_slot("Head").set_display_region("Head2")
	if event is InputEventKey and event.pressed and event.keycode == KEY_2:
		dragon_bones_female.get_armature().get_slot("torso").set_display_region("torso2")
	if event is InputEventKey and event.pressed and event.keycode == KEY_3:
		dragon_bones_female.get_armature().get_slot("leftleg").set_display_region("leftleg2")
		dragon_bones_female.get_armature().get_slot("rightleg").set_display_region("rightleg2")
	if event is InputEventKey and event.pressed and event.keycode == KEY_4:
		dragon_bones_female.get_armature().get_slot("leftarm").set_display_region("leftarm2")
		dragon_bones_female.get_armature().get_slot("rightarm").set_display_region("rightarm2")
	if event is InputEventKey and event.pressed and event.keycode == KEY_5:
		clear_equipment()

func _process(_delta: float) -> void:
	if not dragon_bones_female:
		return

	var mouse_pos := get_global_mouse_position()
	var to_mouse := mouse_pos - dragon_bones_female.global_position
	var should_face_forward := to_mouse.x >= 0.0
	dragon_bones_female.flip_x = facing_forward
	if should_face_forward != facing_forward:
		facing_forward = should_face_forward
		dragon_bones_female.flip_x = not facing_forward

	sprite_2d.global_position = dragon_bones_female.get_armature().get_bone_global_pos("HandRight")
	move_speed = 220.0 if running else 120.0
	var walk_scale := clampf(move_speed / base_walk_speed, 0.25, 2.5)
	dragon_bones_female.get_armature().set_animation_time_scale("Walk", walk_scale)

	if attacking:
		return

	var aim := -to_mouse.angle() + rotation_offset
	if not facing_forward:
		aim = PI - aim
	var arm := dragon_bones_female.get_armature()
	arm.set_bone_rotation_override("ArmLeftUpper", aim)
	arm.set_bone_rotation_override("ArmRightUpper", aim)

func play_run() -> void:
	dragon_bones_female.fade_in(
		"Walk", -1.0, 0, 0, "body",
		DragonBonesArmature.FADE_OUT_SAME_LAYER
	)

func play_attack() -> void:
	attacking = true
	var arm := dragon_bones_female.get_armature()
	# Clear Bone Override plays the anim from their original pose instead of current pos
	#arm.clear_bone_override("ArmLeftUpper")
	#arm.clear_bone_override("ArmRightUpper")
	arm.fade_in_masked(
		"Swing", 0.0, 1, 1, "arms",
		DragonBonesArmature.FADE_OUT_NONE,
		PackedStringArray(["ArmLeftUpper", "ArmRightUpper"])
	)
	#print("Animation States  : ",dragon_bones_female.get_armature().get_animation_states())
	arm.set_animation_time_scale("Swing", attack_speed)
	print("Animation States  : ",dragon_bones_female.get_armature().get_animation_states())

func _on_animation_completed(animation_name: String) -> void:
	if animation_name == "Flinch":
		flinching = false
		print("Flinch Animation ended")
	print("completed: ", animation_name)
	if animation_name != "Swing":
		return
	attacking = false
	dragon_bones_female.get_armature().fade_out("Swing", 0.1)
	
func clear_equipment() -> void:
	var slots := dragon_bones_female.get_armature().get_slots()
	for slot_name in slots:
		dragon_bones_female.get_armature().get_slot(slot_name).clear_display_region()
