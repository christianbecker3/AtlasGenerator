extends Control

@onready var dialog_box: AcceptDialog = %AcceptDialog
@onready var line_edit: LineEdit = %LineEdit
@onready var file_dialog: FileDialog = %FileDialog
@onready var horizontal_images: SpinBox = %HorizontalImages
@onready var square_image: CheckButton = %SquareImage
var path: String
var output_filename: String = "Atlas"

func select_folder() -> void:
	file_dialog.popup()

func setup_folder(input_path: String) -> void:
	path = input_path
	line_edit.text = path
	
func update_filename(new_text: String) -> void:
	output_filename = new_text

func generate_atlas() -> void:
	if path == "" or path == null or !DirAccess.dir_exists_absolute(path):
		show_popup("Please select a valid filepath to continue.")
		return
	if output_filename == "" or output_filename == null:
		show_popup("Please use a valid output filename.")
		return
	var files: PackedStringArray = DirAccess.open(path).get_files()
	var filtered_files: Array[Image]
	for file in files:
		if file.get_extension() == "png" and file.get_slice(".", 0) != output_filename:
			filtered_files.append(load_file(file, path))
	var image_size: int = filter_largest_image_resolution_of_images(filtered_files).x
	var x_size: int = horizontal_images.value
	var y_size: int = ceil(float(filtered_files.size()) / float(x_size))
	if filtered_files.size() < x_size:
		show_popup("Please reduce the horizontal size to continue.")
		return
	var is_square_image: bool = square_image.button_pressed
	var atlas: Image = Image.new()
	if is_square_image:
		atlas = Image.create(x_size * image_size, x_size * image_size, true, Image.FORMAT_RGBA8)
	else:
		atlas = Image.create(x_size * image_size, y_size * image_size, true, Image.FORMAT_RGBA8)
	var x_pos: int = -1
	var y_pos: int = -1
	for i in range(filtered_files.size()):
		var image: Image = filtered_files[i]
		x_pos += 1
		if fmod(i, x_size) == 0:
			y_pos += 1
			x_pos = 0
		var offset: Vector2i = Vector2i.ZERO
		var center_anchor_position: Vector2i = (Vector2i(image_size, image_size) - image.get_size()) / 2
		var image_position: Vector2i = Vector2i(x_pos * image_size + center_anchor_position.x, y_pos * image_size + center_anchor_position.y)
		atlas.blit_rect(image, Rect2(Vector2i.ZERO, image.get_size()), image_position)
	if atlas.save_png(path + "\\" + output_filename + ".png") != 0:
		show_popup("An error occurred while saving the file.")
		return
	show_popup("Atlas was successfully created.")

func load_file(filename: String, path: String) -> Image:
	var img: Image = Image.load_from_file(path + "\\" + filename)
	img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img

func show_popup(text: String) -> void:
	dialog_box.dialog_text = text
	dialog_box.popup()

func filter_largest_image_resolution_of_images(images: Array[Image]) -> Vector2i:
	var resolution: Vector2i = Vector2i.ZERO
	for image in images:
		if resolution.length() < image.get_size().length():
			resolution = image.get_size()
	return resolution
