extends SubViewportContainer
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#adjust_viewports()
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#adjust_viewports()
#
#func adjust_viewports() -> void:
	## Get the number of child viewports
	#var viewport_count = get_child_count()
	#
	#if viewport_count == 0:
		#return
	#
	## Calculate the new size for each viewport
	#var container_size = size
	#var new_width = container_size.x / viewport_count
	#var new_height = container_size.y
	#
	## Adjust the size of each child control containing a viewport
	#for i in range(viewport_count):
		#var viewport_container = get_child(i)
		#if viewport_container is Control:
			#viewport_container.rect_min_size = Vector2(new_width, new_height)
			#viewport_container.rect_position = Vector2(i * new_width, 0)
#
## Optional signal handlers if needed for adding/removing viewports dynamically
#func _on_viewport_added():
	#adjust_viewports()
#
#func _on_viewport_removed():
	#adjust_viewports()
