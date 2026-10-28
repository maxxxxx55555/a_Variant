extends "res://tests/AudioCleanTree.gd"
const Icons=preload("res://scripts/ui/ItemIcons.gd")
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    var kinds:Dictionary={}
    for directory:String in ["weapons","armors","potions"]:
        for filename:String in DirAccess.get_files_at("res://data/"+directory):
            if not filename.ends_with(".tres"):continue
            var item:ItemData=load("res://data/"+directory+"/"+filename) as ItemData
            check(item!=null,"Item resource loads: "+filename)
            if item==null:continue
            var icon:Texture2D=Icons.for_item(item)
            check(icon!=null and icon.get_width()>=32 and icon.get_height()>=32,"Usable icon for "+filename)
            if icon!=null:kinds[icon.resource_path]=true
    check(kinds.size()>=10,"Items have distinct recognizable icon categories")
    var state:Node=root.get_node("GameState")
    state.inventory.clear()
    check(state.add_item(load("res://data/weapons/iron_sword.tres"),1),"Sword added to actual inventory")
    check(state.add_item(load("res://data/potions/health_potion.tres"),2),"Potion added to actual inventory")
    var panel:Control=load("res://scenes/ui/inventory_ui.tscn").instantiate()
    root.add_child(panel);await process_frame
    check(panel.item_list.item_count==2,"Inventory lists both actual items")
    if panel.item_list.item_count==2:
        check(panel.item_list.get_item_icon(0)!=null and panel.item_list.get_item_icon(1)!=null,"Actual inventory rows show icons")
        check(panel.item_list.get_item_icon(0)!=panel.item_list.get_item_icon(1),"Sword and potion remain visually distinct")
    panel.queue_free();await process_frame
    print("RPG ICON COVERAGE: ","PASS" if failures==0 else "FAIL")
    finish_test(0 if failures==0 else 1)
