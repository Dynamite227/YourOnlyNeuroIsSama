class_name Traverse

static func directory(path: String) -> Array:
	var d := Directory.new()
	var dir := d.open(path)
	if dir != OK:
		return []

	var files: Array = []

	d.list_dir_begin()
	var file_name := d.get_next()
	while file_name != "":
		var file_path := path.plus_file(file_name)

		if d.current_is_dir():
			files.append_array(directory(file_path))
		else:
			files.append(file_path)

		file_name = d.get_next()

	d.list_dir_end()

	return files

static func directories(paths: Array) -> Array:
	var files: Array = []

	for path in paths:
		files.append_array(directory(path))

	return files
