extends Element
class_name BasicElement
tool

export var corner_radius: float = 15.0 setget setCornerRadius
export var colour: Color = Colours.mauve setget setColour

onready var layout_container: HBoxContainer = $PanelContainer/MarginContainer/LayoutContainer
onready var panel_container: PanelContainer = $PanelContainer
onready var panel_style: StyleBoxFlat = $PanelContainer.get("custom_styles/panel")
onready var margin_container: MarginContainer = $PanelContainer/MarginContainer
onready var resize_tween: Tween = $ResizeTween
onready var colour_tween: Tween = $ColourTween

enum RESIZE_MODE { FIXED, DYNAMIC_FULL, DYNAMIC_OFFSET }
var resize_mode: int = RESIZE_MODE.DYNAMIC_FULL

const DYNAMIC_RESIZE_DURATION: float = 0.5
const DYNAMIC_RESIZE_TRANS_TYPE: int = Tween.TRANS_SINE
const DYNAMIC_RESIZE_EASE_TYPE: int = Tween.EASE_IN_OUT

var prev_min_size: Vector2

func _ready():
	panel_style.bg_color = colour

func init(module: Module = null):
	visible = false
	
#	var label: Label = Label.new()
#	label.visible = false
#
#	var font: DynamicFont = DynamicFont.new()
#	font.font_data = preload("res://fonts/NotoSansCJKjp-Regular.ttf")
#	font.size = 13
#	label.set("custom_fonts/font", font)
#
#	addSubElement(label)
	
	.init(module)
	
	if "bg-colour" in module.config:
		setColour(GDBar.getColour(module.config["bg-colour"]))

func setCornerRadius(value: float):
	if corner_radius == value:
		return
	corner_radius = value
	
	for property in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		panel_style.set(property, corner_radius)

func addSubElement(node: Node, index: int = -1):
	if layout_container == null:
		layout_container = $PanelContainer/MarginContainer/LayoutContainer
	
	layout_container.add_child(node)
	if index != -1:
		layout_container.move_child(node, index)

func setData(value, index: int = 0):
	
	if layout_container == null:
		layout_container = $PanelContainer/MarginContainer/LayoutContainer
	
	var node: Node = layout_container.get_child(index)
	
	if node is TextureRect:
		assert(value is Texture)
	
	elif node is Label:
		assert(value is String)
		
		if Engine.editor_hint:
			node.text = value
			return
		
		if not node.has_meta("text"):
			node.set_meta("text", "")
		
		if value == node.get_meta("text"):
			return
		
		var text: String = value.strip_edges()
		node.set_meta("text", value.strip_edges())
		
		if resize_tween == null:
			node.text = text
			node.visible = !text.empty()
			checkVisibility()
			return
		
		resize_tween.stop_all()
		
		if text.empty():
			
			if not visible:
				return
			
			match resize_mode:
				RESIZE_MODE.FIXED:
					resize_tween.interpolate_property(self, "modulate:a", modulate.a, 0, DYNAMIC_RESIZE_DURATION, DYNAMIC_RESIZE_TRANS_TYPE, DYNAMIC_RESIZE_EASE_TYPE)
					resize_tween.interpolate_callback(self, DYNAMIC_RESIZE_DURATION, "set_visible", false)
					resize_tween.start()
				RESIZE_MODE.DYNAMIC_FULL, RESIZE_MODE.DYNAMIC_OFFSET:
					node.set_meta("source_text", node.text)
					resize_tween.interpolate_method(self, "interpolateToTargetText", index * 10 + 0.0, index * 10 + 0.5, DYNAMIC_RESIZE_DURATION * 0.5, DYNAMIC_RESIZE_TRANS_TYPE, DYNAMIC_RESIZE_EASE_TYPE)
					resize_tween.interpolate_property(self, "modulate:a", modulate.a, 0, DYNAMIC_RESIZE_DURATION * 0.5, DYNAMIC_RESIZE_TRANS_TYPE, DYNAMIC_RESIZE_EASE_TYPE)
					resize_tween.interpolate_callback(self, DYNAMIC_RESIZE_DURATION * 0.501, "shrink")
					resize_tween.start()
			
			return
		
		if not visible:
			node.text = ""
			
			resize_tween.interpolate_method(self, "interpolateToTargetText", index * 10 + 0.5, index * 10 + 1, DYNAMIC_RESIZE_DURATION * 0.75, DYNAMIC_RESIZE_TRANS_TYPE, DYNAMIC_RESIZE_EASE_TYPE, DYNAMIC_RESIZE_DURATION * 0.25)
			resize_tween.interpolate_property(self, "modulate:a", 0, 1, DYNAMIC_RESIZE_DURATION * 0.75, 0, 2, DYNAMIC_RESIZE_DURATION * 0.25)
			
			expand()
			return
		
		match resize_mode:
			RESIZE_MODE.FIXED: node.text = value
			RESIZE_MODE.DYNAMIC_FULL:
				node.set_meta("source_text", node.text)
				resize_tween.interpolate_method(self, "interpolateToTargetText", index * 10 + 0, index * 10 + 1, DYNAMIC_RESIZE_DURATION, DYNAMIC_RESIZE_TRANS_TYPE, DYNAMIC_RESIZE_EASE_TYPE)
				resize_tween.start()
			
			RESIZE_MODE.DYNAMIC_OFFSET:
				resize_tween.interpolate_property(node, "modulate:a", node.modulate.a, 0, DYNAMIC_RESIZE_DURATION * 0.5, DYNAMIC_RESIZE_TRANS_TYPE, DYNAMIC_RESIZE_EASE_TYPE)
				resize_tween.interpolate_property(node, "modulate:a", 0, 1, DYNAMIC_RESIZE_DURATION * 0.5, DYNAMIC_RESIZE_TRANS_TYPE, DYNAMIC_RESIZE_EASE_TYPE, DYNAMIC_RESIZE_DURATION * 0.5)
				resize_tween.interpolate_method(self, "interpolateToTargetText", index * 10 + 0.0, index * 10 + 1.0, DYNAMIC_RESIZE_DURATION * 0.5, DYNAMIC_RESIZE_TRANS_TYPE, DYNAMIC_RESIZE_EASE_TYPE, DYNAMIC_RESIZE_DURATION * 0.5)
				resize_tween.start()

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

func checkVisibility():
	for child in layout_container.get_children():
		if child.visible:
			visible = true
			return
	visible = false

func shrink():
	prev_min_size = rect_size
	rect_min_size = rect_size
	
	for child in get_children():
		if "visible" in child:
			child.visible = false
	
	resize_tween.interpolate_property(self, "rect_min_size", rect_size, Vector2.ZERO, DYNAMIC_RESIZE_DURATION * 0.5, DYNAMIC_RESIZE_TRANS_TYPE, Tween.EASE_OUT)
	resize_tween.interpolate_callback(self, DYNAMIC_RESIZE_DURATION * 0.5, "set_visible", false)
	resize_tween.start()

func expand():
	for child in get_children():
		if "visible" in child:
			resize_tween.interpolate_callback(child, DYNAMIC_RESIZE_DURATION * 0.5, "set_visible", true)
	
	visible = true
	rect_min_size = Vector2.ZERO
	rect_size = Vector2.ZERO
	
	resize_tween.interpolate_property(self, "rect_min_size", rect_min_size, prev_min_size, DYNAMIC_RESIZE_DURATION * 0.5, DYNAMIC_RESIZE_TRANS_TYPE, Tween.EASE_IN)
	resize_tween.start()
