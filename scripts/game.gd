extends Node3D
## Tribun Arena 0.2 - real-time offline 3D football and career game.

const ARENA = preload("res://scripts/arena_world.gd")
const HUD = preload("res://scripts/hud.gd")
const SAVE_FILE := "user://tribun_arena_v02.json"
const CLUB_NAMES := ["KARTAL 1903","MARMARA FK","ANADOLU GÜCÜ","YILDIZ SPOR","BOĞAZ CITY","KUZEY UNITED","KAPLANLAR","ASİL GENÇLİK"]
const FIELD_X := 49.2
const FIELD_Z := 29.2
const DURATION := 164.0

var arena = null
var hud = null
var page := "home"
var mode := "quick"
var players: Array[Dictionary] = []
var ball_pos := Vector3(0,0.5,0)
var ball_vel := Vector3.ZERO
var ball_owner := -1
var selected := 5
var score := [0,0]
var clock := 0.0
var length := DURATION
var goal_freeze := 0.0
var pickup_lock := 0.0
var action_lock := 0.0
var ai_choice := 0.0
var ai_steal := 0.0
var joystick := Vector2.ZERO
var sprint := false
var opponent := 1
var shots := [0,0]
var passes := [0,0]
var steals := [0,0]
var message := ""
var message_timer := 0.0
var result_saved := false
var difficulty := 2
var formation := 0
var tactic := 0
var coins := 700
var season := 1
var round_number := 0
var upgrade_attack := 60
var upgrade_defense := 58
var upgrade_fitness := 64
var cup_round := 0
var cup_wins := 0
var trophy_count := 0
var career_wins := 0
var career_draws := 0
var daily_goal := 0
var league_table: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	load_progress()
	if league_table.size()!=CLUB_NAMES.size():
		reset_league()
	arena = ARENA.new()
	add_child(arena)
	var canvas := CanvasLayer.new()
	canvas.layer = 2
	add_child(canvas)
	hud = HUD.new()
	hud.game = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(hud)
	setup_players()
	set_message("TRİBÜN ARENA'YA HOŞ GELDİN",3.0)

func initial_table() -> Array[Dictionary]:
	var table: Array[Dictionary] = []
	for i in range(CLUB_NAMES.size()):
		table.append({"name":CLUB_NAMES[i],"p":0,"w":0,"d":0,"l":0,"gf":0,"ga":0})
	return table

func reset_league() -> void:
	league_table = initial_table()
	round_number = 0

func save_progress() -> void:
	var file := FileAccess.open(SAVE_FILE,FileAccess.WRITE)
	if file==null: return
	var state := {
		"coins":coins,"season":season,"round":round_number,
		"attack":upgrade_attack,"defense":upgrade_defense,"fitness":upgrade_fitness,
		"difficulty":difficulty,"formation":formation,"tactic":tactic,
		"cup_round":cup_round,"cup_wins":cup_wins,"trophies":trophy_count,
		"career_wins":career_wins,"career_draws":career_draws,
		"daily_goal":daily_goal,"table":league_table
	}
	file.store_string(JSON.stringify(state))

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_FILE): return
	var file := FileAccess.open(SAVE_FILE,FileAccess.READ)
	if file==null: return
	var state = JSON.parse_string(file.get_as_text())
	if not (state is Dictionary): return
	coins = int(state.get("coins",coins))
	season = int(state.get("season",season))
	round_number = int(state.get("round",round_number))
	upgrade_attack = int(state.get("attack",upgrade_attack))
	upgrade_defense = int(state.get("defense",upgrade_defense))
	upgrade_fitness = int(state.get("fitness",upgrade_fitness))
	difficulty = clampi(int(state.get("difficulty",difficulty)),1,3)
	formation = posmod(int(state.get("formation",formation)),3)
	tactic = posmod(int(state.get("tactic",tactic)),3)
	cup_round = int(state.get("cup_round",cup_round))
	cup_wins = int(state.get("cup_wins",cup_wins))
	trophy_count = int(state.get("trophies",trophy_count))
	career_wins = int(state.get("career_wins",career_wins))
	career_draws = int(state.get("career_draws",career_draws))
	daily_goal = int(state.get("daily_goal",daily_goal))
	var previous: Variant = state.get("table",[])
	if previous is Array and previous.size() == CLUB_NAMES.size():
		league_table.clear()
		for entry in previous:
			if entry is Dictionary:
				league_table.append(entry)

func set_message(text: String, seconds: float = 2.0) -> void:
	message = text
	message_timer = seconds

