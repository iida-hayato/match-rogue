extends Control

signal reward_chosen(reward: Dictionary)

@onready var rewards_container: HBoxContainer = $VBox/RewardsContainer

func initialize_rewards(rewards: Array[Dictionary]) -> void:
	for r in rewards:
		var btn = Button.new()
		btn.text = r.display_name
		btn.custom_minimum_size = Vector2(200, 300)
		rewards_container.add_child(btn)
		btn.pressed.connect(_on_reward_pressed.bind(r))

func _on_reward_pressed(reward: Dictionary) -> void:
	reward_chosen.emit(reward)
