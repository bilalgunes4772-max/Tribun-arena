extends Control
## TRIBUN ARENA DIRECTOR mobile UI: dense PC-style information, touch-friendly controls.
const CORE = preload("res://scripts/director_core.gd")
const BG := Color("#09121f")
const PANEL := Color("#112239")
const PANEL2 := Color("#182c43")
const BORDER := Color("#2b4058")
const WHITE := Color("#edf5fa")
const MUTED := Color("#9cb1c4")
const GOLD := Color("#edc46d")
const TEAL := Color("#50d4c0")
const RED := Color("#fa8290")
const NAV := ["MERKEZ","KADRO","TAKTİK","TRANSFER","SCOUT","ANTRENMAN","FİNANS","ALTYAPI","PERSONEL","LİG","HABERLER"]
var sim = null
var tab: String="MERKEZ"
var selected_pid: int=-1
var notification: String=""
var root_col: VBoxContainer
var body_col: VBoxContainer

func _ready() -> void:
	sim=CORE.new()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents=true
	render()

func style(color: Color, border: Color=BORDER, radius: int=10, pad: int=14) -> StyleBoxFlat:
	var s: StyleBoxFlat=StyleBoxFlat.new()
	s.bg_color=color
	s.border_color=border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left=pad
	s.content_margin_right=pad
	s.content_margin_top=pad
	s.content_margin_bottom=pad
	return s

func label(text: String, size: int=20, color: Color=WHITE, wide: bool=false) -> Label:
	var l: Label=Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	if wide:l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return l

func button(text: String, handler: Callable, primary: bool=false) -> Button:
	var b: Button=Button.new()
	b.text=text
	b.custom_minimum_size=Vector2(124,50)
	b.add_theme_font_size_override("font_size",17)
	b.add_theme_color_override("font_color",BG if primary else WHITE)
	b.add_theme_color_override("font_hover_color",BG if primary else WHITE)
	b.add_theme_color_override("font_pressed_color",BG if primary else WHITE)
	b.add_theme_stylebox_override("normal",style(GOLD if primary else PANEL2,GOLD if primary else BORDER,8,12))
	b.add_theme_stylebox_override("hover",style(TEAL if primary else Color("#274b67"),TEAL,8,12))
	b.add_theme_stylebox_override("pressed",style(TEAL if primary else GOLD,TEAL,8,12))
	b.add_theme_stylebox_override("focus",style(Color.TRANSPARENT,TEAL,8,12))
	b.pressed.connect(handler)
	return b

func hrow(gap: int=12) -> HBoxContainer:
	var h: HBoxContainer=HBoxContainer.new()
	h.add_theme_constant_override("separation",gap)
	h.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return h

func vcol(gap: int=10) -> VBoxContainer:
	var v: VBoxContainer=VBoxContainer.new()
	v.add_theme_constant_override("separation",gap)
	v.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return v

func panel_container() -> PanelContainer:
	var p: PanelContainer=PanelContainer.new()
	p.add_theme_stylebox_override("panel",style(PANEL))
	p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return p

func block(title: String, description: String="") -> VBoxContainer:
	var pan: PanelContainer=panel_container()
	body_col.add_child(pan)
	var v: VBoxContainer=vcol(12)
	pan.add_child(v)
	v.add_child(label(title,27,GOLD))
	if description!="":v.add_child(label(description,17,MUTED))
	return v

func note_message(s: String) -> void:
	notification=s
	render()

func nav_page(name: String) -> void:
	tab=name
	notification=""
	render()

func _change_setting(setting: String, direction: int=1) -> void:
	match setting:
		"on":sim.formation_on=posmod(sim.formation_on+direction,sim.FORMATIONS.size())
		"off":sim.formation_off=posmod(sim.formation_off+direction,sim.FORMATIONS.size())
		"mentality":sim.mentality=posmod(sim.mentality+direction,sim.MENTALITIES.size())
		"pressing":sim.pressing=posmod(sim.pressing+direction,3)
		"tempo":sim.tempo=posmod(sim.tempo+direction,3)
		"width":sim.width=posmod(sim.width+direction,3)
		"training":sim.focus=posmod(sim.focus+direction,sim.TRAINING.size())
		"intensity":sim.intensity=posmod(sim.intensity+direction,3)
	if setting=="on" or setting=="off":sim.familiarity=maxf(20,sim.familiarity-1.8)
	sim.save_game()
	render()

