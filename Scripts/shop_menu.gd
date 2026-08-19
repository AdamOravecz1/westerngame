extends Control

@onready var player = get_tree().get_first_node_in_group("Player")
@onready var shop_menu = player.get_node("CanvasLayer/ShopMenu")
@onready var hover_rect: ColorRect = $HoverRect
var foundation = null

const BLACKSMITHCOST := 10
const STORECOST := 10
const CARPENTERCOST := 10
const BARRACKSCOST := 10
const MINECOST := 10
const SALOONCOST := 10

func _process(_delta: float) -> void:
	if hover_rect and hover_rect.visible:
		hover_rect.global_position = get_viewport().get_mouse_position() + Vector2(10, 10)

func shop(found):
	foundation = found
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.in_shop = true
		shop_menu.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.in_shop = false
		shop_menu.visible = false


func _on_black_smith_pressed() -> void:
	if player.money >= BLACKSMITHCOST:
		foundation.build("res://Scenes/half_black_smith.tscn")
		$VBoxContainer/BlackSmith.queue_free()


func _on_store_pressed() -> void:
	if player.money >= STORECOST:
		foundation.build("res://Scenes/half_store.tscn")
		$VBoxContainer/Store.queue_free()

func _on_carpenter_pressed() -> void:
	if player.money >= CARPENTERCOST:
		foundation.build("res://Scenes/half_carpenter.tscn")
		$VBoxContainer/Carpenter.queue_free()


func _on_barracks_pressed() -> void:
	if player.money >= BARRACKSCOST:
		foundation.build("res://Scenes/half_barracks.tscn")
		$VBoxContainer/Barracks.queue_free()


func _on_mine_pressed() -> void:
	if player.money >= MINECOST:
		foundation.build("res://Scenes/half_mine.tscn")
		$VBoxContainer/Mine.queue_free()


func _on_saloon_pressed() -> void:
	if player.money >= SALOONCOST:
		foundation.build("res://Scenes/half_saloon.tscn")
		$VBoxContainer/Saloon.queue_free()


func _on_black_smith_mouse_entered() -> void:
	if not hover_rect.visible:
		hover_rect.visible = true
		$HoverRect/RichTextLabel.text = "Unlocks shotgun\n Cost: " + str(BLACKSMITHCOST)


func _on_black_smith_mouse_exited() -> void:
	hover_rect.visible = false


func _on_store_mouse_entered() -> void:
	if not hover_rect.visible:
		hover_rect.visible = true
		$HoverRect/RichTextLabel.text = "Gives ammo after every wave\n Cost: " + str(BLACKSMITHCOST)


func _on_store_mouse_exited() -> void:
	hover_rect.visible = false


func _on_carpenter_mouse_entered() -> void:
	if not hover_rect.visible:
		hover_rect.visible = true
		$HoverRect/RichTextLabel.text = "Allows the building of covers\n Cost: " + str(BLACKSMITHCOST)


func _on_carpenter_mouse_exited() -> void:
	hover_rect.visible = false


func _on_barracks_mouse_entered() -> void:
	if not hover_rect.visible:
		hover_rect.visible = true
		$HoverRect/RichTextLabel.text = "Produces soldiers that fight on your side\n Cost: " + str(BLACKSMITHCOST)


func _on_barracks_mouse_exited() -> void:
	hover_rect.visible = false


func _on_mine_mouse_entered() -> void:
	if not hover_rect.visible:
		hover_rect.visible = true
		$HoverRect/RichTextLabel.text = "Extra money after each wave\n Cost: " + str(BLACKSMITHCOST)


func _on_mine_mouse_exited() -> void:
	hover_rect.visible = false


func _on_saloon_mouse_entered() -> void:
	if not hover_rect.visible:
		hover_rect.visible = true
		$HoverRect/RichTextLabel.text = "Refils some health after each wave\n Cost: " + str(BLACKSMITHCOST)


func _on_saloon_mouse_exited() -> void:
	hover_rect.visible = false
