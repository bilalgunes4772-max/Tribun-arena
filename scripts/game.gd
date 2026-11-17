extends Node2D

const W := 1280.0
const H := 720.0
const PITCH := Rect2(115, 102, 1050, 515)
const CLUBS := ["KARTAL 1903", "BOGAZ UNITED", "ANADOLU FK", "YILDIZ SPOR", "SIMSEK CITY", "ASLANLAR"]
const SAVE := "user://tribun_arena.json"
var page := "home"
var career := false
var season := 1
var rounds := 0
var league_points := 0
var money := 500
var wins := 0
var difficulty := 1
var match_time := 0.0
var score := [0,0]
var players: Array[Dictionary] = []
var ball := Vector2(640,360)
var ball_v := Vector2.ZERO
var ball_owner := -1
var chosen := 0
var status := ""
var status_timer := 0.0
var joy := Vector2.ZERO
var joy_down := false
var sprint := false
var press_keys := {}
var ai_timer := 0.0
var result_recorded := false
var opposition := 1
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	load_game()
	queue_redraw()

func save_game() -> void:
	var f := FileAccess.open(SAVE,FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"season":season,"rounds":rounds,"points":league_points,"money":money,"wins":wins,"difficulty":difficulty}))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE): return
	var f := FileAccess.open(SAVE,FileAccess.READ)
	if not f: return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		season = int(data.get("season",1))
		rounds = int(data.get("rounds",0))
		league_points = int(data.get("points",0))
		money = int(data.get("money",500))
		wins = int(data.get("wins",0))
		difficulty = int(data.get("difficulty",1))

func begin_match(is_career: bool) -> void:
	career = is_career
	opposition = 1 + ((rounds if career else rng.randi_range(0,99)) % 5)
	page = "match"
	match_time = 0.0
	score = [0,0]
	result_recorded = false
	players.clear()
	for team in range(2):
		for i in range(5):
			var x = (350.0 if team == 0 else 930.0) + (float(i % 2) * (130.0 if team == 0 else -130.0))
			var y = 190.0 + floor(float(i) / 2.0) * 150.0
			if i == 0:
				x = 180.0 if team == 0 else 1100.0
				y = 360.0
			players.append({"pos":Vector2(x,y),"team":team,"keeper":i == 0,"speed":180.0,"stamina":100.0})
	chosen = 1
	ball = Vector2(640,360)
	ball_v = Vector2.ZERO
	ball_owner = -1
	set_status("MAC BASLADI!")

func set_status(s: String) -> void:
	status = s
	status_timer = 2.0

func _process(delta: float) -> void:
	if page == "match":
		update_match(minf(delta,0.04))
	status_timer = maxf(0.0,status_timer-delta)
	queue_redraw()

func input_axis() -> Vector2:
	var v := joy
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	return v.limit_length(1.0)

