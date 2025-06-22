extends Node

@export var SplashScreen: PackedScene
@export var MainMenu: PackedScene
@export var GameMenu: PackedScene
@export var GameLevels: Array[PackedScene]

signal scene_finished(next_scene: PackedScene)

func _ready():
	var scene = SplashScreen.instantiate()
	add_child(scene)
	pass

#func _on_scene_finished(next_scene: PackedScene):
#	next_scene.instantiate().add_child()
