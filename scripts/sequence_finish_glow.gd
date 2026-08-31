extends Control
class_name SequenceFinishGlow


var glow_color := Color(0.55, 0.85, 1.0, 1.0):
	set(value):
		glow_color = value
		queue_redraw()

var radius := 18.0:
	set(value):
		radius = maxf(0.0, value)
		queue_redraw()

var glow_alpha := 0.0:
	set(value):
		glow_alpha = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var outer := Color(glow_color.r, glow_color.g, glow_color.b, glow_alpha * 0.20)
	var middle := Color(glow_color.r, glow_color.g, glow_color.b, glow_alpha * 0.34)
	var inner := Color(1.0, 1.0, 1.0, glow_alpha * 0.44)
	draw_circle(center, radius, outer)
	draw_circle(center, radius * 0.58, middle)
	draw_circle(center, radius * 0.22, inner)
	draw_arc(center, radius * 0.88, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, glow_alpha * 0.72), 3.0, true)