func _toggle_xi(pid: int) -> void:
	note_message(sim.toggle_starter(pid))
func _rotate_role(pid: int) -> void:
	note_message(sim.change_role(pid))
func _renew(pid: int) -> void:
	note_message(sim.renew(pid))
func _sell(pid: int) -> void:
	note_message(sim.sell(pid))
func _scout(pid: int) -> void:
	note_message(sim.scout(pid))
func _bid(pid: int, multiplier: float) -> void:
	note_message(sim.transfer_bid(pid,multiplier))
func _staff(kind: String) -> void:
	note_message(sim.staff_upgrade(kind))
func _academy(kind: String) -> void:
	note_message(sim.academy_upgrade() if kind=="facility" else sim.academy_promote())
func _auto_xi() -> void:
	sim.auto_choose_xi()
	sim.save_game()
	note_message("En yüksek rol puanlarına göre ilk 11 oluşturuldu.")
func _start_match() -> void:
	var result: String=sim.kickoff()
	if not sim.current_match.is_empty():tab="MAÇ"
	note_message(result)
func _second_half() -> void:
	note_message(sim.finish_match())
func _finish_match_screen() -> void:
	sim.close_match()
	nav_page("MERKEZ")
func _new_season() -> void:
	note_message(sim.next_season())
func _select_player(pid: int) -> void:
	selected_pid=pid
	render()

func render() -> void:
	for c in get_children():c.queue_free()
	var back: ColorRect=ColorRect.new()
	back.color=BG
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(back)
	root_col=vcol(0)
	root_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root_col)
	var head: HBoxContainer=hrow(14)
	head.custom_minimum_size.y=75
	head.add_theme_stylebox_override("panel",style(PANEL)) if false else null
	root_col.add_child(head)
	var brand: VBoxContainer=vcol(0)
	brand.custom_minimum_size.x=350
	head.add_child(brand)
	brand.add_child(label("TRIBUN  /  DIRECTOR",29,GOLD))
	brand.add_child(label("THE COMPLETE MANAGER EXPERIENCE  •  ALFA 0.3",12,MUTED))
	var season_text: String="SEZON "+str(sim.season)+"/"+str(sim.season+1)+"  •  HAFTA "+str(mini(22,sim.round_no+1))+"/22"
	head.add_child(label(season_text,18,WHITE,true))
	head.add_child(label("BÜTÇE "+money(sim.balance),20,TEAL))
	head.add_child(button("KAYDET",Callable(self,"_save_game")))
	var nav_scroll: ScrollContainer=ScrollContainer.new()
	nav_scroll.custom_minimum_size.y=66
	nav_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO
	nav_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root_col.add_child(nav_scroll)
	var navbar: HBoxContainer=hrow(5)
	nav_scroll.add_child(navbar)
	var visible_nav: Array=NAV.duplicate()
	if not sim.current_match.is_empty():visible_nav.insert(0,"MAÇ")
	for name in visible_nav:
		var b: Button=button(str(name),Callable(self,"nav_page").bind(str(name)),tab==name)
		b.custom_minimum_size=Vector2(112,55)
		navbar.add_child(b)
	if notification!="":
		var notice: PanelContainer=PanelContainer.new()
		notice.add_theme_stylebox_override("panel",style(Color("#234451"),TEAL,2,7))
		root_col.add_child(notice)
		var ntext: Label=label(notification,18,WHITE)
		notice.add_child(ntext)
	var scroll: ScrollContainer=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root_col.add_child(scroll)
	body_col=vcol(16)
	body_col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(body_col)
	match tab:
		"MERKEZ":home()
		"KADRO":roster()
		"TAKTİK":tactics()
		"TRANSFER":transfers()
		"SCOUT":scouting()
		"ANTRENMAN":training()
		"FİNANS":finance()
		"ALTYAPI":academy()
		"PERSONEL":staff()
		"LİG":league()
		"HABERLER":inbox_screen()
		"MAÇ":match_center()
		_:home()

func _save_game() -> void:
	sim.save_game()
	note_message("Kariyer kaydedildi.")

func money(amount: int) -> String:
	if abs(amount)>=1000:return str(snappedf(float(amount)/1000.0,0.1))+" M€"
	return str(amount)+" B€"