func formation_position(team: int, index: int) -> Vector2:
	var x := 0.0
	var z := 0.0
	if index == 0:
		x = -44.0
	else:
		if formation==0:
			match index:
				1,2:
					x=-27.0
					z=-12.0 if index==1 else 12.0
				3,4:
					x=-11.0
					z=-13.0 if index==3 else 13.0
				5,6:
					x=7.0
					z=-8.0 if index==5 else 8.0
		elif formation==1:
			match index:
				1,2,3:
					x=-28.0
					z=float(index-2)*15.0
				4,5:
					x=-8.0
					z=-12.0 if index==4 else 12.0
				6:
					x=10.0
					z=0.0
		else:
			match index:
				1,2:
					x=-27.0
					z=-15.0 if index==1 else 15.0
				3,4,5:
					x=-8.0
					z=float(index-4)*16.0
				6:
					x=10.0
					z=0.0
	if team==1:
		x=-x
		z=-z
	return Vector2(x,z)

func setup_players() -> void:
	players.clear()
	if arena==null: return
	for node in arena.footballers:
		node.queue_free()
	arena.footballers.clear()
	for t in range(2):
		for n in range(7):
			var pos := formation_position(t,n)
			if t==1 and n>0:
				pos.x += rng.randf_range(-1.5,1.5)
			players.append({"pos":pos,"team":t,"num":n,"stamina":100.0,"dir":Vector2(1 if t==0 else -1,0),"speed":0.0})
			arena.create_footballer(t,n)
	ball_pos = Vector3(0,0.5,0)
	ball_vel = Vector3.ZERO
	ball_owner = -1
	selected = 5
	arena.update_visuals(players,ball_pos,selected,0.016,clock)

func go_to(section: String) -> void:
	page = section
	if page=="home":
		joystick = Vector2.ZERO
		sprint = false
	save_progress()

func start_match(match_mode: String) -> void:
	mode = match_mode
	page = "match"
	clock = 0.0
	length = 92.0 if mode=="training" else DURATION
	shots = [0,0]
	passes = [0,0]
	steals = [0,0]
	score = [0,0]
	goal_freeze = 1.5
	action_lock = 0.0
	ai_choice = 0.7
	ai_steal = 0.0
	pickup_lock = 0.0
	result_saved = false
	opponent = (round_number % 7)+1 if mode=="career" else rng.randi_range(1,7)
	if mode=="cup":
		opponent = clampi(7-cup_round,1,7)
	setup_players()
	set_message("HAKEM DÜDÜĞÜ ÇALDI!",2.0)

func _process(delta: float) -> void:
	var dt := minf(delta,0.045)
	message_timer = maxf(0.0,message_timer-dt)
	if page=="match":
		tick_match(dt)
	if arena!=null:
		arena.update_visuals(players,ball_pos,selected,dt,clock)
		arena.aim_camera(ball_pos,dt,page=="match")
	if hud!=null: hud.queue_redraw()

func movement_axis() -> Vector2:
	var axis := joystick
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): axis.x-=1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): axis.x+=1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): axis.y-=1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): axis.y+=1
	return axis.limit_length(1.0)

func closest(team: int, point: Vector2, exclude_keeper: bool = false) -> int:
	var best := -1
	var best_dist := INF
	for i in range(players.size()):
		if int(players[i]["team"])!=team: continue
		if exclude_keeper and int(players[i]["num"])==0: continue
		var position: Vector2 = players[i]["pos"]
		var d := position.distance_squared_to(point)
		if d<best_dist:
			best_dist=d
			best=i
	return best

func support_target(p: Dictionary, index: int, owner_team: int) -> Vector2:
	var team := int(p["team"])
	var base := formation_position(team,int(p["num"]))
	if owner_team==team:
		base.x += 12.0 if team==0 else -12.0
		base.y = clampf(base.y+(ball_pos.z-base.y)*0.24,-25.0,25.0)
	else:
		base.x += clampf(ball_pos.x*0.26,-14.0,14.0)
		base.y += clampf(ball_pos.z*0.3,-7.0,7.0)
	if tactic==1 and team==0 and owner_team==1:
		base.x += 12.0
	if tactic==2 and team==0 and owner_team==1:
		base.x -= 9.0
	return base

