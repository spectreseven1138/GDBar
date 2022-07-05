extends Node

class CommandModule extends Element.Module:
	var label: Label = null
	var executable: String
	var args: Array = []
	
	static func getType():
		return "command"
	
	static func create(config: Dictionary):
		var element: Element = preload("res://src/elements/BasicElement.tscn").instance()
		var module: Element.Module = CommandModule.new()
		module.init(element, config)
		
		module.label = GDBar.createStyledLabel(
			config["style"] if "style" in config else null,
			config["on-click"] if "on-click" in config else null
		)
		element.addSubElement(module.label)
		
		var command: Array = config["command"]
		module.executable = command.pop_front()
		module.args = command
		
		element.init(module)
		return element
	
	func updateElement():
		var result: Array = []
		OS.execute(executable, args, true, result, true)
		
		element.prepareAnimation()
		
		if result.empty() or result[0].strip_edges().empty():
			element.setElementVisibility(label, false)
		else:
			element.setElementVisibility(label, true)
			element.setLabelText(label, result[0].strip_edges())
		
		element.executeAnimation()

class TimeModule extends Element.Module:
	const WEEKDAY_NAMES: Array = [
		"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
	]
	
	var label: Label = null
	
	static func getType():
		return "time"
	
	static func create(config: Dictionary):
		var element: Element = preload("res://src/elements/BasicElement.tscn").instance()
		var module: Element.Module = TimeModule.new()
		module.init(element, config)
		
		module.label = GDBar.createStyledLabel(config["style"] if "style" in config else null)
		element.addSubElement(module.label)
		
		element.init(module)
		
		return element
	
	func updateElement():
		var time: Dictionary = OS.get_datetime()
		for key in time:
			if key == "dst":
				continue
			if key == "weekday":
				time[key] = WEEKDAY_NAMES[time[key]]
				continue
			
			if time[key] < 10:
				var text: String = str(time[key])
				time[key] = "0".repeat(2 - min(len(text), 2)) + text
			else:
				time[key] = str(time[key])
		
		# TODO | Config
		# year, month, day, weekday, hour, minute, second
		label.text = time["weekday"] + " " + time["month"] + "/" + time["day"] + " " + time["hour"] + ":" + time["minute"]

class VolumeModule extends Element.Module:
	
	var label: Label = null
	
	static func getType():
		return "volume"
	
	static func create(config: Dictionary):
		var scene: PackedScene
		if "slider" in config and config["slider"]:
			scene = preload("res://src/elements/SliderElement.tscn")
		else:
			scene = preload("res://src/elements/BasicElement.tscn")
		
		var element: Element = scene.instance()
		var module: Element.Module = VolumeModule.new()
		module.init(element, config)
		
		module.label = GDBar.createStyledLabel(config["style"] if "style" in config else null)
		element.addSubElement(module.label)
		
		element.init(module)
		
		element.resize_mode = BasicElement.RESIZE_MODE.FIXED
		element.rect_min_size.x = 75
		if element is SliderElement:
			element.connect("VALUE_CHANGED", module, "onSliderValueChanged")
			element.setBgColour(element.colour * 0.75)
		else:
			element.connectGuiInput(module, "onElementGuiInput")
		
		return element
	
	static func getVolume() -> float:
		var result: Array = []
		OS.execute("amixer", ["get", "Master"], true, result, true)
		
		var data: String = result[0]
		
		var volume: String = null
		for line in data.split("\n"):
			line = line.strip_edges(true, false)
			if not line.begins_with("Front Left: "):
				continue
			
			for i in len(line) - 12:
				i += 12
				
				var c: String = line[i]
				if volume == null:
					if c == "[":
						volume = ""
				else:
					if c == "%":
						break
					else:
						volume += c
		
		return float(volume) / 100.0
	
	static func setVolume(value: float):
		OS.execute("amixer", ["-q", "sset", "Master", str(int(value * 100.0)) + "%"])
	
	func onElementGuiInput(event: InputEvent):
		if event is InputEventMouseButton:
			var polarity: int = 0
			if event.button_index == BUTTON_WHEEL_UP:
				polarity = 1
			elif event.button_index == BUTTON_WHEEL_DOWN:
				polarity = -1
			
			if polarity != 0:
				var volume: float
				if element.has_meta("volume_cache"):
					volume = element.get_meta("volume_cache")
				else:
					volume = getVolume()
				
				volume += polarity * SliderElement.SCROLL_STEP
				setVolume(volume)
				
				updateElement(volume)
	
	func onSliderValueChanged():
		assert(element is SliderElement)
		var percentage: String = str(int(element.value * 100))
		OS.execute("amixer", ["-q", "sset", "Master", percentage + "%"])
		updateElement(element.value)
	
	func updateElement(volume: float = getVolume()):
		label.text = str(int(volume * 100.0)) + "%"
		if element is SliderElement:
			element.value = volume
		else:
			element.set_meta("volume_cache", volume)