func metrics(container: VBoxContainer, names: Array, values: Array, colors: Array=[]) -> void:
	var row: HBoxContainer=hrow(10)
	container.add_child(row)
	for i in range(names.size()):
		var box: PanelContainer=panel_container()
		box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(box)
		var inner: VBoxContainer=vcol(3)
		box.add_child(inner)
		inner.add_child(label(str(names[i]),15,MUTED))
		var colored: Color=TEAL
		if i<colors.size():colored=colors[i]
		inner.add_child(label(str(values[i]),29,colored))

func home() -> void:
	var intro: VBoxContainer=block("MENAJERLİK MERKEZİ","KARTAL 1903   •   Kulübün geleceği senin kararlarına bağlı.")
	var board: Array[Dictionary]=sim.league_table()
	var rank: int=1
	for i in range(board.size()):
		if int(board[i]["id"])==0:rank=i+1
	metrics(intro,["LİG SIRASI","KULÜP BÜTÇESİ","TAKTİK ETKİNLİĞİ","KADRO MORALİ"],
		[str(rank)+"/12",money(sim.balance),str(roundi(sim.training_effectiveness()))+"%",str(roundi(sim.confidence))+"%"],[GOLD,TEAL,GOLD,WHITE])
	var next: VBoxContainer=block("SONRAKİ MAÇ","Maç gününe geçmeden önce kadronu, taktiğini ve antrenman hedefini kontrol et.")
	var fixture: Array=sim.next_fixture()
	if fixture.is_empty():
		next.add_child(label("Sezon tamamlandı. Yeni sezonda farklı hedeflere hazırlan.",22,GOLD))
		next.add_child(button("YENİ SEZONU BAŞLAT",Callable(self,"_new_season"),true))
	else:
		var home_idx: int=int(fixture[0])
		var away_idx: int=int(fixture[1])
		next.add_child(label(sim.CLUB_NAMES[home_idx]+"   VS   "+sim.CLUB_NAMES[away_idx],29,WHITE))
		next.add_child(label("Diziliş: "+sim.FORMATIONS[sim.formation_on]+" / "+sim.FORMATIONS[sim.formation_off]+"  •  Mentalite: "+sim.MENTALITIES[sim.mentality],18,MUTED))
		var actions: HBoxContainer=hrow()
		next.add_child(actions)
		if sim.current_match.is_empty(): actions.add_child(button("MAÇ GÜNÜNE GEÇ",Callable(self,"_start_match"),true))
		else:actions.add_child(button("MAÇ MERKEZİNE DÖN",Callable(self,"nav_page").bind("MAÇ"),true))
		actions.add_child(button("TAKTİK PANOSU",Callable(self,"nav_page").bind("TAKTİK")))
		actions.add_child(button("İLK 11",Callable(self,"nav_page").bind("KADRO")))
	var analysis: VBoxContainer=block("TEKNİK EKİP ANALİZİ","Oyunun motoru; taktik uyumu, form, ilk 11, moral ve oyuncu kalitesini birlikte hesaplar.")
	analysis.add_child(label("Taktik anlayışı "+str(roundi(sim.familiarity))+"/100    •    Takım uyumu "+str(roundi(sim.cohesion))+"/100    •    Yönetim güveni "+str(roundi(sim.confidence))+"/100",20,TEAL))
	analysis.add_child(label("İlk 11: "+str(sim.starter_count())+"/11   |   Kadro oyuncuları: "+str(sim.my_players().size())+"   |   Transfer penceresi açık",19,WHITE))
	if not sim.inbox.is_empty():
		var news: Dictionary=sim.inbox[0]
		analysis.add_child(label("SON HABER  —  "+str(news["title"]),20,GOLD))
		analysis.add_child(label(str(news["body"]),18,MUTED))

func player_summary(p: Dictionary, known: bool=true) -> String:
	if not known:
		return str(p["pos"])+"  •  "+str(p["age"])+" yaş  •  Rapor bekleniyor"
	return str(p["pos"])+"  •  GEN "+str(sim.overall(p))+"  •  POT "+str(p["potential"])+"  •  FORM "+str(p["fitness"])+"  •  MORAL "+str(p["morale"])+"  •  "+money(int(p["value"]))