func tick_match(dt: float) -> void:
	if goal_freeze>0:
		goal_freeze = maxf(0.0,goal_freeze-dt)
		return
	clock += dt
	pickup_lock = maxf(0.0,pickup_lock-dt)
	action_lock = maxf(0.0,action_lock-dt)
	ai_choice = maxf(0.0,ai_choice-dt)
	ai_steal = maxf(0.0,ai_steal-dt)
	if clock >= length:
		end_match()
		return
	var ball_ground := Vector2(ball_pos.x,ball_pos.z)
	var owner_team := -1 if ball_owner<0 else int(players[ball_owner]["team"])
	var chase_position := ball_ground
	if ball_owner>=0:
		chase_position = players[ball_owner]["pos"]
	var closest_home := closest(0,chase_position,true)
	var closest_away := closest(1,chase_position,true)
	for i in range(players.size()):
		var p: Dictionary = players[i]
		var pteam := int(p["team"])
		var pnum := int(p["num"])
		var current: Vector2 = p["pos"]
		var dir := Vector2.ZERO
		if i==selected and pteam==0:
			dir = movement_axis()
		elif pnum==0:
			var keeper_x := -46.0 if pteam==0 else 46.0
			var wanted := Vector2(keeper_x,clampf(ball_pos.z,-5.5,5.5))
			dir = (wanted-current).normalized() if current.distance_to(wanted)>0.35 else Vector2.ZERO
		elif i==ball_owner:
			var target_goal := Vector2(49.0 if pteam==0 else -49.0,0)
			dir = (target_goal-current).normalized()
			dir.y += sin(clock*1.7+float(i))*0.12
			dir = dir.normalized()
		elif (pteam==0 and i==closest_home and owner_team!=0) or (pteam==1 and i==closest_away and owner_team!=1):
			dir = (chase_position-current).normalized()
		else:
			var desired := support_target(p,i,owner_team)
			dir = (desired-current).normalized() if current.distance_to(desired)>1.0 else Vector2.ZERO
		var pace := 8.4
		if pteam==0: pace *= 0.86+float(upgrade_fitness)/440.0
		else: pace *= 0.95+float(difficulty)*0.06
		if pnum==0: pace*=0.85
		var stamina: float = float(p["stamina"])
		if i==selected and sprint and stamina>2:
			pace*=1.44
			stamina=maxf(0.0,stamina-dt*15.5)
		else:
			stamina=minf(100.0,stamina+dt*(4.6 if pteam==0 else 5.2))
		if stamina<16: pace*=0.72
		if i==ball_owner: pace*=0.89
		var moved := dir*pace*dt
		current += moved
		current.x=clampf(current.x,-47.7,47.7)
		current.y=clampf(current.y,-27.8,27.8)
		p["pos"]=current
		p["stamina"]=stamina
		p["dir"]=dir if dir.length_squared()>0.01 else p["dir"]
		p["speed"]=pace if dir.length_squared()>0.01 else 0.0
		players[i]=p
		if i==ball_owner or pickup_lock>0: continue
		var distance := current.distance_to(ball_ground)
		if ball_owner==-1 and ball_pos.y<1.8 and distance<1.22 and ball_vel.length()<39:
			ball_owner=i
			ball_vel=Vector3.ZERO
			pickup_lock=0.13
		elif ball_owner!=-1 and owner_team!=pteam and distance<1.45 and ai_steal<=0 and i!=selected:
			var chance := (0.10 + (float(upgrade_defense)/600.0 if pteam==0 else 0.09)) * dt*8.0
			if rng.randf()<chance:
				ball_owner=i
				ai_steal=1.25
				pickup_lock=0.2
				if pteam==0: steals[0]+=1
	if ball_owner>=0:
		var carrying: Dictionary = players[ball_owner]
		var place: Vector2 = carrying["pos"]
		var facing: Vector2 = carrying["dir"]
		if facing.length_squared()<0.01: facing=Vector2(1 if int(carrying["team"])==0 else -1,0)
		ball_pos=Vector3(place.x+facing.x*0.87,0.48,place.y+facing.y*0.87)
		ball_vel=Vector3.ZERO
		if int(carrying["team"])==0 and ball_owner!=selected:
			selected=ball_owner
		if int(carrying["team"])==1 and ai_choice<=0:
			ai_ball_choice()
	else:
		ball_vel.y -= 15.8*dt
		ball_pos += ball_vel*dt
		if ball_pos.y<0.45:
			ball_pos.y=0.45
			if ball_vel.y < -2.0: ball_vel.y = -ball_vel.y*0.35
			else: ball_vel.y=0.0
			ball_vel.x*=maxf(0,1.0-0.32*dt)
			ball_vel.z*=maxf(0,1.0-0.32*dt)
		if absf(ball_pos.z)>FIELD_Z:
			ball_pos.z=clampf(ball_pos.z,-FIELD_Z,FIELD_Z)
			ball_vel.z*=-0.62
		if absf(ball_pos.x)>FIELD_X:
			var scoring_team := 0 if ball_pos.x>0 else 1
			if absf(ball_pos.z)<5.0 and ball_pos.y<2.75:
				register_goal(scoring_team)
			else:
				ball_pos.x=clampf(ball_pos.x,-FIELD_X,FIELD_X)
				ball_vel.x*=-0.56
				pickup_lock=0.2

