extends BasicElement
class_name SliderElement
tool

signal VALUE_CHANGED

const SCROLL_STEP: float = 0.01
const LERP_SPEED: float = 10.0

export var value: float = 1.0 setget setValue
export var bg_colour: Color = Color.pink setget setBgColour

var current_shader_value: float = null
var dragging: bool = false
var progress_material: ShaderMaterial

func _ready():
	if Engine.editor_hint:
		return
	
	progress_material = panel_container.material
	current_shader_value = value
	progress_material.set_shader_param("progress", current_shader_value)
	progress_material.set_shader_param("replace_colour", bg_colour)

func setValue(v: float, instant: bool = false):
	v = max(0.0, min(1.0, v))
	
	if v == value:
		return
	
	value = v
	emit_signal("VALUE_CHANGED")
	
	if instant:
		current_shader_value = value
		progress_material.set_shader_param("progress", current_shader_value)
	
	if Engine.editor_hint:
		$PanelContainer.material.set_shader_param("progress", value)

func setBgColour(value: Color):
	if value == bg_colour:
		return
	bg_colour = value
	
	if progress_material == null:
		if Engine.editor_hint:
			$PanelContainer.material.set_shader_param("replace_colour", bg_colour)
		return
	
	progress_material.set_shader_param("replace_colour", bg_colour)

func _process(delta: float):
	if Engine.editor_hint:
		return
	
	if current_shader_value == value:
		return
	
	current_shader_value = lerp(current_shader_value, value, delta * LERP_SPEED)
	progress_material.set_shader_param("progress", current_shader_value)

func _on_MarginContainer_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			dragging = event.pressed
			setValue(get_local_mouse_position().x / rect_size.x)
		elif event.button_index == BUTTON_WHEEL_UP:
			setValue(value + SCROLL_STEP, true)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			setValue(value - SCROLL_STEP, true)

	elif dragging and event is InputEventMouseMotion:
		setValue(get_local_mouse_position().x / rect_size.x)

func _on_MarginContainer_mouse_exited():
	dragging = false
