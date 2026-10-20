extends RefCounted
## Meta progress (LOOP_SPEC section 5): Renown, unlocks and Ascension.
## On the web it lives in window.localStorage (portal-safe, no account).
## Elsewhere (editor, headless tests) it falls back to a user:// JSON file.

const KEY := "dungeon_loadout_meta_v1"
const FILE := "user://meta_v1.json"
const INT_KEYS := ["version", "renown", "renown_total", "runs", "wins", "ascension", "max_ascension"]


static func default_meta() -> Dictionary:
	return {
		"version": 1,
		"renown": 0,         # unspent
		"renown_total": 0,   # ever earned
		"runs": 0,
		"wins": 0,
		"unlocks": {},       # unlock id -> true
		"ascension": 0,      # level chosen for the next run
		"max_ascension": 0,  # highest level you may pick (0 until the first win)
	}


static func _normalize(raw) -> Dictionary:
	var meta := default_meta()
	if typeof(raw) == TYPE_DICTIONARY:
		for k in raw:
			meta[k] = raw[k]
	for k in INT_KEYS:
		meta[k] = int(meta.get(k, 0))
	if typeof(meta.unlocks) != TYPE_DICTIONARY:
		meta.unlocks = {}
	return meta


static func load_meta() -> Dictionary:
	var text := ""
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval(
				"(function(){try{return window.localStorage.getItem('%s')||''}catch(e){return ''}})()" % KEY, true)
		if typeof(v) == TYPE_STRING:
			text = v
	elif FileAccess.file_exists(FILE):
		text = FileAccess.get_file_as_string(FILE)
	if text == "":
		return default_meta()
	return _normalize(JSON.parse_string(text))


## Returns false when storage is unavailable (e.g. a sandboxed iframe); the game keeps
## working with in-memory progress for this session.
static func save_meta(meta: Dictionary) -> bool:
	var text := JSON.stringify(meta)
	if OS.has_feature("web"):
		var ok = JavaScriptBridge.eval(
				"(function(){try{window.localStorage.setItem('%s', %s);return 'ok'}catch(e){return 'fail'}})()"
				% [KEY, JSON.stringify(text)], true)
		# Compare as text: the bridge's return type for JS booleans is not reliable.
		return typeof(ok) == TYPE_STRING and String(ok) == "ok"
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.close()
	return true


static func clear_meta():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{window.localStorage.removeItem('%s')}catch(e){}})()" % KEY, true)
	elif FileAccess.file_exists(FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FILE))