func ai_ball_choice() -> void:
	if ball_owner<0: return
	var p: Dictionary = players[ball_owner]
	if int(p["team"])!=1:return
	var current: Vector2 = p["pos"]
	ai_choice=rng.randf_range(0.65,1.3)
	if int(p["num"])==0:
		var receiver := teammate(ball_owner)
		if receiver>=0: pass_to(ball_owner,receiver)
		return
	if current.x < -22.0 and rng.randf()<0.75:
		kick(ball_owner,Vector2(-49.7,rng.randf_range(-4.0,4.0)),31.0+float(difficulty)*2,3.1)
		shots[1]+=1
	elif rng.randf()<0.43:
		var receiver := teammate(ball_owner)
		if receiver>=0: pass_to(ball_owner,receiver)

func teammate(i: int) -> int:
	if i<0 or i>=players.size():return -1
	var our_team := int(players[i]["team"])
	var origin: Vector2 = players[i]["pos"]
	var candidate := -1
	var best := -INF
	for j in range(players.size()):
		if i==j or int(players[j]["team"])!=our_team or int(players[j]["num"])==0:continue
		var other: Vector2 = players[j]["pos"]
		var forward := (other.x-origin.x)*(1 if our_team==0 else -1)
		var score_value := forward*1.8-origin.distance_to(other)*0.30+rng.randf_range(-2.0,2.0)
		if score_value>best:
			candidate=j
			best=score_value
	return candidate

func kick(i: int, target: Vector2, strength: float, lift: float) -> void:
	if i<0 or ball_owner!=i:return
	var from: Vector2 = players[i]["pos"]
	var aim := (target-from).normalized()
	if aim.length_squared()<0.01:return
	ball_pos=Vector3(from.x+aim.x*1.15,0.73,from.y+aim.y*1.15)
	ball_vel=Vector3(aim.x*strength,lift,aim.y*strength)
	ball_owner=-1
	pickup_lock=0.27
	action_lock=0.25

func pass_to(sender: int, receiver: int) -> void:
	if sender<0 or receiver<0:return
	var target: Vector2=players[receiver]["pos"]
	if int(players[sender]["team"])==0:
		target += Vector2(rng.randf_range(-0.8,0.8),rng.randf_range(-1.2,1.2))
	kick(sender,target,24.0,1.5)
	passes[int(players[sender]["team"])]+=1

func action_pass() -> void:
	if page!="match" or action_lock>0:return
	var i:=ball_owner
	if i<0 or int(players[i]["team"])!=0:return
	var receiver := teammate(i)
	if receiver>=0:
		pass_to(i,receiver)
		set_message("AKIL DOLU PAS!",0.8)

func action_shoot() -> void:
	if page!="match" or action_lock>0:return
	var i:=ball_owner
	if i<0 or int(players[i]["team"])!=0:return
	var aim_z:=rng.randf_range(-5.0,5.0)*(1.18-float(upgrade_attack)/225.0)
	var target := Vector2(51.0,aim_z)
	kick(i,target,31.0+float(upgrade_attack)*0.09,2.8+rng.randf_range(-1.0,0.7))
	shots[0]+=1
	set_message("ŞUT!",0.85)

func action_tackle() -> void:
	if page!="match" or action_lock>0:return
	if ball_owner>=0 and int(players[ball_owner]["team"])==1:
		var our_pos: Vector2 = players[selected]["pos"]
		var their_pos: Vector2 = players[ball_owner]["pos"]
		if our_pos.distance_to(their_pos)<3.1:
			ball_owner=selected
			pickup_lock=0.22
			action_lock=0.5
			steals[0]+=1
			set_message("HARİKA MÜDAHALE!",1.0)
		else: set_message("TOPA YAKLAŞ!",0.8)
	elif ball_owner<0:
		var p: Vector2 = players[selected]["pos"]
		if p.distance_to(Vector2(ball_pos.x,ball_pos.z))<3.0:
			ball_owner=selected
			pickup_lock=0.2

