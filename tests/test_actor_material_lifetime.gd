extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	for batch in 8:
		var group:=Node3D.new()
		root.add_child(group)
		for i in 10: MarchAssets.character(group,i%2==0,true)
		await process_frame
		group.queue_free()
		await process_frame
		await process_frame
	print("ACTOR MATERIAL LIFETIME: PASS")
	quit()
