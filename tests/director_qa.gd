extends SceneTree
## Headless manager regression, executed before every Android APK is published.
const CORE = preload("res://scripts/director_core.gd")

func fail_with(s: String, code: int) -> void:
	push_error("DIRECTOR QA FAILED: "+s)
	quit(code)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = CORE.new()
	game.create_world()
	if game.clubs.size()!=12 or game.footballers.size()<250 or game.fixtures.size()!=22:
		fail_with("world generation clubs/players/fixture counts",1)
		return
	if game.starter_count()!=11:
		fail_with("starting eleven generation",2)
		return
	var effectiveness: float=game.training_effectiveness()
	if effectiveness<20.0 or effectiveness>99.0:
		fail_with("tactical effectiveness range",3)
		return
	var p: Dictionary=game.market_players()[0]
	if game.scout(int(p["id"])).is_empty():
		fail_with("scouting request",4)
		return
	if game.pending_scout.size()<1:
		fail_with("scouting queue",5)
		return
	if game.kickoff().is_empty() or game.current_match.is_empty() or int(game.current_match["half"])!=1:
		fail_with("start and halftime simulation",6)
		return
	if game.finish_match().is_empty() or int(game.current_match["half"])!=2 or game.round_no!=1:
		fail_with("full time and league progression",7)
		return
	if game.league_table().size()!=12 or game.week_results.size()!=6:
		fail_with("league table and six fixtures each round",8)
		return
	if not bool(p["known"]):
		fail_with("scout report not returned after one week",9)
		return
	game.close_match()
	var record_count: int=game.history.size()
	if record_count!=1:
		fail_with("match history did not persist",10)
		return
	var bid_result: String=game.transfer_bid(int(p["id"]),1.5)
	if bid_result=="":
		fail_with("bid returned empty result",11)
		return
	var youth_result: String=game.academy_promote()
	if youth_result.is_empty():
		fail_with("youth player development",12)
		return
	var staff_result: String=game.staff_upgrade("coach")
	if staff_result.is_empty():
		fail_with("staff system",13)
		return
	game.focus=0
	game.intensity=1
	game.weekly_training()
	for idx in range(21):
		if game.kickoff().is_empty():
			fail_with("season fixture "+str(idx),14)
			return
		if game.finish_match().is_empty():
			fail_with("season simulation failed "+str(idx),15)
			return
		game.close_match()
	if game.round_no!=22:
		fail_with("22-week double round-robin not completed",16)
		return
	var next: String=game.next_season()
	if next=="" or game.season!=2027 or game.fixtures.size()!=22:
		fail_with("next season rollover",17)
		return
	game.save_game()
	var reloaded = CORE.new()
	if reloaded.season!=2027 or reloaded.footballers.size()<250:
		fail_with("save / reload world data",18)
		return
	var packed: PackedScene=load("res://scenes/main.tscn")
	if packed==null:
		fail_with("main manager scene missing",19)
		return
	var ui: Node=packed.instantiate()
	root.add_child(ui)
	await process_frame
	if ui.sim==null:
		fail_with("manager UI failed to boot",20)
		return
	for page in ["MERKEZ","KADRO","TAKTİK","TRANSFER","SCOUT","ANTRENMAN","FİNANS","ALTYAPI","PERSONEL","LİG","HABERLER"]:
		ui.nav_page(page)
		await process_frame
	print("DIRECTOR QA PASSED: world, 12 clubs, 22 rounds, half-time match engine, academy, staff, scouting, transfers, persistence and 11 UI screens")
	quit(0)