func update_match(dt: float) -> void:
	match_time += dt
	if match_time >= 120.0:
		finish_game()
		return
	var dt_scale := 1.0 + difficulty * 0.15
	ai_timer -= dt
	var axis := input_axis()
	for i in range(players.size()):
		var p: Dictionary = players[i]
		var position: Vector2 = p.pos
		var target := Vector2.ZERO
		if i == chosen:
			target = axis
		elif p.keeper:
			var kx := 170.0 if p.team == 0 else 1110.0
			target = (Vector2(kx,clampf(ball.y,220,500))-position).normalized()
		else:
			var interested: bool = (ball_owner == -1 or (ball_owner >= 0 and int(players[ball_owner].team) != int(p.team)))
			var closest := nearest_player(int(p.team),ball)
			if interested and closest == i:
				target = (ball-position).normalized()
			else:
				var start_x := 350.0 if p.team == 0 else 930.0
				var dest := Vector2(start_x + float(i%3)*52.0*(1 if p.team == 0 else -1), 160.0 + float(i)*85.0)
				if ball_owner >= 0 and players[ball_owner].team == p.team:
					dest.x += 175.0 if p.team == 0 else -175.0
				target = (dest-position).normalized() if position.distance_to(dest)>18.0 else Vector2.ZERO
		var speed := 185.0 if p.team == 0 else 180.0*dt_scale
		if i == chosen and sprint and float(p.stamina)>2:
			speed *= 1.4
			p.stamina = maxf(0.0,float(p.stamina)-16.0*dt)
		else:
			p.stamina = minf(100.0,float(p.stamina)+4.0*dt)
		if p.keeper: speed *= 0.72
		position += target*speed*dt
		position.x = clampf(position.x,PITCH.position.x+19,PITCH.end.x-19)
		position.y = clampf(position.y,PITCH.position.y+19,PITCH.end.y-19)
		p.pos = position
		players[i] = p
		if ball_owner == -1 and position.distance_to(ball)<21.0 and ball_v.length()<240:
			ball_owner = i
	if ball_owner >= 0:
		ball = players[ball_owner].pos + Vector2(12 if players[ball_owner].team == 0 else -12,9)
		ball_v = Vector2.ZERO
		if players[ball_owner].team == 1:
			if ai_timer <= 0:
				ai_timer = 0.65 + rng.randf_range(0,0.6)
				if ball.x < 460 or rng.randf()<0.17:
					strike(ball_owner,Vector2(-1,rng.randf_range(-0.30,0.30)),rng.randf_range(550,720))
				else:
					var mate := choose_teammate(ball_owner)
					if mate >= 0:
						strike(ball_owner,(players[mate].pos-ball).normalized(),390)
	else:
		ball += ball_v*dt
		ball_v = ball_v.move_toward(Vector2.ZERO,145.0*dt)
		if ball.y < PITCH.position.y+10 or ball.y > PITCH.end.y-10:
			ball.y = clampf(ball.y,PITCH.position.y+10,PITCH.end.y-10)
			ball_v.y *= -0.7
		if ball.x < PITCH.position.x or ball.x > PITCH.end.x:
			var goal_team := 0 if ball.x > PITCH.end.x else 1
			if ball.y > 286 and ball.y < 434:
				score[goal_team] += 1
				set_status("GOOOOL! "+CLUBS[0 if goal_team == 0 else opposition])
				reset_ball()
			else:
				ball.x = clampf(ball.x,PITCH.position.x,PITCH.end.x)
				ball_v.x *= -0.65
	if ball_owner >= 0 and players[ball_owner].team == 0 and chosen != ball_owner:
		chosen = ball_owner

func nearest_player(team: int, pos: Vector2) -> int:
	var best := -1
	var dist := INF
	for i in range(players.size()):
		if int(players[i].team) != team: continue
		var d: float = players[i].pos.distance_to(pos)
		if d < dist:
			dist = d
			best = i
	return best

func choose_teammate(owner: int) -> int:
	var best := -1
	var best_dist := INF
	for i in range(players.size()):
		if i == owner or players[i].team != players[owner].team: continue
		var d: float = players[i].pos.distance_to(players[owner].pos)
		if d < best_dist:
			best_dist = d
			best = i
	return best

func strike(i: int, direction: Vector2, speed: float) -> void:
	if i < 0: return
	if direction.length_squared()<0.01: return
	ball = players[i].pos + direction*24
	ball_v = direction.normalized()*speed
	ball_owner = -1

func shoot_ball() -> void:
	if ball_owner < 0 or players[ball_owner].team != 0: return
	var dir := (Vector2(PITCH.end.x+24,360.0+rng.randf_range(-55,55))-ball).normalized()
	strike(ball_owner,dir,730)
	set_status("SUT!")

func pass_ball() -> void:
	if ball_owner < 0 or players[ball_owner].team != 0: return
	var mate := choose_teammate(ball_owner)
	if mate >= 0:
		strike(ball_owner,(players[mate].pos-ball).normalized(),385)

func tackle() -> void:
	if ball_owner < 0: return
	if players[ball_owner].team != 1: return
	if players[chosen].pos.distance_to(players[ball_owner].pos)<48:
		ball_owner = chosen
		set_status("TOP KAPILDI!")

func switch_player() -> void:
	var next := nearest_player(0,ball)
	if next >= 0: chosen = next

