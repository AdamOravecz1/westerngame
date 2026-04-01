extends GutTest

var Player = preload("res://Scenes/player.tscn")
var player

func before_each():
	player = Player.instantiate()
	add_child(player)
	await get_tree().process_frame

func after_each():
	player.queue_free()
	
func test_take_damage_reduces_health():
	var initial_health = player.health
	
	player.take_damage(Vector3(1, 0, 0))
	
	assert_eq(player.health, initial_health - 5)
	
func test_health_does_not_exceed_100():
	player.health = 100
	player._on_health_pressed()
	
	assert_lte(player.health, 100)
	
func test_add_money_increases_money():
	player.money = 0
	
	player.AddMoney(10)
	
	assert_eq(player.money, 10)
	
func test_add_money_decreases_money():
	player.money = 10
	
	player.AddMoney(-5)
	
	assert_eq(player.money, 5)
	
func test_revolver_ammo_purchase():
	player.money = 5
	player.free_bullets = 0
	
	player._on_ammo_pressed()
	
	assert_eq(player.free_bullets, 1)
	assert_eq(player.money, 4)

func test_shotgun_ammo_purchase():
	player.money = 5
	player.free_shotgun = 0
	
	player._on_shutgun_ammo_pressed()
	
	assert_eq(player.free_shotgun, 1)
	assert_eq(player.money, 4)

func test_buy_dynamite():
	player.money = 5
	player.dynamite_amount = 0
	
	player._on_dynamyte_pressed()
	
	assert_eq(player.dynamite_amount, 1)
	assert_eq(player.money, 2)
	
func test_throw_dynamite_reduces_amount():
	player.dynamite_amount = 3
	
	Input.action_press("throw")
	player._physics_process(0.016)
	Input.action_release("throw")
	
	assert_eq(player.dynamite_amount, 2)
	
func test_weapon_switch_changes_index():
	var initial = player.selected_weapon
	
	await player.switch_weapon(1)
	
	assert_ne(player.selected_weapon, initial)
	
func test_weapon_index_wraps():
	player.selected_weapon = len(player.weapons) - 1
	
	await player.switch_weapon(1)
	
	assert_eq(player.selected_weapon, 0)
	
func test_reload_not_triggered_without_ammo():
	player.free_bullets = 0
	
	Input.action_press("reload")
	player._physics_process(0.016)
	Input.action_release("reload")
	
	assert_false(player.reloading)
