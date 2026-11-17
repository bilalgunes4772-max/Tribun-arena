extends Control
## Screen-space premium game UI. All interactions work with multi-touch.
var game = null
var joy_finger := -100
var run_finger := -100
const W := 1280.0
const H := 720.0
const NAVY := Color("#091827")
const MID := Color("#14273b")
const PAPER := Color("#eef4f5")
const MUTED := Color("#a0b7c5")
const GOLD := Color("#efc676")
const TEAL := Color("#4bd7c1")
const PINK := Color("#ff6883")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(W,H)

func rect(r: Rect2, color: Color, border: Color = Color.TRANSPARENT) -> void:
	draw_rect(r,color)
	if border.a>0.01:draw_rect(r,border,false,1.5)

func txt(s: String, pos: Vector2, size: int=26, color: Color=PAPER, center: bool=false) -> void:
	var font := ThemeDB.fallback_font
	var x := pos.x
	if center:
		x-=font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*0.5
	draw_string(font,Vector2(x,pos.y),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func button(r: Rect2, name: String, selected: bool=false) -> void:
	rect(r,Color("#19334a") if not selected else Color("#e9c372"),TEAL if not selected else GOLD)
	if selected:
		rect(Rect2(r.position.x+1,r.position.y+1,5,r.size.y-2),Color("#ffffff"))
	txt(name,r.position+Vector2(20,r.size.y*0.66),24,NAVY if selected else PAPER)
	draw_circle(r.position+Vector2(r.size.x-24,r.size.y/2),12,Color("#2f6170") if not selected else Color("#977a44"))
	txt("›",r.position+Vector2(r.size.x-30,r.size.y*0.64),26,PAPER)

func header(title: String, subtitle: String) -> void:
	rect(Rect2(0,0,W,H),Color(0.035,0.075,0.13,0.85))
	rect(Rect2(0,0,W,9),GOLD)
	txt("‹  ANA MENÜ",Vector2(48,63),20,MUTED)
	txt(title,Vector2(55,147),57,PAPER)
	txt(subtitle,Vector2(55,184),21,MUTED)
	rect(Rect2(48,206,1185,1),Color("#496279"))

func stat_card(r: Rect2, heading: String, big: String, unit: String = "") -> void:
	rect(r,Color("#142b3c"),Color("#375268"))
	rect(Rect2(r.position.x,r.position.y,5,r.size.y),GOLD)
	txt(heading,r.position+Vector2(24,32),17,MUTED)
	txt(big,r.position+Vector2(23,89),45,PAPER)
	if unit!="":txt(unit,r.position+Vector2(24,r.size.y-16),16,TEAL)

func pill(center: Vector2, radius: float, label: String, c: Color, note: String="") -> void:
	draw_circle(center,radius,Color(0.035,0.10,0.17,0.85))
	draw_arc(center,radius,0,TAU,40,c,3.3)
	txt(label,center+Vector2(0,9),23,PAPER,true)
	if note!="":txt(note,center+Vector2(0,radius+18),16,MUTED,true)

func _draw() -> void:
	if game==null:return
	match game.page:
		"home": home_screen()
		"career": career_screen()
		"shop": shop_screen()
		"tactics": tactics_screen()
		"cup": cup_screen()
		"results": results_screen()
		"match": match_screen()

func home_screen() -> void:
	rect(Rect2(0,0,635,720),Color(0.03,0.08,0.14,0.94))
	rect(Rect2(0,0,10,720),GOLD)
	txt("TA    |    FOOTBALL UNIVERSE",Vector2(60,75),23,TEAL)
	txt("TRIBUN",Vector2(58,183),78,PAPER)
	txt("ARENA",Vector2(58,267),89,GOLD)
	txt("SAHAYA ÇIK. EFSANENİ YAZ.",Vector2(64,304),21,MUTED)
	button(Rect2(58,342,516,60),"HIZLI MAÇ",true)
	button(Rect2(58,411,516,60),"KULÜP KARİYERİ")
	button(Rect2(58,480,516,60),"ELEME KUPASI")
	button(Rect2(58,549,516,60),"ŞUT ANTRENMANI")
	button(Rect2(58,618,516,60),"ZORLUK: "+(["","KOLAY","NORMAL","ZOR"][game.difficulty]))
	rect(Rect2(727,58,498,106),Color(0.035,0.085,0.14,0.77),Color("#668199"))
	txt("GECE MAÇI • 3D STADYUM",Vector2(754,99),23,GOLD)
	txt("7v7  •  YAPAY ZEKÂ  •  KARİYER",Vector2(754,135),21,PAPER)
	rect(Rect2(750,578,457,105),Color(0.035,0.075,0.13,0.82),Color("#334b5c"))
	txt("TOPLAM KUPA",Vector2(773,617),17,MUTED)
	txt(str(game.trophy_count),Vector2(773,660),35,GOLD)
	txt("KULÜP BÜTÇESİ",Vector2(975,617),17,MUTED)
	txt(str(game.coins)+" ALTIN",Vector2(975,660),28,TEAL)

func career_screen() -> void:
	header("KULÜP KARİYERİ","14 maçlık lig • taktikler • kadro gelişimi • şampiyonluk")
	stat_card(Rect2(58,235,262,137),"SEZON",str(game.season),"KARTAL 1903")
	stat_card(Rect2(334,235,262,137),"LİG MAÇI",str(game.round_number)+"/14","HAZIR OL")
	stat_card(Rect2(610,235,262,137),"BÜTÇE",str(game.coins),"ALTIN")
	stat_card(Rect2(886,235,327,137),"KUPALAR",str(game.trophy_count),"TARİHE GEÇ")
	txt("LİG SIRALAMASI",Vector2(60,415),31,GOLD)
	var board: Array[Dictionary] = game.ordered_table()
	for i in range(mini(5,board.size())):
		var entry: Dictionary = board[i]
		var pos := Vector2(60,451+i*37)
		var is_ours := str(entry["name"]) == "KARTAL 1903"
		if is_ours:rect(Rect2(50,pos.y-22,550,33),Color("#284d57"))
		txt(str(i+1)+".  "+str(entry["name"]),pos,21,TEAL if is_ours else PAPER)
		txt(str(game.points_of(entry))+" P",Vector2(537,pos.y),20,GOLD)
	rect(Rect2(625,426,583,208),Color("#112638"),Color("#496279"))
	txt("SONRAKİ RAKİP",Vector2(650,464),18,MUTED)
	txt(game.CLUB_NAMES[(game.round_number%7)+1],Vector2(651,505),32,PAPER)
	txt("Formasyon "+formation_name()+"   •   "+tactic_name(),Vector2(651,547),19,TEAL)
	button(Rect2(650,564,527,54),"SONRAKİ MAÇA ÇIK",true)
	button(Rect2(58,656,345,50),"KADRO GELİŞTİR")
	button(Rect2(420,656,350,50),"TAKTİKLER")
	button(Rect2(787,656,425,50),"ANA MENÜ")

func shop_screen() -> void:
	header("KADRO GELİŞTİR","Maçlardan kazandığın altınla takımının gücünü yükselt.")
	stat_card(Rect2(55,244,258,129),"BÜTÇEN",str(game.coins),"MEVCUT ALTIN")
	var kinds := ["attack","defense","fitness"]
	var names := ["HÜCUM","SAVUNMA","KONDİSYON"]
	var val := [game.upgrade_attack,game.upgrade_defense,game.upgrade_fitness]
	for i in range(3):
		var x := 343.0+float(i)*296.0
		rect(Rect2(x,244,276,345),Color("#132b3e"),Color("#4a687a"))
		rect(Rect2(x,244,276,7),GOLD if i==0 else (TEAL if i==1 else PINK))
		txt(names[i],Vector2(x+24,300),26,PAPER)
		txt(str(val[i])+"/95",Vector2(x+24,388),52,GOLD)
		txt("Kadro puanı",Vector2(x+24,426),17,MUTED)
		var cost: int=200+(val[i]-50)*14
		button(Rect2(x+15,488,245,65),"GÜÇLENDİR  "+str(cost),true)
	button(Rect2(60,645,395,59),"KARİYERE DÖN")

func formation_name() -> String:
	return ["2-2-2","3-2-1","2-3-1"][game.formation]

func tactic_name() -> String:
	return ["DENGELİ","YÜKSEK PRES","KONTRA"][game.tactic]

func tactics_screen() -> void:
	header("TAKTİK TAHTASI","Sahadaki dizilişi ve oyun anlayışını belirle.")
	stat_card(Rect2(63,248,350,160),"FORMASYON",formation_name(),"TAKIM YAPISI")
	stat_card(Rect2(428,248,367,160),"OYUN PLANI",tactic_name(),"TAKTİK")
	rect(Rect2(834,237,357,340),Color("#1a5b40"),Color("#ebefe6"))
	draw_line(Vector2(1013,237),Vector2(1013,577),Color("#d4ded6"),2)
	draw_arc(Vector2(1013,403),34,0,TAU,36,Color("#c5d8c8"),2)
	for n in range(7):
		var p: Vector2 = game.formation_position(0,n)
		var center := Vector2(1013+p.x*3.06,403+p.y*4.65)
		draw_circle(center,10,TEAL if n>0 else GOLD)
	button(Rect2(66,461,331,62),"DEĞİŞTİR: DİZİLİŞ",true)
	button(Rect2(427,461,358,62),"DEĞİŞTİR: TAKTİK")
	button(Rect2(65,620,509,68),"KARİYERE DÖN")

func cup_screen() -> void:
	header("ELEME KUPASI","Dört galibiyet. Tek şampiyon. Büyük ödül.")
	txt("TRİBÜN KUPASI",Vector2(640,286),60,GOLD,true)
	for i in range(4):
		var x := 110.0+float(i)*278
		rect(Rect2(x,346,257,147),Color("#173146"),GOLD if i<=game.cup_round else Color("#3d5260"))
		txt(str(i+1)+". TUR",Vector2(x+128,397),34,PAPER,true)
		txt("TAMAMLANDI" if i<game.cup_round else ("SIRADAKİ" if i==game.cup_round else "KİLİTLİ"),Vector2(x+128,451),20,TEAL if i<=game.cup_round else MUTED,true)
	button(Rect2(365,565,550,74),"KUPA MAÇINI BAŞLAT",true)
	button(Rect2(365,652,550,50),"ANA MENÜ")

func results_screen() -> void:
	rect(Rect2(0,0,W,H),Color(0.04,0.095,0.15,0.90))
	rect(Rect2(0,0,W,8),GOLD)
	txt("MAÇ SONU",Vector2(640,116),41,GOLD,true)
	txt("KARTAL 1903",Vector2(346,221),34,PAPER,true)
	txt(game.CLUB_NAMES[game.opponent],Vector2(934,221),34,PAPER,true)
	txt(str(game.score[0])+"  :  "+str(game.score[1]),Vector2(640,321),82,PAPER,true)
	txt("GOLLER • PASLAR • MÜCADELE",Vector2(640,385),20,MUTED,true)
	var a := [game.shots,game.passes,game.steals]
	var labels := ["ŞUTLAR","PASLAR","TOP KAPMA"]
	for i in range(3):
		var y := 435.0+float(i)*46
		txt(labels[i],Vector2(640,y),20,MUTED,true)
		txt(str(a[i][0]),Vector2(438,y),22,TEAL,true)
		txt(str(a[i][1]),Vector2(840,y),22,PINK,true)
	button(Rect2(350,596,580,70),"DEVAM ET",true)
	if game.message_timer>0:
		txt(game.message,Vector2(640,571),27,GOLD,true)

func match_screen() -> void:
	rect(Rect2(311,11,657,78),Color(0.025,0.075,0.14,0.92),Color("#416177"))
	rect(Rect2(311,11,657,5),GOLD)
	txt("KARTAL 1903",Vector2(338,52),23,PAPER)
	txt(str(game.score[0])+"  -  "+str(game.score[1]),Vector2(639,54),39,GOLD,true)
	txt(game.CLUB_NAMES[game.opponent],Vector2(786,52),21,PAPER,true)
	var minute := mini(90,int(game.clock/maxf(1,game.length)*90.0))
	rect(Rect2(975,18,135,57),Color(0.025,0.07,0.12,0.8))
	txt(str(minute)+"'",Vector2(1039,54),32,TEAL,true)
	txt("✕",Vector2(40,64),29,PAPER)
	rect(Rect2(334,93,554,25),Color(0.015,0.055,0.10,0.6))
	draw_rect(Rect2(334,93,554.0*game.clock/maxf(game.length,0.01),25),Color("#d4ac5c"))
	txt("7v7 • "+("LİG" if game.mode=="career" else ("KUPA" if game.mode=="cup" else ("ANTRENMAN" if game.mode=="training" else "HIZLI MAÇ"))),Vector2(617,112),16,PAPER,true)
	# translucent virtual joystick
	draw_circle(Vector2(160,565),94,Color(0.035,0.1,0.15,0.65))
	draw_arc(Vector2(160,565),93,0,TAU,52,Color("#c2d3d4"),3)
	draw_circle(Vector2(160,565)+game.joystick*72.0,38,Color("#f0c976"))
	draw_circle(Vector2(160,565)+game.joystick*72.0,23,Color("#28445a"))
	pill(Vector2(1109,504),64,"ŞUT",GOLD)
	pill(Vector2(968,570),58,"PAS",TEAL)
	pill(Vector2(1146,642),52,"PRES",PINK)
	pill(Vector2(833,644),48,"DEĞİŞ",MUTED)
	pill(Vector2(1217,338),46,"KOŞ",TEAL)
	# tactical mini-map
	rect(Rect2(473,578,239,121),Color(0.025,0.105,0.105,0.63),Color("#82b4a6"))
	draw_line(Vector2(592,582),Vector2(592,696),Color("#8eb7aa"),1.0)
	for p in game.players:
		var pos: Vector2=p["pos"]
		draw_circle(Vector2(592+pos.x*2.05,639+pos.y*1.73),4.5,TEAL if int(p["team"])==0 else PINK)
	draw_circle(Vector2(592+game.ball_pos.x*2.05,639+game.ball_pos.z*1.73),3.8,GOLD)
	if game.message_timer>0:
		rect(Rect2(342,155,596,63),Color(0.025,0.07,0.12,0.83))
		txt(game.message,Vector2(640,198),32,GOLD,true)

func _input(event: InputEvent) -> void:
	if game==null:return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed: press_at(touch.position,touch.index)
		else: release_touch(touch.index)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index==joy_finger:
			game.joystick=((drag.position-Vector2(160,565))/82.0).limit_length(1.0)
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		if mouse.button_index==MOUSE_BUTTON_LEFT:
			if mouse.pressed:press_at(mouse.position,-1)
			else:release_touch(-1)
	elif event is InputEventMouseMotion and joy_finger==-1:
		var move: InputEventMouseMotion=event as InputEventMouseMotion
		game.joystick=((move.position-Vector2(160,565))/82.0).limit_length(1.0)

func release_touch(index: int) -> void:
	if index==joy_finger:
		joy_finger=-100
		game.joystick=Vector2.ZERO
	if index==run_finger:
		run_finger=-100
		game.sprint=false

func press_at(pos: Vector2,index: int) -> void:
	if game.page=="match":
		if pos.x<300 and pos.y>422:
			joy_finger=index
			game.joystick=((pos-Vector2(160,565))/82.0).limit_length(1.0)
		elif pos.distance_to(Vector2(1217,338))<64:
			run_finger=index
			game.sprint=true
		elif pos.distance_to(Vector2(1109,504))<78:
			game.action_shoot()
		elif pos.distance_to(Vector2(968,570))<76:
			game.action_pass()
		elif pos.distance_to(Vector2(1146,642))<67:
			game.action_tackle()
		elif pos.distance_to(Vector2(833,644))<64:
			game.action_switch()
		elif pos.x<99 and pos.y<96:
			game.end_match()
		return
	if pos.x<245 and pos.y<93 and game.page!="home":
		game.go_to("home")
		return
	match game.page:
		"home":
			if Rect2(58,342,516,60).has_point(pos): game.start_match("quick")
			elif Rect2(58,411,516,60).has_point(pos):game.go_to("career")
			elif Rect2(58,480,516,60).has_point(pos):game.go_to("cup")
			elif Rect2(58,549,516,60).has_point(pos):game.start_match("training")
			elif Rect2(58,618,516,60).has_point(pos):
				game.difficulty=(game.difficulty%3)+1
				game.save_progress()
		"career":
			if Rect2(650,564,527,54).has_point(pos):game.start_match("career")
			elif Rect2(58,656,345,50).has_point(pos):game.go_to("shop")
			elif Rect2(420,656,350,50).has_point(pos):game.go_to("tactics")
			elif Rect2(787,656,425,50).has_point(pos):game.go_to("home")
		"shop":
			if Rect2(358,488,245,65).has_point(pos):game.purchase_upgrade("attack")
			elif Rect2(654,488,245,65).has_point(pos):game.purchase_upgrade("defense")
			elif Rect2(950,488,245,65).has_point(pos):game.purchase_upgrade("fitness")
			elif Rect2(60,645,395,59).has_point(pos):game.go_to("career")
		"tactics":
			if Rect2(66,461,331,62).has_point(pos):
				game.formation=(game.formation+1)%3
				game.save_progress()
			elif Rect2(427,461,358,62).has_point(pos):
				game.tactic=(game.tactic+1)%3
				game.save_progress()
			elif Rect2(65,620,509,68).has_point(pos):game.go_to("career")
		"cup":
			if Rect2(365,565,550,74).has_point(pos):game.start_match("cup")
			elif Rect2(365,652,550,50).has_point(pos):game.go_to("home")
		"results":
			game.go_to("career" if game.mode=="career" else ("cup" if game.mode=="cup" else "home"))