func roster() -> void:
	var section: VBoxContainer=block("A TAKIM KADROSU","İlk 11'i belirle, oyuncuların rollerini değiştir, kontratlarını yenile ve satış kararları al.")
	var controls: HBoxContainer=hrow()
	section.add_child(controls)
	controls.add_child(button("EN İYİ 11'İ SEÇ",Callable(self,"_auto_xi"),true))
	controls.add_child(label("İlk 11: "+str(sim.starter_count())+"/11    •    1 KL, 4 savunmacı, 5 orta saha, 1 forvet",18,MUTED))
	var squad: Array[Dictionary]=sim.my_players()
	for p in squad:
		var row: HBoxContainer=hrow(12)
		section.add_child(row)
		row.add_child(label(("● " if bool(p["starter"]) else "○ ")+str(p["name"]),20,TEAL if bool(p["starter"]) else WHITE,true))
		row.add_child(label(str(p["pos"])+"  G"+str(sim.overall(p))+"  "+str(p["fitness"])+"%",18,MUTED))
		row.add_child(button("İNCELE",Callable(self,"_select_player").bind(int(p["id"]))))
		row.add_child(button("11'E AL" if not bool(p["starter"]) else "YEDEĞE AL",Callable(self,"_toggle_xi").bind(int(p["id"]))))
		if int(p["injury"])>0:row.add_child(label("SAKAT "+str(p["injury"])+" HAFTA",16,RED))
		section.add_child(line_divider())
	if selected_pid<0 and not squad.is_empty():selected_pid=int(squad[0]["id"])
	var chosen: Dictionary=sim.get_player(selected_pid)
	if chosen.is_empty() or int(chosen.get("club",-1))!=0:return
	var detail: VBoxContainer=block("OYUNCU RAPORU  /  "+str(chosen["name"]))
	detail.add_child(label(player_summary(chosen),20,TEAL))
	metrics(detail,["TEKNİK","PAS","BİTİRİCİLİK","SAVUNMA","FİZİK","MENTAL"],
		[chosen["tek"],chosen["pas"],chosen["bit"],chosen["def"],chosen["fiz"],chosen["men"]])
	detail.add_child(label("Yaş: "+str(chosen["age"])+"   •   Tercih ettiği ayak: "+str(chosen["foot"])+"   •   Sözleşme: "+str(chosen["contract"])+" yıl   •   Maaş: "+str(chosen["wage"])+" bin €/hafta   •   Rol: "+sim.ROLES[int(chosen["role"])],17,MUTED))
	var actions: HBoxContainer=hrow()
	detail.add_child(actions)
	actions.add_child(button("ROLÜ DEĞİŞTİR",Callable(self,"_rotate_role").bind(selected_pid)))
	actions.add_child(button("SÖZLEŞME YENİLE",Callable(self,"_renew").bind(selected_pid)))
	actions.add_child(button("TRANSFERLE SAT",Callable(self,"_sell").bind(selected_pid)))

func option_row(container: VBoxContainer, title: String, value: String, key: String, explanation: String) -> void:
	var row: HBoxContainer=hrow()
	container.add_child(row)
	var texts: VBoxContainer=vcol(3)
	texts.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	texts.add_child(label(title,22,WHITE))
	texts.add_child(label(explanation,16,MUTED))
	row.add_child(button(value+"   DEĞİŞTİR",Callable(self,"_change_setting").bind(key)))
	container.add_child(line_divider())

func tactics() -> void:
	var top: VBoxContainer=block("TAKTİK LABORATUVARI","PC düzeyinde iki evreli planlama: hücumdayken ve top rakipteyken farklı dizilişler.")
	metrics(top,["TAKTİK ETKİNLİĞİ","OYUN ANLAYIŞI","TAKIM UYUMU"],
		[str(roundi(sim.training_effectiveness()))+"%",str(roundi(sim.familiarity))+"%",str(roundi(sim.cohesion))+"%"],[GOLD,TEAL,TEAL])
	option_row(top,"TOPA SAHİPKEN DİZİLİŞ",sim.FORMATIONS[sim.formation_on],"on","Top sendeyken hücum genişliğini ve rollerin yönünü belirler.")
	option_row(top,"TOP RAKİPTEYKEN DİZİLİŞ",sim.FORMATIONS[sim.formation_off],"off","Takım savunmaya geçtiğinde başka bir şekle dönüşür.")
	option_row(top,"MENTALİTE",sim.MENTALITIES[sim.mentality],"mentality","Fırsat üretimi ile savunma güvenliği arasındaki denge.")
	option_row(top,"PRES ŞİDDETİ",["Düşük blok","Standart","Önde baskı"][sim.pressing],"pressing","Yüksek pres fırsat getirir ama daha çok kondisyon tüketir.")
	option_row(top,"OYUN TEMPOSU",["Sabırlı","Dengeli","Yüksek"][sim.tempo],"tempo","Hızlı tempo daha fazla fırsat, daha fazla top kaybı riski.")
	option_row(top,"SAHA GENİŞLİĞİ",["Dar","Dengeli","Geniş"][sim.width],"width","Beklerin ve kanatların oyun pozisyonuna etkisi.")
	var notes: VBoxContainer=block("TAKTİKSEL RİSK ANALİZİ","Kompleks ve sık değişen taktikler kısa vadede uyumu azaltır.")
	var diff: int=absi(sim.formation_on-sim.formation_off)
	notes.add_child(label("Geçiş karmaşıklığı: "+("DÜŞÜK" if diff==0 else ("ORTA" if diff<=1 else "YÜKSEK"))+"   •   Antrenmanla uyumu geliştirebilirsin.",20,GOLD))
	notes.add_child(button("ANTRENMAN PLANINA GİT",Callable(self,"nav_page").bind("ANTRENMAN")))

