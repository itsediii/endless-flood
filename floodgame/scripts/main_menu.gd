extends Control


func _ready() -> void:
	$MainMenuUI/MenuPositioner/Buttons/PlayButton.pressed.connect(_on_play_pressed)
	$MainMenuUI/MenuPositioner/Buttons/QuitButton.pressed.connect(_on_quit_pressed)

func _process(delta: float) -> void:
	pass


func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
	LevelMusic.play()
	pass

func _on_quit_pressed():
	get_tree().quit()