func reset_ball() -> void:
	ball = Vector2(640,360)
	ball_v = Vector2.ZERO
	ball_owner = -1
	for i in range(players.size()):
		var p: Dictionary = players[i]
		p.pos = Vector2(320.0+float(i%5)*45,165.0+float(i%5)*90) if i<5 else Vector2(940.0-float(i%5)*45,165.0+float(i%5)*90)
		players[i] = p

func finish_game() -> void:
	page = "result"
	if career and not result_recorded:
		result_recorded = true
		rounds += 1
		var reward := 50
		if score[0]>score[1]:
			league_points += 3
			wins += 1
			reward = 160
		elif score[0]==score[1]:
			league_points += 1
			reward = 85
		money += reward
		if rounds % 10 == 0:
			season += 1
			rounds = 0
			league_points = 0
		save_game()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if page == "match":
		match key.keycode:
			KEY_J: pass_ball()
			KEY_K: shoot_ball()
			KEY_L: tackle()
			KEY_SPACE: switch_player()
			KEY_ESCAPE: finish_game()
	elif key.keycode == KEY_ENTER:
		begin_match(false)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			tap(event.position)
		else:
			joy_down = false
			joy = Vector2.ZERO
			sprint = false
	elif event is InputEventScreenDrag:
		if joy_down:
			joy = (event.position-Vector2(190,564)).limit_length(72)/72.0
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			tap(event.position)
		else:
			joy_down = false
			joy = Vector2.ZERO
			sprint = false

func tap(p: Vector2) -> void:
	if page == "home":
		if Rect2(390,280,500,78).has_point(p): begin_match(false)
		elif Rect2(390,380,500,78).has_point(p): page = "career"
		elif Rect2(390,480,500,78).has_point(p): difficulty = (difficulty % 3)+1; save_game()
	elif page == "career":
		if Rect2(390,430,500,78).has_point(p): begin_match(true)
		elif p.x<230 and p.y<160: page = "home"
	elif page == "result":
		page = "career" if career else "home"
	elif page == "match":
		if p.x<345 and p.y>445:
			joy_down = true
			joy = (p-Vector2(190,564)).limit_length(72)/72.0
		elif p.distance_to(Vector2(1100,510))<77: shoot_ball()
		elif p.distance_to(Vector2(980,590))<75: pass_ball()
		elif p.distance_to(Vector2(1130,640))<60: tackle()
		elif p.distance_to(Vector2(870,650))<55: switch_player()
		elif p.distance_to(Vector2(1210,320))<58: sprint = true
		elif p.x<90 and p.y<85: finish_game()

