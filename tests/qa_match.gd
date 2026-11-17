extends SceneTree
## Regression checks: UI boot, 3D squad, live action, match resolution,
## career progression, persistent upgrade, cup / training navigation.

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed==null:
		push_error("Main 3D scene is missing")
		quit(1)
		return
	var game: Variant = packed.instantiate()
	root.add_child(game)
	await process_frame
	if game.players.size()!=14 or game.arena.footballers.size()!=14:
		push_error("Expected 14 real 3D footballers")
		quit(2)
		return
	game.start_match("quick")
	if game.page!="match":
		push_error("Quick match cannot be started")
		quit(3)
		return
	game.goal_freeze=0.0
	for i in range(120):
		if i==10:
			game.action_switch()
		if i==20:
			game.ball_owner=game.selected
			game.action_pass()
		if i==45:
			game.ball_owner=game.selected
			game.action_shoot()
		if i==65:
			game.action_tackle()
		await process_frame
	if game.players.size()!=14 or game.ball_pos.length()>1000.0:
		push_error("3D match simulation state corrupted")
		quit(4)
		return
	game.end_match()
	if game.page!="results":
		push_error("Result screen did not appear")
		quit(5)
		return
	game.go_to("career")
	var old_round: int=game.round_number
	game.start_match("career")
	game.goal_freeze=0.0
	game.clock=game.length-0.02
	for i in range(7):
		await process_frame
	if game.page!="results":
		game.end_match()
	if game.round_number!=old_round+1:
		push_error("Career fixture did not record")
		quit(6)
		return
	game.go_to("shop")
	var old_level: int=game.upgrade_attack
	game.coins+=2000
	game.purchase_upgrade("attack")
	if game.upgrade_attack<=old_level:
		push_error("Squad upgrade failed")
		quit(7)
		return
	game.go_to("cup")
	game.start_match("cup")
	game.goal_freeze=0.0
	game.score=[2,0]
	game.end_match()
	if game.cup_round<=0:
		push_error("Cup victory was not recorded")
		quit(8)
		return
	game.go_to("home")
	game.start_match("training")
	if game.mode!="training" or game.length>100.0:
		push_error("Training mode did not start")
		quit(9)
		return
	game.end_match()
	print("FULL GAME QA PASSED: 3D stadium, 7v7, AI, pass/shot/tackle, career, upgrades, cup, training")
	quit(0)
