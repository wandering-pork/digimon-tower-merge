class_name StarterSelection
extends Control
## UI screen for selecting the starting Digimon partner.
## Displays 8 starter options based on GDD: Koromon, Tsunomon, Tokomon, Gigimon,
## Tanemon, DemiVeemon, Pagumon, Viximon.

signal starter_selected(digimon_data: DigimonData)

## Starter configuration data
const STARTERS = [
	{
		"name": "Koromon",
		"resource": "res://resources/digimon/in_training/koromon.tres",
		"attribute": "Vaccine",
		"family": "Dragon's Roar",
		"evolution_preview": "Agumon -> Greymon"
	},
	{
		"name": "Tsunomon",
		"resource": "res://resources/digimon/in_training/tsunomon.tres",
		"attribute": "Data",
		"family": "Nature Spirits",
		"evolution_preview": "Gabumon -> Garurumon"
	},
	{
		"name": "Tokomon",
		"resource": "res://resources/digimon/in_training/tokomon.tres",
		"attribute": "Vaccine",
		"family": "Virus Busters",
		"evolution_preview": "Patamon -> Angemon"
	},
	{
		"name": "Gigimon",
		"resource": "res://resources/digimon/in_training/gigimon.tres",
		"attribute": "Virus",
		"family": "Dragon's Roar",
		"evolution_preview": "Guilmon -> Growlmon"
	},
	{
		"name": "Tanemon",
		"resource": "res://resources/digimon/in_training/tanemon.tres",
		"attribute": "Data",
		"family": "Jungle Troopers",
		"evolution_preview": "Palmon -> Togemon"
	},
	{
		"name": "DemiVeemon",
		"resource": "res://resources/digimon/in_training/demiveemon.tres",
		"attribute": "Free",
		"family": "Dragon's Roar",
		"evolution_preview": "Veemon -> ExVeemon"
	},
	{
		"name": "Pagumon",
		"resource": "res://resources/digimon/in_training/pagumon.tres",
		"attribute": "Virus",
		"family": "Nightmare Soldiers",
		"evolution_preview": "DemiDevimon -> Devimon"
	},
	{
		"name": "Viximon",
		"resource": "res://resources/digimon/in_training/viximon.tres",
		"attribute": "Data",
		"family": "Nature Spirits",
		"evolution_preview": "Renamon -> Kyubimon"
	}
]

## Node references
@onready var starter_grid: GridContainer = $VBoxContainer/StarterGrid

## Loaded DigimonData resources
var _starter_data: Array[DigimonData] = []

func _ready() -> void:
	_load_starter_data()
	_setup_starter_cards()

func _load_starter_data() -> void:
	## Load all starter DigimonData resources
	for starter_info in STARTERS:
		var resource_path = starter_info["resource"]
		if ResourceLoader.exists(resource_path):
			var data = load(resource_path) as DigimonData
			if data:
				_starter_data.append(data)
			else:
				ErrorHandler.log_warning("StarterSelection", "Failed to load starter: %s" % resource_path)
				_starter_data.append(null)
		else:
			ErrorHandler.log_warning("StarterSelection", "Starter resource not found: %s" % resource_path)
			_starter_data.append(null)

func _setup_starter_cards() -> void:
	## Set up each starter card with data and connect buttons
	for i in range(STARTERS.size()):
		var card_name = "Starter%d" % (i + 1)
		var card = starter_grid.get_node_or_null(card_name)
		if not card:
			continue

		var starter_info = STARTERS[i]
		var vbox = card.get_node_or_null("VBox")
		if not vbox:
			continue

		# Update card labels
		var name_label = vbox.get_node_or_null("Name")
		if name_label:
			name_label.text = starter_info["name"]

		var info_label = vbox.get_node_or_null("Info")
		if info_label:
			info_label.text = "%s | %s" % [starter_info["attribute"], starter_info["family"]]

		var evolution_label = vbox.get_node_or_null("Evolution")
		if evolution_label:
			evolution_label.text = "-> %s" % starter_info["evolution_preview"]

		# Load sprite if available
		var sprite_rect = vbox.get_node_or_null("Sprite")
		if sprite_rect:
			var sprite_path = "res://assets/sprites/digimon/%s.png" % starter_info["name"].to_lower()
			if ResourceLoader.exists(sprite_path):
				sprite_rect.texture = load(sprite_path)
			else:
				# Create placeholder texture
				sprite_rect.texture = _create_placeholder_texture(starter_info["attribute"])

		# Connect select button
		var select_btn = vbox.get_node_or_null("SelectBtn")
		if select_btn:
			# Disconnect any existing connections first
			if select_btn.pressed.is_connected(_on_starter_selected):
				select_btn.pressed.disconnect(_on_starter_selected)
			select_btn.pressed.connect(_on_starter_selected.bind(i))

func _create_placeholder_texture(attribute: String) -> ImageTexture:
	## Create a colored placeholder based on attribute
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var color: Color

	match attribute:
		"Vaccine":
			color = Color(0.2, 0.6, 1.0)
		"Data":
			color = Color(0.2, 0.8, 0.2)
		"Virus":
			color = Color(0.8, 0.2, 0.2)
		"Free":
			color = Color(0.8, 0.8, 0.2)
		_:
			color = Color(0.5, 0.5, 0.5)

	for x in range(64):
		for y in range(64):
			if x < 4 or x > 59 or y < 4 or y > 59:
				img.set_pixel(x, y, color.darkened(0.3))
			else:
				img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)

func _on_starter_selected(index: int) -> void:
	## Handle starter selection
	if index < 0 or index >= _starter_data.size():
		ErrorHandler.log_error("StarterSelection", "Invalid starter index: %d" % index)
		return

	var data = _starter_data[index]
	if data:
		starter_selected.emit(data)
	else:
		ErrorHandler.log_error("StarterSelection", "No data for starter index: %d" % index)

## Get the starter DigimonData by index
func get_starter_data(index: int) -> DigimonData:
	if index >= 0 and index < _starter_data.size():
		return _starter_data[index]
	return null

## Get the starter DigimonData by name
func get_starter_by_name(digimon_name: String) -> DigimonData:
	for i in range(STARTERS.size()):
		if STARTERS[i]["name"].to_lower() == digimon_name.to_lower():
			return _starter_data[i]
	return null