func label_text(s: String, pos: Vector2, size: int=30, color: Color=Color.WHITE, centered: bool=false) -> void:
	var font := ThemeDB.fallback_font
	var x := pos.x
	if centered: x -= font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2.0
	draw_string(font,Vector2(x,pos.y),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func box_shape(r: Rect2, c: Color) -> void:
	draw_rect(r,c)

func panel_button(r: Rect2, txt: String) -> void:
	box_shape(r,Color("#243e51"))
	draw_rect(r,Color("#68d8cc"),false,3.0)
	label_text(txt,r.position+Vector2(r.size.x/2.0,49),31,Color.WHITE,true)

func _draw() -> void:
	box_shape(Rect2(0,0,W,H),Color("#091925"))
	if page == "home":
		label_text("TRIBUN ARENA",Vector2(640,140),76,Color("#f8d479"),true)
		label_text("KENDI EFSANENI YAZ",Vector2(640,200),25,Color("#9ab3c2"),true)
		panel_button(Rect2(390,280,500,78),"HIZLI MAC")
		panel_button(Rect2(390,380,500,78),"KARIYER MODU")
		panel_button(Rect2(390,480,500,78),"ZORLUK: "+str(difficulty)+" / 3")
		label_text("Android alfa - 2D futbol",Vector2(640,662),23,Color("#a7bbc6"),true)
	elif page == "career":
		label_text("< GERI",Vector2(42,78),25)
		label_text("KULUP KARIYERI",Vector2(640,155),65,Color("#f8d479"),true)
		label_text("SEZON "+str(season)+"  |  MAC "+str(rounds)+"/10",Vector2(640,245),33,Color.WHITE,true)
		label_text("PUAN: "+str(league_points)+"   GALIBIYET: "+str(wins),Vector2(640,312),32,Color.WHITE,true)
		label_text("KULUP BUTCESI: "+str(money)+" ALTIN",Vector2(640,375),28,Color("#76dcb3"),true)
		panel_button(Rect2(390,430,500,78),"SONRAKI LIG MACI")
		label_text("Rakip: "+CLUBS[1+(rounds%5)],Vector2(640,565),28,Color("#bdd1dd"),true)
	elif page == "result":
		label_text("MAC SONA ERDI",Vector2(640,205),60,Color("#f8d479"),true)
		label_text(CLUBS[0]+"  "+str(score[0])+" - "+str(score[1])+"  "+CLUBS[opposition],Vector2(640,348),37,Color.WHITE,true)
		label_text("DEVAM ETMEK ICIN DOKUN",Vector2(640,490),27,Color("#a5d6de"),true)
	elif page == "match":
		draw_match()

func draw_match() -> void:
	draw_rect(PITCH,Color("#216848"))
	for j in range(10):
		if j%2==0:
			box_shape(Rect2(115+j*105,102,105,515),Color(0.3,0.7,0.4,0.13))
	draw_rect(PITCH,Color("#e9f2e4"),false,3)
	draw_line(Vector2(640,102),Vector2(640,617),Color.WHITE,3)
	draw_arc(Vector2(640,360),77,0,TAU,64,Color.WHITE,3)
	draw_rect(Rect2(115,260,155,200),Color.WHITE,false,3)
	draw_rect(Rect2(1010,260,155,200),Color.WHITE,false,3)
	draw_rect(Rect2(98,286,17,148),Color("#ecede6"),false,5)
	draw_rect(Rect2(1165,286,17,148),Color("#ecede6"),false,5)
	for i in range(players.size()):
		var p: Dictionary = players[i]
		var color := Color("#ffffff") if int(p.team)==0 else Color("#fa5774")
		draw_circle(p.pos,18,color)
		draw_circle(p.pos,11,Color("#1e2c3b"))
		label_text(str((i%5)+1),p.pos+Vector2(0,7),18,Color.WHITE,true)
		if i==chosen: draw_arc(p.pos,25,0,TAU,32,Color("#fff17b"),4)
	draw_circle(ball+Vector2(3,4),11,Color("#162e26"))
	draw_circle(ball,9,Color.WHITE)
	box_shape(Rect2(260,14,760,71),Color("#122a3a"))
	label_text(CLUBS[0]+"  "+str(score[0])+"  -  "+str(score[1])+"  "+CLUBS[opposition],Vector2(640,57),31,Color.WHITE,true)
	label_text(str(int(match_time/2.0))+"' / 60'",Vector2(1120,55),25)
	if status_timer>0:
		label_text(status,Vector2(640,143),33,Color("#ffeb89"),true)
	draw_circle(Vector2(190,564),75,Color(0.05,0.12,0.18,0.75))
	draw_arc(Vector2(190,564),75,0,TAU,48,Color("#a4bac4"),3)
	draw_circle(Vector2(190,564)+joy*62,31,Color("#c5e2d9"))
	draw_control(Vector2(980,590),55,"PAS")
	draw_control(Vector2(1100,510),67,"SUT")
	draw_control(Vector2(1130,640),48,"TOP")
	draw_control(Vector2(870,650),45,"DEGIS")
	draw_control(Vector2(1210,320),44,"KOS")
	label_text("X",Vector2(30,58),31,Color.WHITE)

func draw_control(pos: Vector2,r: float,txt: String) -> void:
	draw_circle(pos,r,Color("#173d51"))
	draw_arc(pos,r,0,TAU,48,Color("#77d9cf"),3)
	label_text(txt,pos+Vector2(0,8),20,Color.WHITE,true)
