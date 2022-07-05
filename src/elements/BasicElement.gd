extends Element
class_name BasicElement
tool

export var corner_radius: float = 15.0 setget setCornerRadius
export var colour: Color = Colours.mauve setget setColour

onready var layout_container: HBoxContainer = $PanelContainer/MarginContainer/LayoutContainer
onready var panel_container: PanelContainer = $PanelContainer
onready var panel_style: StyleBoxFlat = $PanelContainer.get("custom_styles/panel")
onready var margin_container: MarginContainer = $PanelContainer/MarginContainer
onready var animation_tween: Tween = $ResizeTween
onready var colour_tween: Tween = $ColourTween

enum RESIZE_MODE { FIXED, DYNAMIC_FULL, DYNAMIC_OFFSET }
var resize_mode: int = RESIZE_MODE.DYNAMIC_FULL

const ANIMATION_DURATION: float = 0.5
#const ANIMATION_DURATION: float = 5.0
const ANIMATION_TRANS_TYPE: int = Tween.TRANS_SINE
const ANIMATION_EASE_TYPE: int = Tween.EASE_IN_OUT

var prev_min_size: Vector2

func _ready():
	panel_style.bg_color = colour

func init(module: Module = null):
	.init(module)
	
	if "bg-colour" in module.config:
		setColour(GDBar.getColour(module.config["bg-colour"]))
	elif Colours.palletteAvailable():
		setColour(Colours.getNextPalletteColour())

func setCornerRadius(value: float):
	if corner_radius == value:
		return
	corner_radius = value
	
	for property in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		panel_style.set(property, corner_radius)

func addSubElement(node: Node):
	if layout_container == null:
		layout_container = $PanelContainer/MarginContainer/LayoutContainer
	layout_container.add_child(node)

var animation_queue: Dictionary = {}
var animation_targets: Dictionary = {}

func prepareAnimation():
	animation_queue.clear()
	if not is_inside_tree():
		return

func setVisibility(visibility: bool):
	
	if visible == visibility:
		return
	
	if not self in animation_queue:
		animation_queue[self] = {}
	
	animation_queue[self]["visibility"] = visibility

func setElementVisibility(node: Node, visibility: bool):
	assert(layout_container.is_a_parent_of(node))
	
	if node.visible == visibility:
		return
	
	if not node in animation_queue:
		animation_queue[node] = {}
	
	animation_queue[node]["visibility"] = visibility

func setLabelText(label: Label, text: String):
	assert(layout_container.is_a_parent_of(label))
	
	if label.text == text:
		return
	
	if label in animation_targets and "label_text" in animation_targets[label] and text == animation_targets[label]["label_text"]:
		return
	
	if not label in animation_queue:
		animation_queue[label] = {}
	
	animation_queue[label]["label_text"] = text

func _setLabelTextSmooth(label: Label, text: String):
	rect_min_size = Vector2.ZERO
	
	var tween: Tween = Tween.new()
	add_child(tween)
	
#	var container: Node = Node.new()
#	var dupe: Control = self.duplicate(0)
#	container.add_child(dupe)
#	get_parent().add_child(container)
#	dupe.rect_global_position = rect_global_position
	
	var original_size: Vector2 = rect_size
	var original_text: String = label.text
	label.text = text
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	var size_flags: int = label.size_flags_horizontal
	
	var target_size: Vector2 = rect_size
	label.text = original_text
	yield(get_tree(), "idle_frame")
	
#	container.queue_free()
	
	tween.interpolate_property(label, "modulate:a", label.modulate.a, 0, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, ANIMATION_EASE_TYPE)
	tween.start()
	yield(tween, "tween_all_completed")
	
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if target_size.x < original_size.x:
		label.text = text
		tween.interpolate_property(label, "modulate:a", label.modulate.a, 1, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, ANIMATION_EASE_TYPE)
	
	rect_size = Vector2.ZERO
	tween.interpolate_property(self, "rect_min_size", original_size, target_size, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, ANIMATION_EASE_TYPE)
	tween.start()
	yield(tween, "tween_all_completed")
	
	if target_size.x >= original_size.x:
		label.text = text
		tween.interpolate_property(label, "modulate:a", label.modulate.a, 1, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, ANIMATION_EASE_TYPE)
		tween.start()
		yield(tween, "tween_all_completed")
	
	label.size_flags_horizontal = size_flags
	tween.queue_free()

