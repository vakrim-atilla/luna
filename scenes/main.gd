extends Node

@export var SplashScreen: PackedScene
@export var MainMenu: PackedScene



func _ready():
	await run_scene(SplashScreen)
	print("Splash Screen is gone")
	await run_scene(MainMenu)
	print("Bye bye!")
	get_tree().quit()

	

func run_scene(packed_scene: PackedScene):
	var scene = packed_scene.instantiate()
	add_child.call_deferred(scene)
	await(scene.child_exiting_tree)
