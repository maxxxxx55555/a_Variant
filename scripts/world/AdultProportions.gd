extends SkeletonModifier3D
## Keep licensed animation while reducing exaggerated childlike head proportions.
func _process_modification() -> void:
	var skeleton:Skeleton3D= get_skeleton()
	if not skeleton: return
	var head:int= skeleton.find_bone("head")
	if head >= 0: skeleton.set_bone_pose_scale(head,Vector3.ONE*0.65)
	var hips:int= skeleton.find_bone("hips")
	if hips >= 0: skeleton.set_bone_pose_scale(hips,Vector3(0.78,1.12,0.8))
