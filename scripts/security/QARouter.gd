extends RefCounted
# Custom features are fixed in the exported pack; env alone never unlocks QA.
static func authorized() -> bool:
	return OS.has_feature("qa_verifier") and OS.get_environment("GAME_QA")=="1"

static func request(host:Node) -> bool:
	var arguments:=OS.get_cmdline_user_args()
	var requested:bool=arguments.has("--verify-build") or arguments.has("--military")
	if not requested:return false
	if not authorized() or not arguments.has("--verify-build"):
		printerr("QA arguments require a private QA export and GAME_QA=1")
		host.get_tree().quit(64)
		return true
	# Dynamic path avoids an export dependency in the physically filtered public pack.
	var script:Script=load("res://scripts/verification/CampaignRoute.gd")
	if not script:
		host.get_tree().quit(65)
		return true
	var route:Node=script.new()
	host.get_tree().root.add_child.call_deferred(route)
	return true