func executeAnimation():
	
	if not is_inside_tree():
		for node in animation_queue:
			for key in animation_queue[node]:
				var value = animation_queue[node][key]
				
				match key:
					"visibility":
						node.visible = value
					"label_text":
						node.text = value
		return
	
	if self in animation_queue:
		for key in animation_queue[self]:
			var value = animation_queue[self][key]
			if key == "visibility":
				if value:
					yield(expand(), "completed")
				else:
					shrink()
		animation_queue.erase(self)
	
	for node in animation_queue:
		
		if not node in animation_targets:
			animation_targets[node] = {}
		
		for key in animation_queue[node]:
			var value = animation_queue[node][key]
			animation_targets[node][key] = value
			
			match key:
				"visibility":
					animation_tween.stop(node, "modulate:a")
					animation_tween.stop(node, "set_visible")
					animation_tween.interpolate_property(node, "modulate:a", node.modulate.a, 1 if value else 0, ANIMATION_DURATION)
					animation_tween.interpolate_callback(node, ANIMATION_DURATION, "set_visible", value)
				"label_text":
					if node.get_meta("disable_fade"):
						node.text = value
					else:
						_setLabelTextSmooth(node, value)
					
#					animation_tween.interpolate_property(node, "modulate:a", node.modulate.a, 0, ANIMATION_DURATION * 0.5)
#					animation_tween.interpolate_property(node, "modulate:a", 0, 1, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, ANIMATION_EASE_TYPE, ANIMATION_DURATION * 0.5)
#					animation_tween.interpolate_callback(self, ANIMATION_DURATION * 0.5, "_setLabelTextSmooth", node, value)
					
#					animation_tween.stop(node, "tweenStep")
#					var animator: LabelAnimator = LabelAnimator.new(node.text, value, node)
#					animation_tween.interpolate_method(animator, "tweenStep", 0, 1, ANIMATION_DURATION)
	
	animation_tween.start()

func setColour(value: Color, animate: bool = false):
	if colour == value:
		return
	
	colour = value
	
	if Engine.editor_hint:
		$PanelContainer.get("custom_styles/panel").bg_color = colour
		return
	
	if colour_tween:
		colour_tween.stop_all()
	
	if not animate or colour_tween == null:
		if not panel_style:
			panel_style = $PanelContainer.get("custom_styles/panel")
		panel_style.bg_color = colour
		return

	colour_tween.interpolate_property(panel_style, "bg_color", panel_style.bg_color, colour, 0.25, Tween.TRANS_SINE)
	colour_tween.start()

func connectGuiInput(object: Object, method: String, binds: Array = []):
	if margin_container == null:
		margin_container = $PanelContainer/MarginContainer
	margin_container.connect("gui_input", object, method, binds)

func interpolateToTargetText(value: float):
	var new_text: String = ""
	
	var index: int = int(value / 10)
	value = value - index
	
	var node: Node = layout_container.get_child(index)
	assert(node is Label)
	
	if value < 0.5:
		var source_text: String = node.get_meta("source_text")
		for i in len(source_text) * (1.0 - (value * 2.0)):
			new_text += source_text[i]
	else:
		for i in len(node.text) * (value - 0.5) * 2.0:
			new_text = new_text + node.text[i]
	
	node.text = new_text

#func checkVisibility():
#	for child in layout_container.get_children():
#		if child.visible:
#			visible = true
#			return
#	visible = false

func shrink():
	prev_min_size = rect_size
	rect_min_size = rect_size
	
	animation_tween.interpolate_property(layout_container, "modulate:a", layout_container.modulate.a, 0, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, ANIMATION_EASE_TYPE)
	animation_tween.interpolate_callback(layout_container, ANIMATION_DURATION * 0.5, "set_visible", false)
	
	animation_tween.interpolate_property(self, "rect_min_size", rect_size, Vector2.ZERO, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, Tween.EASE_OUT, ANIMATION_DURATION * 0.5)
	animation_tween.interpolate_callback(self, ANIMATION_DURATION, "set_visible", false)

func expand():
	visible = true
	
	layout_container.visible = true

	yield(get_tree(), "idle_frame")
	
	var target: Vector2 = rect_size
	
	layout_container.visible = false
	
	yield(get_tree(), "idle_frame")
	
	rect_min_size.x = 0
	rect_size.x = 0
	
	yield(get_tree(), "idle_frame")
	
	animation_tween.interpolate_property(self, "rect_min_size", rect_min_size, target, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, Tween.EASE_IN)
	
	animation_tween.interpolate_property(layout_container, "modulate:a", 0, 1, ANIMATION_DURATION * 0.5, ANIMATION_TRANS_TYPE, ANIMATION_EASE_TYPE, ANIMATION_DURATION * 0.5)
	animation_tween.interpolate_callback(layout_container, ANIMATION_DURATION * 0.5, "set_visible", true)
