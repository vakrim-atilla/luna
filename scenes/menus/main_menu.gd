extends Control

func _ready() -> void:
	print("Main menu is ready")


func _on_quit_button_pressed() -> void:
	queue_free()