class MediaAPIModule extends Element.Module:
	
	const DEFAULT_LAYOUT: Array = ["info", "previous", "playpause", "next"]
	
	const DEFAULT_PLAYPAUSE_STYLE: Dictionary = {
		"play-icon": "res://icons/play.png",
		"pause-icon": "res://icons/pause.png"
	}
	
	const DEFAULT_NEXT_STYLE: Dictionary = {
		"icon": "res://icons/next.png"
	}
	
	const DEFAULT_PREVIOUS_STYLE: Dictionary = {
		"icon": "res://icons/previous.png"
	}
	
	var info: Label = null
	var info_on_click: Array = null
	var playpause: TextureButton = null
	var next: TextureButton = null
	var previous: TextureButton = null
	
	static func getType():
		return "media-api"
	
	static func create(config: Dictionary):
		var element: BasicElement = preload("res://src/elements/BasicElement.tscn").instance()
		var module: Element.Module = MediaAPIModule.new();
		module.init(element, config)
		
		if "layout" in config:
			var layout: Dictionary = config["layout"]
			
			for sub_element in layout:
				
				match sub_element:
					"info":
						module.info = GDBar.createStyledLabel(layout[sub_element]["style"] if "style" in layout[sub_element] else null)
						module.info.visible = true
						
						if "on-click" in layout[sub_element]:
							module.info.mouse_filter = Control.MOUSE_FILTER_PASS
							module.info.connect("gui_input", module, "onInfoGuiInput")
							module.info_on_click = layout[sub_element]["on-click"]
							GDBar.formatCommand(module.info_on_click)
						
						element.addSubElement(module.info)
						
					"playpause":
						module.playpause = TextureButton.new()
						module.playpause.visible = true
						module.playpause.expand = true
						module.playpause.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
						module.playpause.rect_min_size = Vector2(12, 12)
						module.playpause.modulate.a = 0.7
						module.playpause.toggle_mode = true
						
						var style: Dictionary = DEFAULT_PLAYPAUSE_STYLE
						if "style" in layout[sub_element]:
							style = GDBar.getStyle(layout[sub_element]["style"], DEFAULT_PLAYPAUSE_STYLE)
						
						module.playpause.texture_normal = load(style["play-icon"])
						module.playpause.texture_pressed = load(style["pause-icon"])
						module.playpause.connect("pressed", module, "onPlayPausePressed")
						
						element.addSubElement(module.playpause)
						
					"next":
						module.next = TextureButton.new()
						module.next.visible = true
						module.next.expand = true
						module.next.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
						module.next.rect_min_size = Vector2(12, 12)
						
						var style: Dictionary = DEFAULT_NEXT_STYLE
						if "style" in layout[sub_element]:
							style = GDBar.getStyle(layout[sub_element]["style"], DEFAULT_NEXT_STYLE)
						
						module.next.texture_normal = load(style["icon"])
						module.next.texture_pressed = module.next.texture_normal
						module.next.connect("pressed", module, "onNextPressed")
						
						element.addSubElement(module.next)
						
					"previous":
						module.previous = TextureButton.new()
						module.previous.visible = true
						module.previous.expand = true
						module.previous.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
						module.previous.rect_min_size = Vector2(12, 12)
						
						var style: Dictionary = DEFAULT_PREVIOUS_STYLE
						if "style" in layout[sub_element]:
							style = GDBar.getStyle(layout[sub_element]["style"], DEFAULT_PREVIOUS_STYLE)
						
						module.previous.texture_normal = load(style["icon"])
						module.previous.texture_pressed = module.previous.texture_normal
						module.previous.connect("pressed", module, "onPreviousPressed")
						
						element.addSubElement(module.previous)
					_:
						assert(false, "Unknown subelement '" + sub_element + "'")
						continue
		
		element.init(module)
		return element
	
	static func getMediaInfo() -> Dictionary:
		var result: Array = []
		OS.execute("mediaAPI", ["client", "getinfo"], true, result, true)
		
#		if result[0].strip_edges() == "[31mResource temporarily unavailable (timed out after 1000ms)[0m":
#			return null
#
#		print(result[0])
		
		var parsed: JSONParseResult = JSON.parse(result[0])
		if parsed.error != OK:
			return null
		
		return parsed.result
	
	func onInfoGuiInput(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
			GDBar.runCommand(info_on_click)
#			element.prepareAnimation()
##			element.setElementVisibility(info, false)
#			element.setLabelText(info, "Hello world Hello world Hello world Hello world Hello world Hello world Hello world")
#			element.executeAnimation()
	
	func onPlayPausePressed():
		OS.execute("mediaAPI", ["client", "playpause"])
		updateElement()
	
	func onNextPressed():
		OS.execute("mediaAPI", ["client", "next"])
	
	func onPreviousPressed():
		OS.execute("mediaAPI", ["client", "previous"])
	
	func updateElement():
		
		element.prepareAnimation()
		
		var data: Dictionary = getMediaInfo()
		
		if data == null:
			for node in [playpause, next, previous]:
				if node != null:
					element.setElementVisibility(node, false)
			
			if info != null:
				element.setElementVisibility(info, true)
				element.setLabelText(info, "Failed to get media info")
			
			element.executeAnimation()
			
			return
		
		element.setVisibility(data["visible"])
		
		if data["visible"]:
		
			element.setElementVisibility(info, true)
			element.setElementVisibility(playpause, true)
			
			if info != null:
				element.setLabelText(info, data["title"])
			
			if playpause != null:
				playpause.pressed = data["playing"]
			
			if next != null:
				element.setElementVisibility(next, data["can_go_next"])
			
			if previous != null:
				element.setElementVisibility(previous, data["can_go_previous"])
		
		element.executeAnimation()
