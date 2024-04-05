extends MarginContainer

@onready var _category_label_container : VBoxContainer = $HBoxContainer/Categories/VBoxContainer/ScrollContainer/HBoxContainer
@onready var _records_grid_container : GridContainer = $HBoxContainer/VBoxContainer/Records/MarginContainer/GridContainer
@onready var _select_starting_record_btn : Button = $HBoxContainer/Categories/VBoxContainer/SelectStartingRecord
@onready var _set_starting_record_btn : Button = $HBoxContainer/VBoxContainer/Info/VBoxContainer/VBoxContainer/SetStartingRecord

@onready var _info_panel : PanelContainer = $HBoxContainer/VBoxContainer/Info
@onready var _info_name : Label = $HBoxContainer/VBoxContainer/Info/VBoxContainer/FileName
@onready var _info_size : Label = $HBoxContainer/VBoxContainer/Info/VBoxContainer/Info/Size
@onready var _info_length : Label = $HBoxContainer/VBoxContainer/Info/VBoxContainer/Info/Length
@onready var _info_date : Label = $HBoxContainer/VBoxContainer/Info/VBoxContainer/Info/Date

const _records_folder_path : String = "res://addons/gameplay_recorder_interface/records/"
const _replay_file_path : String = "res://addons/gameplay_recorder_interface/replay_file.txt"
const _category_label_scene : PackedScene = preload("res://addons/gameplay_recorder_interface/components/category_label.tscn")
const _record_grid_btn_scene : PackedScene = preload("res://addons/gameplay_recorder_interface/components/record_grid_button.tscn")

var _records : Dictionary # {category:{file_name:{entries}, ..}, ..}
var _selected_category : String
var _selected_file : String
var _starting_record_file : String

const _starting_record_set_text : String = "Set As Starting Record"
const _starting_record_remove_text : String = "Remove Starting Record"


func _ready():
	_select_starting_record_btn.hide()
	_info_panel.hide()
	
	# read all records, sort by category
	var dir : DirAccess = DirAccess.open(_records_folder_path)
	dir.include_hidden = false; dir.include_navigational = false
	dir.list_dir_begin()
	var record_name : String = dir.get_next()
	while record_name.is_empty() == false:
		if dir.current_is_dir() == false && record_name.get_extension() == "json":
			var file : FileAccess = FileAccess.open(_records_folder_path + "/" + record_name, FileAccess.READ)
			# records stored in _records contain same entries as in the json file (see gameplay_recorder.gd) except for "input"
			# which isn't needed. "date" is added after extracting the date from the file name. "file_size" as well
			# TODO: the whole "date" extracting thing is unnecessary just store it in the json file
			var record : Dictionary = JSON.parse_string(file.get_as_text())
			record.erase("input")
			
			record["file_size"] = file.get_length()
			
			# get date from file name
			var opening_braket_idx : int = record_name.find("(")+1
			var closing_braket_idx : int = record_name.find(")")
			if opening_braket_idx == -1 || closing_braket_idx == -1:
				push_error("File name doesn't follow the documented format (see gameplay_recorder.gd)")
				record_name = dir.get_next()
				continue
			record["date"] = record_name.substr(opening_braket_idx, closing_braket_idx - opening_braket_idx)
			
			var record_category : String = record["category"]
			if _records.has(record_category) == false: _records[record_category] = {}
			_records[record_category][record_name] = record
			
		
		record_name = dir.get_next()
	
	# generate categories
	for key in _records.keys():
		var category : ScrollContainer = _category_label_scene.instantiate()
		_category_label_container.add_child(category)
		category.setup(key)
		category.pressed.connect(_on_category_pressed.bind(key))

func apply_changed():
	# save selected file to replay_file or clear the file
	# settings the file to replay is the main purpose of this plugin
	var file : FileAccess = FileAccess.open("_replay_file_path", FileAccess.WRITE)
	if _selected_file:
		file.store_string(_records_folder_path + "/" + _selected_file)
	file.close()

func _on_category_pressed(category : String):
	if category == _selected_category: return
	_selected_category = category
	
	_selected_file = ""
	_info_panel.hide()
	for child in _records_grid_container.get_children():
		child.queue_free()
	
	for file_name : String in _records[category].keys():
		var grid_btn : Button = _record_grid_btn_scene.instantiate()
		_records_grid_container.add_child(grid_btn)
		grid_btn.setup(file_name)
		grid_btn.pressed.connect(_on_grid_record_btn_pressed.bind(file_name))

func _on_grid_record_btn_pressed(file_name : String):
	_selected_file = file_name
	_info_panel.show()
	
	var file_record : Dictionary = _records[_selected_category][file_name]
	_info_name.text = file_name
	_info_size.text = "Size: " + str(file_record["file_size"]) + "bytes"
	_info_length.text = "Length: " + str(file_record["length"]) + "s"
	_info_date.text = "Date: " + file_record["date"]
	
	if file_name != _starting_record_file:
		_set_starting_record_btn.text = _starting_record_set_text
	else:
		_set_starting_record_btn.text = _starting_record_remove_text

func _on_set_starting_record_pressed():
	if _selected_file != _starting_record_file:
		_starting_record_file = _selected_file
		_select_starting_record_btn.show()
		
		_set_starting_record_btn.text = _starting_record_remove_text
	
	else:
		_starting_record_file = ""
		_select_starting_record_btn.hide()
		_set_starting_record_btn.text = _starting_record_set_text

func _on_select_starting_record_pressed():
	# open category of the starting file then scroll so grid button of that file is shown
	pass
