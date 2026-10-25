extends Control
## Camp between runs (LOOP_SPEC section 5, Stage D): spend Renown on unlocks,
## pick an Ascension level, then start the run. With the "start_item" unlock,
## Start Run first offers 1 Common item per slot.

const GearData = preload("res://scripts/gear_data.gd")
const UiUtil = preload("res://scripts/ui_util.gd")

var phase: String = "camp"
var options: Array = []


func _ready():
	DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/name"))
	_build()


func _clear():
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _build():
	_clear()
	if phase == "start_item":
		_build_start_item()
	else:
		_build_camp()


func _build_camp():
	var meta: Dictionary = RunState.meta
	var box := UiUtil.make_screen(self, "Camp")
	box.add_child(UiUtil.make_label("Renown: %d    (earned in total: %d, runs: %d, wins: %d)" % [
			int(meta.renown), int(meta.renown_total), int(meta.runs), int(meta.wins)], 18, UiUtil.GOLD))
	for unlock_id in RunState.UNLOCK_ORDER:
		var def: Dictionary = RunState.UNLOCKS[unlock_id]
		box.add_child(UiUtil.make_label(String(def.text), 14, UiUtil.DIM))
		var button: Button
		if RunState.is_unlocked(unlock_id):
			button = UiUtil.make_button("%s: unlocked" % def.name, func(): pass, 460.0)
			button.disabled = true
		else:
			# art-a6.1: explicit 2-line text on phones ("Unlock Arcane talent tree" / "30 Renown")
			var fmt := "Unlock %s\n%d Renown" if RunState.portrait else "Unlock %s (%d Renown)"
			button = UiUtil.make_button(fmt % [def.name, def.cost], _on_unlock.bind(unlock_id), 460.0)
			button.disabled = not RunState.can_buy_unlock(unlock_id)
		box.add_child(button)
	var max_asc := int(meta.max_ascension)
	if max_asc > 0:
		var level := clampi(int(meta.ascension), 0, max_asc)
		box.add_child(UiUtil.make_label("Ascension %d of %d: enemies have +%d%% HP" % [
				level, max_asc, roundi(level * RunState.ASCENSION_HP_STEP * 100.0)], 18, UiUtil.HP))
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		var down := UiUtil.make_button("Ascension -", _on_ascension.bind(level - 1), 170.0)
		down.disabled = level <= 0
		var up := UiUtil.make_button("Ascension +", _on_ascension.bind(level + 1), 170.0)
		up.disabled = level >= max_asc
		row.add_child(down)
		row.add_child(up)
		box.add_child(row)
	else:
		box.add_child(UiUtil.make_label("Ascension unlocks after your first win.", 15, UiUtil.DIM))
	if not RunState.meta_storage_ok:
		box.add_child(UiUtil.make_label("Progress can't be saved in this browser; it lasts until you close the page.", 14, UiUtil.HP))
	box.add_child(UiUtil.with_icon(UiUtil.make_button("Start Run", _on_start), preload("res://scripts/art.gd").tex(preload("res://scripts/art.gd").HERO, 2)))
	RunState.qa_dump_ui(self, "camp", {"phase": "camp", "meta": meta, "storage_ok": RunState.meta_storage_ok})


func _build_start_item():
	var box := UiUtil.make_screen(self, "Choose a starting item")
	box.add_child(UiUtil.make_status(16, UiUtil.GOLD))
	for item in options:
		box.add_child(UiUtil.make_label(GearData.describe(item), 16, GearData.RARITY_COLORS[item.rarity]))
		box.add_child(UiUtil.with_icon(UiUtil.make_button("Take %s" % item.name, _on_take.bind(item)), preload("res://scripts/art.gd").item_tex(item, 2)))
	box.add_child(UiUtil.make_button("No item", _on_take.bind({})))
	RunState.qa_dump_ui(self, "camp", {"phase": "start_item", "offers": options})


func _on_unlock(unlock_id: String):
	if RunState.buy_unlock(unlock_id):
		_build()


func _on_ascension(level: int):
	RunState.set_ascension(level)
	_build()


func _on_start():
	RunState.reset_run()
	if RunState.is_unlocked("start_item"):
		options = RunState.start_item_options()
		phase = "start_item"
		_build()
		return
	RunState.change_scene("res://scenes/map.tscn")


func _on_take(item: Dictionary):
	RunState.take_start_item(item)
	RunState.change_scene("res://scenes/map.tscn")
