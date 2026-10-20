extends Control
## Draws the lines between map nodes. Each segment is [from, to, color, width].

var segments: Array = []


func _draw():
	for seg in segments:
		draw_line(seg[0], seg[1], seg[2], seg[3], true)
