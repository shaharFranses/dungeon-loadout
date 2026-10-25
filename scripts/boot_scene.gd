extends Control

const Art_ = preload("res://scripts/art.gd")
## art-a7: Pikeydi studio intro (pikeydi-logo/godot/INTEGRATION.md, overlay mode A)
const PkdIntro := preload("res://pkd_intro/pkd_intro.tscn")

var _intro: Node
var _intro_vis := 0
var _intro_t0 := 0

func _ready():
	$ColorRect.color = preload("res://scripts/art.gd").BG   # art-a5: palette BG (was #1A1A26)
	preload("res://scripts/art.gd").add_backdrop(self, 1)   # a5.1: same backdrop as every scene
	if RunState.portrait:
		# art-a5: phone font is bigger; the title column spans the screen and wraps
		var w := get_viewport_rect().size.x - 40.0
		$VBox.offset_left = -w / 2.0
		$VBox.offset_right = w / 2.0
		$VBox/Title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# the boot scene is in the tree before RunState hooks node_added, so apply the
		# phone font scale and tap floor here directly
		for n in [$VBox/Title, $VBox/BeginButton]:
			RunState._portrait_scene_fonts(n)
		preload("res://scripts/art.gd").tap($VBox/BeginButton)
	if not RunState.portrait:
		for n in [$VBox/Title, $VBox/BeginButton]:
			RunState._portrait_scene_fonts(n)   # art-a6: tier sizes on desktop too
	for n in [$VBox/Title, $VBox/BeginButton]:
		RunState._text_pass(n)   # boot is in the tree before RunState hooks node_added
	RunState.reset_run()
	if RunState.intro_enabled():
		# the title screen builds underneath; the intro (CanvasLayer 128) blocks input and
		# frees itself; nothing interactive starts until `finished`
		var intro := PkdIntro.instantiate()
		_intro = intro
		intro.started.connect(_on_intro_visible)   # PKD v1.1: clock starts at the first draw
		intro.finished.connect(_on_intro_finished)
		_intro_t0 = Time.get_ticks_msec()
		add_child(intro)
		print("PKD_INTRO_STARTED viewport=", get_viewport().get_visible_rect().size)
	else:
		_on_intro_finished()


## art-a7: start of play. The game has no music yet; when it gets some, start it here.
func _on_intro_visible() -> void:
	_intro_vis = Time.get_ticks_msec()
	print("PKD_INTRO_VISIBLE ms_after_add=", _intro_vis - _intro_t0)


func _on_intro_finished() -> void:
	# art-a7.1: the navy default clear colour (PKD INTEGRATION 3) is for the boot splash and
	# the intro only; every game scene runs on the #2B2329 palette BG from here on
	RenderingServer.set_default_clear_color(preload("res://scripts/art.gd").BG)
	if _intro_t0 > 0:
		var el: float = _intro.get_elapsed() if is_instance_valid(_intro) else -1.0
		print("PKD_INTRO_FINISHED ms=", Time.get_ticks_msec() - _intro_t0,
				" visible_ms=", (Time.get_ticks_msec() - _intro_vis) if _intro_vis > 0 else -1,
				" elapsed=", snappedf(el, 0.001))
	RunState.qa_dump_ui(self, "boot")
	if RunState.qa_mode and RunState.qa_scene != "":
		_qa_jump(RunState.qa_scene)


## art-a5 QA only (?qa=1&scene=...): open one screen directly for layout screenshots.
func _qa_jump(scene: String):
	await get_tree().create_timer(0.5).timeout
	match scene:
		"result_win", "result":   # art-a7: plain "result" (was unmatched: stayed on boot) = a win
			RunState.acts_cleared = RunState.FINAL_ACT
			RunState.change_scene("res://scenes/result.tscn")
		"result_loss":
			RunState.player_hp = 0
			RunState.change_scene("res://scenes/result.tscn")
		"shop":
			RunState.gold = 120
			RunState.change_scene("res://scenes/shop_smith.tscn")
		"skill":
			RunState.talent_pick_source = "skill"
			RunState.change_scene("res://scenes/skill_pick.tscn")
		"rest":
			RunState.player_hp = 20
			RunState.change_scene("res://scenes/rest.tscn")
		"reward", "reward_boss":
			RunState.current_node_type = "boss" if scene == "reward_boss" else "elite"
			RunState.on_combat_won()
			RunState.change_scene("res://scenes/reward.tscn")
		"camp":
			RunState.change_scene("res://scenes/camp.tscn")

func _on_begin_pressed():
	# Stage D: the camp (Renown unlocks, Ascension) comes before every run.
	RunState.change_scene("res://scenes/camp.tscn")