func transfers() -> void:
	var section: VBoxContainer=block("TRANSFER MERKEZİ","Satın alımlar bütçeyi azaltır, maaşları artırır; yeni gelen futbolcu önce takım uyumuna ihtiyaç duyar.")
	metrics(section,["TRANSFER BÜTÇESİ","KADRO BOYUTU","SCOUT AĞI"],[money(sim.balance),str(sim.my_players().size()),"SEVİYE "+str(sim.scout_level)])
	section.add_child(label("ALTERNATİF TEKLİFLER  /  %105 ve %130 piyasa değeri",19,GOLD))
	var candidates: Array[Dictionary]=sim.market_players()
	for i in range(mini(19,candidates.size())):
		var p: Dictionary=candidates[i]
		var row: HBoxContainer=hrow(10)
		section.add_child(row)
		row.add_child(label(str(p["name"]),20,WHITE,true))
		row.add_child(label(str(p["pos"])+"  "+str(p["age"])+"y  •  "+("GEN "+str(sim.overall(p)) if bool(p["known"]) else "GİZLİ"),16,MUTED))
		row.add_child(label(money(int(p["value"])) if bool(p["known"]) else "RAPOR YOK",17,GOLD))
		row.add_child(button("SCOUT",Callable(self,"_scout").bind(int(p["id"]))))
		row.add_child(button("TEKLİF %105",Callable(self,"_bid").bind(int(p["id"]),1.05)))
		row.add_child(button("TEKLİF %130",Callable(self,"_bid").bind(int(p["id"]),1.30),true))
		section.add_child(line_divider())

func scouting() -> void:
	var section: VBoxContainer=block("SCOUT VE YETENEK HAVUZU","Gizli yetenekleri raporla; 1 maç haftası sonra değer, kalite ve potansiyel verileri açılır.")
	var market: Array[Dictionary]=sim.market_players()
	metrics(section,["SCOUT DEPARTMANI","DEVAM EDEN RAPOR","RAPOR MALİYETİ"],
		[str(sim.scout_level)+"/5",str(sim.pending_scout.size()),"90 B€"])
	for i in range(mini(25,market.size())):
		var p: Dictionary=market[i]
		var row: HBoxContainer=hrow(9)
		section.add_child(row)
		row.add_child(label(str(p["name"]),20,WHITE,true))
		row.add_child(label(str(p["pos"])+" • "+str(p["age"])+" yaş • "+sim.CLUB_NAMES[int(p["club"])],16,MUTED))
		row.add_child(label(("GEN "+str(sim.overall(p))+" / POT "+str(p["potential"])) if bool(p["known"]) else "BİLGİ YOK",18,TEAL if bool(p["known"]) else GOLD))
		row.add_child(button("RAPOR İSTE",Callable(self,"_scout").bind(int(p["id"]))))
		section.add_child(line_divider())