func action_switch() -> void:
	if page!="match":return
	if ball_owner>=0 and int(players[ball_owner]["team"])==0:
		selected=ball_owner
		return
	var nearest := closest(0,Vector2(ball_pos.x,ball_pos.z),true)
	if nearest>=0 and selected!=nearest:
		selected=nearest
	else:
		var next := selected+1
		selected=1+(next%6)

func register_goal(team: int) -> void:
	score[team]+=1
	set_message("GOOOOL!  "+(CLUB_NAMES[0] if team==0 else CLUB_NAMES[opponent]),3.1)
	goal_freeze=2.0
	reset_kickoff()

func reset_kickoff() -> void:
	for i in range(players.size()):
		var p: Dictionary=players[i]
		p["pos"]=formation_position(int(p["team"]),int(p["num"]))
		p["stamina"]=minf(100.0,float(p["stamina"])+6.0)
		players[i]=p
	selected=5
	ball_pos=Vector3.ZERO+Vector3(0,0.5,0)
	ball_vel=Vector3.ZERO
	ball_owner=-1
	pickup_lock=1.0

func update_table(team: int, goals_for: int, goals_against: int) -> void:
	var data: Dictionary=league_table[team]
	data["p"]=int(data["p"])+1
	data["gf"]=int(data["gf"])+goals_for
	data["ga"]=int(data["ga"])+goals_against
	if goals_for>goals_against: data["w"]=int(data["w"])+1
	elif goals_for==goals_against: data["d"]=int(data["d"])+1
	else: data["l"]=int(data["l"])+1
	league_table[team]=data

func points_of(p: Dictionary) -> int:
	return int(p["w"])*3+int(p["d"])

func ordered_table() -> Array[Dictionary]:
	var ordered: Array[Dictionary] = league_table.duplicate(true)
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		var ap:=points_of(a)
		var bp:=points_of(b)
		if ap!=bp: return ap>bp
		return (int(a["gf"])-int(a["ga"]))>(int(b["gf"])-int(b["ga"]))
	)
	return ordered

func simulate_league_round() -> void:
	for i in range(1,8):
		if i==opponent:continue
		var simulated_home:=rng.randi_range(0,3)
		var simulated_away:=rng.randi_range(0,3)
		update_table(i,simulated_home,simulated_away)

func end_match() -> void:
	if page!="match": return
	page="results"
	joystick=Vector2.ZERO
	sprint=false
	if result_saved:return
	result_saved=true
	if mode=="career":
		update_table(0,int(score[0]),int(score[1]))
		update_table(opponent,int(score[1]),int(score[0]))
		simulate_league_round()
		round_number+=1
		if score[0]>score[1]:
			coins+=260
			career_wins+=1
		elif score[0]==score[1]:
			coins+=140
			career_draws+=1
		else: coins+=75
		coins+=int(shots[0])*12+int(passes[0])*3
		if round_number>=14:
			var board := ordered_table()
			if str(board[0]["name"])==CLUB_NAMES[0]:
				trophy_count+=1
				coins+=1600
				set_message("ŞAMPİYONLUK KUPASI!",4.0)
			season+=1
			reset_league()
	elif mode=="cup":
		if score[0]>score[1]:
			cup_round+=1
			cup_wins+=1
			coins+=350
			if cup_round>=4:
				trophy_count+=1
				coins+=1200
				cup_round=0
				set_message("KUPA ŞAMPİYONU!",4.0)
		else:cup_round=0
	elif mode=="training":
		coins+=int(score[0])*90+int(shots[0])*7
	else:
		coins+=maxi(35,int(score[0])*35)
	save_progress()

func purchase_upgrade(which: String) -> void:
	var level:=upgrade_attack if which=="attack" else (upgrade_defense if which=="defense" else upgrade_fitness)
	var cost:=200+(level-50)*14
	if level>=95:
		set_message("MAKSİMUM SEVİYE!",1.4)
	elif coins<cost:
		set_message("YETERSİZ ALTIN!",1.4)
	else:
		coins-=cost
		match which:
			"attack": upgrade_attack+=3
			"defense": upgrade_defense+=3
			"fitness": upgrade_fitness+=3
		set_message("KADRO GÜÇLENDİ!",1.5)
		save_progress()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):return
	var key: InputEventKey=event as InputEventKey
	if not key.pressed or key.echo:return
	if page=="match":
		match key.keycode:
			KEY_J: action_pass()
			KEY_K: action_shoot()
			KEY_L: action_tackle()
			KEY_SPACE: action_switch()
			KEY_ESCAPE: end_match()
	elif key.keycode==KEY_ESCAPE:
		go_to("home")
	elif key.keycode==KEY_ENTER:
		start_match("quick")