func training() -> void:
	var section: VBoxContainer=block("HAFTALIK ANTRENMAN PROGRAMI","Antrenman, taktik anlayışını ve futbolcuların bireysel özelliklerini geliştirir.")
	metrics(section,["TAKTİK HAZIRLIK","TAKIM KİMYASI","KONDİSYON ANTRENÖRÜ"],
		[str(roundi(sim.familiarity))+"%",str(roundi(sim.cohesion))+"%","SEVİYE "+str(sim.coaching_level)])
	option_row(section,"ANTRENMAN ODAĞI",sim.TRAINING[sim.focus],"training","Bir sonraki maç için en uygun hazırlığı belirle.")
	option_row(section,"YÜKLENME",["Hafif","Orta","Ağır"][sim.intensity],"intensity","Ağır yüklenme sakatlık riski taşır, bireysel gelişimi hızlandırır.")
	section.add_child(label("Teknik direktör tavsiyesi: Çok karmaşık taktiklerde önce takım uyumunu geliştirmeyi tercih et.",19,GOLD))
	section.add_child(button("TAKTİKLERE GERİ DÖN",Callable(self,"nav_page").bind("TAKTİK")))

func finance() -> void:
	var section: VBoxContainer=block("KULÜP FİNANS RAPORU","Tüm rakamlar bin € cinsindendir. Yayın, sponsor, maaş, transfer, stadyum giderleri ve altyapı yatırımları nakit akışını etkiler.")
	var payroll: int=0
	for p in sim.footballers:
		if int(p["club"])==0:payroll+=int(p["wage"])
	metrics(section,["KULÜP NAKİTİ","HAFTALIK FUTBOLCU MAAŞI","KADRO DEĞERİ"],
		[money(sim.balance),money(payroll),money(_squad_value())],[TEAL,GOLD,WHITE])
	var ledger: VBoxContainer=block("MUHASEBE HAREKETLERİ")
	for e in sim.money_log:
		var row: HBoxContainer=hrow()
		ledger.add_child(row)
		row.add_child(label("H"+str(e["week"])+"   "+str(e["text"]),19,WHITE,true))
		var amount: int=int(e["amount"])
		row.add_child(label(("+" if amount>=0 else "")+money(amount),19,TEAL if amount>=0 else RED))
		ledger.add_child(line_divider())

func _squad_value() -> int:
	var total: int=0
	for p in sim.footballers:
		if int(p["club"])==0:total+=int(p["value"])
	return total

func academy() -> void:
	var section: VBoxContainer=block("GENÇLİK AKADEMİSİ","Kendi altyapı ekolünü oluştur, potansiyeli yüksek gençleri A takıma çıkar.")
	metrics(section,["ALTYAPI TESİSİ","A TAKIM OYUNCUSU","AKADEMİ GELİŞTİRME"],
		[str(sim.academy_level)+"/5",str(sim.my_players().size()),money(1000*sim.academy_level)])
	var actions: HBoxContainer=hrow()
	section.add_child(actions)
	actions.add_child(button("TESİSLERİ GELİŞTİR",Callable(self,"_academy").bind("facility"),true))
	actions.add_child(button("GENÇ YETENEK TARAMASI 320 B€",Callable(self,"_academy").bind("promote")))
	section.add_child(label("Tesis kalitesi, yeni yetişen oyuncuların potansiyelini yükseltir. Her seçme yeni ve kurgusal bir genç futbolcu oluşturur.",19,MUTED))

func staff() -> void:
	var section: VBoxContainer=block("TEKNİK EKİP VE PERSONEL","Antrenör kalitesi gelişimi, scout ekibi araştırmaları, fizyoterapistler sakatlık iyileşmesini etkiler.")
	var fields: Array=[["ANTRENÖR KADROSU",sim.coaching_level,"coach","Antrenman kalitesi ve gelişim."],
		["OYUNCU GÖZLEM BİRİMİ",sim.scout_level,"scout","Transfer hedeflerinin değerlendirilmesi."],
		["SAĞLIK / FİZYOTERAPİ",sim.physio_level,"physio","Toparlanma ve sakatlık yönetimi."]]
	for field in fields:
		var row: HBoxContainer=hrow()
		section.add_child(row)
		var left: VBoxContainer=vcol(3)
		left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(left)
		left.add_child(label(str(field[0])+"  •  SEVİYE "+str(field[1])+"/5",23,WHITE))
		left.add_child(label(str(field[3]),17,MUTED))
		row.add_child(button("EKİBİ GÜÇLENDİR  "+money(600+int(field[1])*400),Callable(self,"_staff").bind(str(field[2])),true))
		section.add_child(line_divider())

func league() -> void:
	var section: VBoxContainer=block("LİG TABLOSU  /  "+str(sim.season)+"-"+str(sim.season+1),"12 kurgusal kulüp, çift devreli 22 hafta ve sezonlar arası ilerleme.")
	var standings: Array[Dictionary]=sim.league_table()
	var head: HBoxContainer=hrow()
	section.add_child(head)
	head.add_child(label("SIRA / KULÜP",19,GOLD,true))
	head.add_child(label("O  G  B  M  A  Y  AV  P",18,GOLD))
	for i in range(standings.size()):
		var t: Dictionary=standings[i]
		var row: HBoxContainer=hrow()
		section.add_child(row)
		row.add_child(label(str(i+1)+".  "+str(t["name"]),21,TEAL if int(t["id"])==0 else WHITE,true))
		var gd: int=int(t["gf"])-int(t["ga"])
		var tail: String="%2d   %2d   %2d   %2d   %2d   %2d   %+d   %2d" % [int(t["played"]),int(t["won"]),int(t["draw"]),int(t["lost"]),int(t["gf"]),int(t["ga"]),gd,int(t["points"])]
		row.add_child(label(tail,19,GOLD if int(t["id"])==0 else MUTED))
		section.add_child(line_divider())
	var played: VBoxContainer=block("SON HAFTANIN SONUÇLARI")
	for r in sim.week_results:
		played.add_child(label(sim.CLUB_NAMES[int(r["home"])]+"  "+str(r["gh"])+" - "+str(r["ga"])+"  "+sim.CLUB_NAMES[int(r["away"])],20,WHITE))

func inbox_screen() -> void:
	var section: VBoxContainer=block("GELEN KUTUSU / FUTBOL DÜNYASI","Transfer anlaşmaları, sakatlıklar, maçlar, yönetim kararları ve scout raporları.")
	for item in sim.inbox:
		section.add_child(label("HAFTA "+str(item["week"])+"   /   "+str(item["title"]),21,GOLD))
		section.add_child(label(str(item["body"]),18,WHITE))
		section.add_child(line_divider())

func match_center() -> void:
	if sim.current_match.is_empty():
		var empty: VBoxContainer=block("MAÇ MERKEZİ","Henüz başlayan maç yok.")
		empty.add_child(button("ANA MERKEZE DÖN",Callable(self,"nav_page").bind("MERKEZ")))
		return
	var m: Dictionary=sim.current_match
	var screen: VBoxContainer=block("CANLI MAÇ MERKEZİ","Maçı kendin oynamazsın: kararların sahadaki olayları etkiler. Devre arasında taktik güncellenebilir.")
	screen.add_child(label(sim.CLUB_NAMES[int(m["home"])]+"    "+str(m["gh"])+"  -  "+str(m["ga"])+"    "+sim.CLUB_NAMES[int(m["away"])],37,GOLD))
	metrics(screen,["DAKİKA","xG (EV / DEP)","ŞUT (EV / DEP)","TOPA SAHİP OLMA"],
		["45" if int(m["half"])==1 else "90",
			str(snappedf(float(m["xgh"]),0.01))+" / "+str(snappedf(float(m["xga"]),0.01)),
			str(m["sh"])+" / "+str(m["sa"]),str(m["posh"])+"% / "+str(100-int(m["posh"]))+"%"])
	if int(m["half"])==1:
		var buttons: HBoxContainer=hrow()
		screen.add_child(buttons)
		buttons.add_child(button("İKİNCİ YARIYI OYNAT",Callable(self,"_second_half"),true))
		buttons.add_child(button("DEVRE ARASI TAKTİĞİ",Callable(self,"nav_page").bind("TAKTİK")))
		screen.add_child(label("Devre arasındasın. Taktik sekmesinden ayar değiştirip maç merkezine dönerek ikinci yarıya geç.",18,MUTED))
	else:
		screen.add_child(button("SONUÇLARI KAYDET VE DEVAM ET",Callable(self,"_finish_match_screen"),true))
	var events: VBoxContainer=block("MAÇ AKIŞI / ÖNEMLİ POZİSYONLAR")
	var ev: Array=m["events"]
	for idx in range(ev.size()-1,-1,-1):
		events.add_child(label(str(ev[idx]),20,GOLD if str(ev[idx]).contains("GOL!") else WHITE))
		events.add_child(line_divider())

func line_divider() -> HSeparator:
	var sep: HSeparator=HSeparator.new()
	sep.add_theme_constant_override("separation",5)
	return sep
