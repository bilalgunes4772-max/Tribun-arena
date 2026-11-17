extends RefCounted
## TRIBUN ARENA DIRECTOR: fictional, offline football management simulation.
const SAVE_FILE := "user://tribun_director_01.json"
const CLUB_NAMES := ["KARTAL 1903","MARMARA ATLETİK","ANADOLU GÜCÜ","KUZEY YILDIZI","BOĞAZ CITY","BAŞKENT 06","EGE SPOR","DEMİR FK","GÜNEY BİRLİK","KAPLANLAR","KARADENİZ 61","OVA GENÇLİK"]
const CLUB_COLORS := ["#e9ecef","#ff665c","#65bfe5","#f6d176","#b784d9","#55c8a5","#f5a65c","#e77893","#7c9cea","#ffc477","#6dd6c3","#cac6ef"]
const POSITIONS := ["KL","STP","SLB","SĞB","DOS","OS","SLK","SĞK","SNT"]
const POSITION_POOL := ["KL","KL","STP","STP","STP","STP","SLB","SLB","SĞB","SĞB","DOS","DOS","DOS","OS","OS","SLK","SLK","SĞK","SĞK","SNT","SNT","SNT"]
const FIRST := ["Aras","Emir","Baran","Mert","Deniz","Bora","Ege","Kerem","Yaman","Arda","Rüzgar","Doğan","Atlas","Yiğit","Eren","Onur","Miran","Kaan","Doruk","Mahir","Ali","Ozan","Yusuf","Efe","Berk","Can","Tarık","Selim","Alper","Emre","Tuna","Demir"]
const LAST := ["Aydın","Kaya","Aksoy","Yılmaz","Şahin","Öztürk","Arslan","Kaplan","Yıldız","Karaca","Ergin","Demirtaş","Turan","Koç","Güneş","Avcı","Bozkurt","Çelik","Tekin","Uçar","Sönmez","Erdem","Taş","Keskin","Güler","Aslan"]
const FORMATIONS := ["4-2-3-1","4-3-3","4-4-2","3-4-2-1","5-3-2"]
const MENTALITIES := ["Temkinli","Dengeli","Pozitif","Hücum"]
const TRAINING := ["Taktik uyumu","Hücum organizasyonu","Savunma düzeni","Fiziksel hazırlık","Duran toplar","Takım kaynaşması"]
const ROLES := ["Savunma","Destek","Hücum"]
var rng := RandomNumberGenerator.new()
var clubs: Array[Dictionary] = []
var footballers: Array[Dictionary] = []
var fixtures: Array = []
var round_no: int = 0
var season: int = 2026
var balance: int = 18500  # all finances in 1000 EUR
var familiarity: float = 64.0
var cohesion: float = 69.0
var confidence: float = 62.0
var academy_level: int = 1
var scout_level: int = 2
var coaching_level: int = 2
var physio_level: int = 1
var mentality: int = 1
var formation_on: int = 0
var formation_off: int = 0
var pressing: int = 1
var tempo: int = 1
var width: int = 1
var intensity: int = 1
var focus: int = 0
var inbox: Array[Dictionary] = []
var week_results: Array[Dictionary] = []
var history: Array[Dictionary] = []
var pending_scout: Array[Dictionary] = []
var next_id: int = 1
var current_match: Dictionary = {}
var player_club: int = 0
var top_scorer: int = -1
var money_log: Array[Dictionary] = []

func _init() -> void:
	rng.randomize()
	if not load_game(): create_world()

func create_world() -> void:
	rng.seed = 47721903
	clubs.clear()
	footballers.clear()
	fixtures.clear()
	inbox.clear()
	money_log.clear()
	season = 2026
	round_no = 0
	balance = 18500
	next_id = 1
	for i in range(CLUB_NAMES.size()):
		clubs.append({"name":CLUB_NAMES[i],"id":i,"prestige":rng.randi_range(50,77),"budget":rng.randi_range(6000,17000),
			"played":0,"won":0,"draw":0,"lost":0,"gf":0,"ga":0,"points":0})
	for i in range(CLUB_NAMES.size()):
		for position in POSITION_POOL:
			create_player(i,position,false)
	auto_choose_xi()
	generate_fixtures()
	push_news("Yeni kariyer başladı","2026/27 sezonu başlıyor. Yönetim ilk 6 ve dengeli bir bütçe bekliyor.")
	push_news("İlk teknik ekip raporu","Kulübün hücum ve savunma dizilişlerini belirle. Antrenman uyumu sonuçları etkileyecek.")
	save_game()

func create_player(club: int, position: String, youngster: bool) -> Dictionary:
	var base: int = int(clubs[club]["prestige"])
	if youngster: base -= 15
	var age: int = rng.randi_range(17,20) if youngster else rng.randi_range(19,33)
	var skill: int = clampi(int(float(base)/5.0)+rng.randi_range(-4,3),5,19)
	var p: Dictionary = {
		"id":next_id,"club":club,"name":FIRST[rng.randi_range(0,FIRST.size()-1)]+" "+LAST[rng.randi_range(0,LAST.size()-1)],
		"pos":position,"age":age,
		"tek":clampi(skill+rng.randi_range(-3,3),3,20),
		"pas":clampi(skill+rng.randi_range(-3,3),3,20),
		"bit":clampi(skill+rng.randi_range(-3,3),3,20),
		"def":clampi(skill+rng.randi_range(-3,3),3,20),
		"fiz":clampi(skill+rng.randi_range(-3,3),3,20),
		"men":clampi(skill+rng.randi_range(-3,3),3,20),
		"kal":clampi(skill+rng.randi_range(-2,3),3,20) if position=="KL" else rng.randi_range(1,5),
		"morale":rng.randi_range(60,88),"fitness":rng.randi_range(87,100),"injury":0,
		"potential":clampi(skill+rng.randi_range(0,5)+(3 if youngster else 0),5,20),
		"contract":rng.randi_range(1,4),"wage":rng.randi_range(7,30),
		"role":1,"starter":false,"goals":0,"assists":0,"apps":0,
		"known":club==0,"scout_eta":-1,
		"foot":"Sol" if rng.randf()<0.27 else "Sağ"
	}
	p["value"]=clampi(int(float(overall(p))*float(4+int(p["potential"])) * 11.5),400,7600)
	if youngster: p["wage"]=5
	next_id+=1
	footballers.append(p)
	return p

func overall(p: Dictionary) -> int:
	var position: String = str(p["pos"])
	if position=="KL": return roundi(float(p["kal"])*0.61+float(p["men"])*0.24+float(p["fiz"])*0.15)
	if position=="STP" or position=="SLB" or position=="SĞB":
		return roundi(float(p["def"])*0.37+float(p["fiz"])*0.25+float(p["men"])*0.2+float(p["pas"])*0.18)
	if position=="DOS": return roundi(float(p["def"])*0.24+float(p["pas"])*0.33+float(p["men"])*0.3+float(p["fiz"])*0.13)
	if position=="OS": return roundi(float(p["pas"])*0.34+float(p["tek"])*0.28+float(p["men"])*0.23+float(p["fiz"])*0.15)
	if position=="SNT": return roundi(float(p["bit"])*0.46+float(p["tek"])*0.23+float(p["fiz"])*0.18+float(p["men"])*0.13)
	return roundi(float(p["tek"])*0.31+float(p["bit"])*0.23+float(p["pas"])*0.24+float(p["fiz"])*0.22)

func get_player(pid: int) -> Dictionary:
	for p in footballers:
		if int(p["id"])==pid:return p
	return {}

func my_players() -> Array[Dictionary]:
	var a: Array[Dictionary] = []
	for p in footballers:
		if int(p["club"])==0:a.append(p)
	a.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return overall(a)>overall(b))
	return a

func market_players() -> Array[Dictionary]:
	var a: Array[Dictionary]=[]
	for p in footballers:
		if int(p["club"])!=0 and int(p["age"])<32:
			a.append(p)
	a.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return overall(a)>overall(b))
	return a

func auto_choose_xi() -> void:
	var slots: Dictionary = {"KL":1,"STP":2,"SLB":1,"SĞB":1,"DOS":2,"OS":1,"SLK":1,"SĞK":1,"SNT":1}
	for p in footballers:
		if int(p["club"])==0:p["starter"]=false
	for position in slots.keys():
		var candidates: Array[Dictionary] = []
		for p in footballers:
			if int(p["club"])==0 and str(p["pos"])==str(position) and int(p["injury"])==0:
				candidates.append(p)
		candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return overall(a)>overall(b))
		for j in range(mini(int(slots[position]),candidates.size())): candidates[j]["starter"]=true

func starter_count() -> int:
	var count: int=0
	for p in footballers:
		if int(p["club"])==0 and bool(p["starter"]):count+=1
	return count

func toggle_starter(pid: int) -> String:
	var p: Dictionary=get_player(pid)
	if p.is_empty() or int(p["club"])!=0:return "Oyuncu bulunamadı"
	if int(p["injury"])>0:return "Sakat oyuncu seçilemez"
	if bool(p["starter"]):p["starter"]=false
	elif starter_count()<11:p["starter"]=true
	else:return "İlk 11 dolu. Önce bir oyuncuyu çıkar."
	save_game()
	return "Kadron güncellendi"

func change_role(pid: int) -> String:
	var p: Dictionary=get_player(pid)
	if p.is_empty() or int(p["club"])!=0:return "Oyuncu seçilemedi"
	p["role"]=(int(p["role"])+1)%3
	save_game()
	return str(p["name"])+" rolü: "+ROLES[int(p["role"])]

func generate_fixtures() -> void:
	fixtures.clear()
	var ids: Array = []
	for i in range(CLUB_NAMES.size()):ids.append(i)
	for w in range(CLUB_NAMES.size()-1):
		var games: Array = []
		for j in range(CLUB_NAMES.size()/2):
			var a: int=int(ids[j])
			var b: int=int(ids[CLUB_NAMES.size()-1-j])
			if w%2==1:games.append([b,a])
			else:games.append([a,b])
		fixtures.append(games)
		var last: Variant=ids.pop_back()
		ids.insert(1,last)
	var first_leg: Array=fixtures.duplicate(true)
	for week_pairs in first_leg:
		var return_pairs: Array=[]
		for pair in week_pairs:return_pairs.append([int(pair[1]),int(pair[0])])
		fixtures.append(return_pairs)

func next_fixture() -> Array:
	if round_no>=fixtures.size():return []
	for fixture in fixtures[round_no]:
		if int(fixture[0])==0 or int(fixture[1])==0:return fixture
	return []

func league_table() -> Array[Dictionary]:
	var board: Array[Dictionary]=clubs.duplicate(true)
	board.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if int(a["points"])!=int(b["points"]):return int(a["points"])>int(b["points"])
		var gd_a: int=int(a["gf"])-int(a["ga"])
		var gd_b: int=int(b["gf"])-int(b["ga"])
		if gd_a!=gd_b:return gd_a>gd_b
		return int(a["gf"])>int(b["gf"])
	)
	return board

func add_finance(title: String, amount: int) -> void:
	balance+=amount
	money_log.push_front({"week":round_no+1,"text":title,"amount":amount})
	if money_log.size()>35:money_log.resize(35)

func push_news(subject: String, body: String) -> void:
	inbox.push_front({"week":round_no+1,"title":subject,"body":body})
	if inbox.size()>80:inbox.resize(80)

func training_effectiveness() -> float:
	var team_ability: float = team_strength(0)
	var complexity: float = float(abs(formation_on-formation_off)*3+pressing*7+tempo*5+width*3+mentality*4)
	var penalty: float = maxf(0.0,complexity-(team_ability-45.0))*0.28
	return clampf(familiarity*0.37+cohesion*0.18+confidence*0.18+team_ability*0.27-penalty,30.0,98.0)

func team_strength(club: int) -> float:
	if club!=0:return float(clubs[club]["prestige"])
	var total: float=0
	var count: int=0
	for p in footballers:
		if int(p["club"])!=0 or not bool(p["starter"]) or int(p["injury"])>0:continue
		total+=float(overall(p))*5.0*clampf(float(p["fitness"])/100.0,0.5,1.0)
		total+=float(p["morale"])*0.08
		count+=1
	if count==0:return 26.0
	var avg: float=total/float(count)
	var organization: float=(training_effectiveness_raw()-60.0)*0.13
	return clampf(avg+organization,35.0,94.0)

func training_effectiveness_raw() -> float:
	return familiarity*0.48+cohesion*0.26+confidence*0.26

func weekly_training() -> void:
	var load: float=[1.8,3.7,6.0][intensity]
	var gain: float=0.55+float(coaching_level)*0.23
	if focus==0: familiarity=clampf(familiarity+gain*1.5,15.0,99.0)
	elif focus==5: cohesion=clampf(cohesion+gain*1.25,15.0,99.0)
	else: familiarity=clampf(familiarity+gain*0.5,15.0,99.0)
	for p in footballers:
		if int(p["club"])!=0:continue
		if int(p["injury"])>0:
			p["injury"]=maxi(0,int(p["injury"])-1)
			p["fitness"]=clampi(int(p["fitness"])+5+physio_level,20,100)
			continue
		p["fitness"]=clampi(int(p["fitness"])+17+physio_level*2-roundi(load),28,100)
		var improve: bool=rng.randf()<0.09+float(coaching_level)*0.025
		if improve and int(p["age"])<29 and overall(p)<int(p["potential"]):
			match focus:
				1:p["bit"]=mini(20,int(p["bit"])+1)
				2:p["def"]=mini(20,int(p["def"])+1)
				3:p["fiz"]=mini(20,int(p["fiz"])+1)
				4:p["pas"]=mini(20,int(p["pas"])+1)
				_:p["men"]=mini(20,int(p["men"])+1)
		if intensity==2 and rng.randf()<0.018-float(physio_level)*0.003:
			p["injury"]=rng.randi_range(1,3)
			push_news("Antrenman sakatlığı",str(p["name"])+" antrenmanda sakatlandı. Tahmini "+str(p["injury"])+" hafta yok.")
		p["morale"]=clampi(int(p["morale"])+rng.randi_range(-2,2),25,100)
	var payroll: int=0
	for p in footballers:
		if int(p["club"])==0: payroll+=int(p["wage"])
	add_finance("Haftalık maaş giderleri",-payroll-coaching_level*24-scout_level*12-physio_level*10)
	add_finance("Yayın ve sponsorluk",440+int(clubs[0]["prestige"])*5)
	if round_no%4==0:
		add_finance("Stadyum bakım / işletme",-210)
	for pending in pending_scout.duplicate():
		if round_no>=int(pending["ready"]):
			var target: Dictionary=get_player(int(pending["id"]))
			if not target.is_empty():
				target["known"]=true
				push_news("Scout raporu hazır",str(target["name"])+" hakkında tam yetenek ve piyasa raporu hazır.")
			pending_scout.erase(pending)
	# Injured starters leave the selection; replace them with fit reserves.
	var count: int=0
	for p in footballers:
		if int(p["club"])!=0:continue
		if int(p["injury"])>0 and bool(p["starter"]):p["starter"]=false
		if bool(p["starter"]):count+=1
	if count<11:
		var fresh: Array[Dictionary]=my_players()
		var has_keeper: bool=false
		for p in footballers:
			if int(p["club"])==0 and bool(p["starter"]) and str(p["pos"])=="KL":has_keeper=true
		if not has_keeper:
			for p in fresh:
				if str(p["pos"])=="KL" and int(p["injury"])==0 and not bool(p["starter"]):
					p["starter"]=true
					count+=1
					break
		for p in fresh:
			if count>=11:break
			if not bool(p["starter"]) and int(p["injury"])==0:
				p["starter"]=true
				count+=1

func scout(pid: int) -> String:
	var p: Dictionary=get_player(pid)
	if p.is_empty() or int(p["club"])==0:return "Bu oyuncu izlenemiyor."
	if bool(p["known"]):return "Oyuncunun raporu zaten açık."
	if balance<90:return "Scouting bütçesi yetersiz."
	for e in pending_scout:
		if int(e["id"])==pid:return "Scout zaten görevde."
	add_finance("Oyuncu gözlem raporu",-90)
	pending_scout.append({"id":pid,"ready":round_no+1})
	save_game()
	return "Scout gönderildi. Rapor gelecek hafta hazır."

func transfer_bid(pid: int, multiplier: float) -> String:
	var p: Dictionary=get_player(pid)
	if p.is_empty() or int(p["club"])==0:return "Oyuncu transfer listesinde değil."
	if not bool(p["known"]):return "Önce oyuncuya scout gönder."
	var fee: int=roundi(float(p["value"])*multiplier)
	if balance<fee+300:return "Bütçe yetersiz. "+str(fee)+" bin € gerekli."
	var seller: int=int(p["club"])
	var required: float=0.86+float(int(clubs[seller]["prestige"])-int(clubs[0]["prestige"]))*0.007
	if multiplier<required:
		push_news("Teklif reddedildi",str(p["name"])+" için "+str(fee)+" bin € teklif reddedildi.")
		save_game()
		return "Kulüp teklifi reddetti. Daha yüksek öner."
	if rng.randf()<0.11 and int(p["age"])<24:
		push_news("Oyuncu anlaşamadı",str(p["name"])+" maaş beklentilerinde anlaşmadı.")
		return "Oyuncuyla sözleşme anlaşması sağlanamadı."
	add_finance(str(p["name"])+" transfer bedeli",-fee)
	p["club"]=0
	p["starter"]=false
	p["contract"]=3
	p["wage"]=roundi(float(p["wage"])*1.25)+5
	p["morale"]=rng.randi_range(73,93)
	p["known"]=true
	familiarity=clampf(familiarity-1.6,10.0,99.0)
	cohesion=clampf(cohesion-1.0,10.0,99.0)
	push_news("TRANSFER TAMAMLANDI",str(p["name"])+" "+str(fee)+" bin € bedelle kadroya katıldı.")
	save_game()
	return "TRANSFER GERÇEKLEŞTİ: "+str(p["name"])

func renew(pid: int) -> String:
	var p: Dictionary=get_player(pid)
	if p.is_empty() or int(p["club"])!=0:return "Sadece kendi oyuncularınla görüşebilirsin."
	if balance<300:return "İmza primi için 300 bin € gerekiyor."
	add_finance("Sözleşme imza primi",-300)
	p["contract"]=3
	p["wage"]=roundi(float(p["wage"])*1.19)+2
	p["morale"]=mini(100,int(p["morale"])+5)
	push_news("Sözleşme yenilendi",str(p["name"])+" ile üç yıllık yeni kontrat yapıldı.")
	save_game()
	return "Sözleşme yenilendi."

func sell(pid: int) -> String:
	var p: Dictionary=get_player(pid)
	if p.is_empty() or int(p["club"])!=0:return "Bu oyuncu senin kulübünde değil."
	if starter_count()<=11 and bool(p["starter"]):return "Önce oyuncuyu ilk 11'den çıkar."
	var fee: int=roundi(float(p["value"])*rng.randf_range(0.78,1.04))
	add_finance("Oyuncu satış geliri",fee)
	p["club"]=rng.randi_range(1,CLUB_NAMES.size()-1)
	p["starter"]=false
	push_news("Oyuncu satıldı",str(p["name"])+" için "+str(fee)+" bin € gelir elde edildi.")
	save_game()
	return "Transfer tamamlandı. +"+str(fee)+" bin €."

func staff_upgrade(kind: String) -> String:
	var level: int = coaching_level if kind=="coach" else (scout_level if kind=="scout" else physio_level)
	if level>=5:return "Bu departman en üst seviyede."
	var fee: int=600+level*400
	if balance<fee:return "Bütçen yetersiz."
	add_finance("Teknik ekip yatırımı",-fee)
	match kind:
		"coach": coaching_level+=1
		"scout":scout_level+=1
		"physio":physio_level+=1
	push_news("Teknik ekip güçlendi","Departman artık seviye "+str(level+1)+".")
	save_game()
	return "Departman güncellendi."

func academy_upgrade() -> String:
	if academy_level>=5:return "Akademi en üst seviyede."
	var fee: int=1000*academy_level
	if balance<fee:return "Akademi için bütçe yetersiz."
	add_finance("Altyapı yatırımı",-fee)
	academy_level+=1
	push_news("Altyapı tesisi geliştirildi","Akademi seviye "+str(academy_level)+".")
	save_game()
	return "Yeni tesisler açıldı."

func academy_promote() -> String:
	if balance<320:return "Genç oyuncu programı için 320 bin € gerekli."
	add_finance("Genç oyuncu seçmesi",-320)
	var pick: String=POSITIONS[rng.randi_range(0,POSITIONS.size()-1)]
	var junior: Dictionary=create_player(0,pick,true)
	junior["potential"]=mini(20,int(junior["potential"])+academy_level)
	push_news("Altyapıdan yeni yetenek",str(junior["name"])+" ("+pick+"), "+str(junior["age"])+" yaş. Potansiyeli araştırılacak.")
	save_game()
	return str(junior["name"])+" A takıma yükseldi."

func record_result(home: int, away: int, gh: int, ga: int) -> void:
	var h: Dictionary=clubs[home]
	var a: Dictionary=clubs[away]
	h["played"]=int(h["played"])+1
	a["played"]=int(a["played"])+1
	h["gf"]=int(h["gf"])+gh
	h["ga"]=int(h["ga"])+ga
	a["gf"]=int(a["gf"])+ga
	a["ga"]=int(a["ga"])+gh
	if gh>ga:
		h["won"]=int(h["won"])+1
		a["lost"]=int(a["lost"])+1
		h["points"]=int(h["points"])+3
	elif ga>gh:
		a["won"]=int(a["won"])+1
		h["lost"]=int(h["lost"])+1
		a["points"]=int(a["points"])+3
	else:
		h["draw"]=int(h["draw"])+1
		a["draw"]=int(a["draw"])+1
		h["points"]=int(h["points"])+1
		a["points"]=int(a["points"])+1

func kickoff() -> String:
	if not current_match.is_empty():return "Maç devam ediyor."
	if round_no>=fixtures.size():return "Sezon bitti; yeni sezonu başlat."
	if starter_count()!=11:return "Maça çıkmak için ilk 11'de 11 oyuncu gerekli."
	var gk_count: int=0
	for p in footballers:
		if int(p["club"])==0 and bool(p["starter"]) and str(p["pos"])=="KL" and int(p["injury"])==0:gk_count+=1
	if gk_count!=1:return "İlk 11'de bir kaleci olmalı."
	var pair: Array=next_fixture()
	if pair.is_empty():return "Fikstür bulunamadı."
	current_match={"home":int(pair[0]),"away":int(pair[1]),"gh":0,"ga":0,
		"xgh":0.0,"xga":0.0,"sh":0,"sa":0,"posh":50,"events":[],"half":0}
	simulate_half(1,45)
	save_game()
	return "İlk yarı tamamlandı."

func team_power(idx: int) -> float:
	if idx!=0:return float(clubs[idx]["prestige"])
	var power: float=team_strength(0)
	power+= (training_effectiveness()-60.0)*0.22
	power+=(float(mentality)-1.0)*1.1
	if pressing==2:power+=1.3
	return power

func simulate_half(first: int, last: int) -> void:
	if current_match.is_empty():return
	var h: int=int(current_match["home"])
	var a: int=int(current_match["away"])
	var ph: float=team_power(h)+2.0
	var pa: float=team_power(a)
	for minute in range(first,last+1,3):
		for side in range(2):
			var attacker: int=h if side==0 else a
			var defender: int=a if side==0 else h
			var strength: float=ph if side==0 else pa
			var rival: float=pa if side==0 else ph
			var tempo_boost: float=0.03*float(tempo) if attacker==0 else 0.02
			var pressure: float=0.04*float(pressing) if attacker==0 else 0.04
			var opportunity: float=clampf(0.17+(strength-rival)*0.003+tempo_boost+pressure,0.06,0.4)
			if rng.randf()>opportunity:continue
			var xg: float=clampf(rng.randf_range(0.06,0.25)+(strength-rival)*0.002,0.025,0.45)
			if attacker==0:
				xg*=clampf(training_effectiveness()/70.0,0.77,1.25)
			var success: bool=rng.randf()<xg
			var key: String="gh" if side==0 else "ga"
			var xkey: String="xgh" if side==0 else "xga"
			var skey: String="sh" if side==0 else "sa"
			current_match[xkey]=float(current_match[xkey])+xg
			current_match[skey]=int(current_match[skey])+1
			var club_name: String=CLUB_NAMES[attacker]
			var text_event: String=""
			if success:
				current_match[key]=int(current_match[key])+1
				text_event=str(minute)+"'  ⚽ GOL! "+club_name
				if attacker==0:
					var possible: Array[Dictionary]=[]
					for p in footballers:
						if int(p["club"])==0 and bool(p["starter"]) and str(p["pos"])!="KL":possible.append(p)
					if not possible.is_empty():
						var scorer: Dictionary=possible[rng.randi_range(0,possible.size()-1)]
						scorer["goals"]=int(scorer["goals"])+1
						text_event+=" — "+str(scorer["name"])
			else:
				text_event=str(minute)+"'  "+club_name+" fırsatı kaçırdı ("+str(snappedf(xg,0.01))+" xG)"
			var ev: Array=current_match["events"]
			ev.append(text_event)
			current_match["events"]=ev
		if rng.randf()<0.06:
			var event_msg: String=str(minute)+"'  Orta sahada sert mücadele. Hakem oyunu durdurdu."
			var all_events: Array=current_match["events"]
			all_events.append(event_msg)
			current_match["events"]=all_events
	var poss: float=clampf(50.0+(ph-pa)*0.7,28.0,72.0)
	current_match["posh"]=roundi(poss)
	current_match["half"]=1 if last<=45 else 2

func finish_match() -> String:
	if current_match.is_empty():return "Başlayan maç yok."
	if int(current_match["half"])!=1:return "İlk yarı bitmeden maç tamamlanamaz."
	simulate_half(46,90)
	var h: int=int(current_match["home"])
	var a: int=int(current_match["away"])
	var gh: int=int(current_match["gh"])
	var ga: int=int(current_match["ga"])
	record_result(h,a,gh,ga)
	week_results.clear()
	week_results.append({"home":h,"away":a,"gh":gh,"ga":ga})
	for pair in fixtures[round_no]:
		var c1: int=int(pair[0])
		var c2: int=int(pair[1])
		if c1==h and c2==a:continue
		var diff: float=clampf((float(clubs[c1]["prestige"])-float(clubs[c2]["prestige"]))/25.0,-1.5,1.5)
		var goals1: int=mini(5,maxi(0,int(rng.randf_range(0.0,2.7)+diff)))
		var goals2: int=mini(5,maxi(0,int(rng.randf_range(0.0,2.6)-diff)))
		record_result(c1,c2,goals1,goals2)
		week_results.append({"home":c1,"away":c2,"gh":goals1,"ga":goals2})
	var ours: int=gh if h==0 else ga
	var theirs: int=ga if h==0 else gh
	if ours>theirs:
		add_finance("Maç günü gelirleri ve galibiyet primi",380)
		confidence=minf(99.0,confidence+3.4)
		cohesion=minf(99.0,cohesion+1.3)
	elif ours==theirs:
		add_finance("Maç günü gelirleri",210)
		confidence=clampf(confidence+0.2,18.0,99.0)
	else:
		add_finance("Maç günü gelirleri",135)
		confidence=maxf(24.0,confidence-2.5)
	for p in footballers:
		if int(p["club"])==0:
			if bool(p["starter"]):
				p["apps"]=int(p["apps"])+1
				p["fitness"]=maxi(25,int(p["fitness"])-rng.randi_range(8+pressing*2,16+intensity*2))
			p["morale"]=clampi(int(p["morale"])+(2 if ours>theirs else (-2 if ours<theirs else 0)),20,100)
	push_news("MAÇ SONU",CLUB_NAMES[h]+" "+str(gh)+" - "+str(ga)+" "+CLUB_NAMES[a]+". xG: "+str(snappedf(float(current_match["xgh"]),0.01))+" - "+str(snappedf(float(current_match["xga"]),0.01)))
	history.push_front({"week":round_no+1,"home":h,"away":a,"gh":gh,"ga":ga,"xgh":current_match["xgh"],"xga":current_match["xga"]})
	if history.size()>120:history.resize(120)
	round_no+=1
	weekly_training()
	save_game()
	return "Maç tamamlandı. Haftanın tüm sonuçları işlendi."

func close_match() -> void:
	current_match.clear()
	save_game()

func next_season() -> String:
	if round_no<fixtures.size():return "Sezon henüz bitmedi."
	var board: Array[Dictionary]=league_table()
	var champ: String=str(board[0]["name"])
	push_news("SEZON TAMAMLANDI","Şampiyon: "+champ+". Yeni sezon hazırlıkları başlıyor.")
	if int(board[0]["id"])==0:
		add_finance("Şampiyonluk ödülü",3800)
	else:add_finance("Sezon katılım ve sıralama",900)
	for club in clubs:
		club["played"]=0
		club["won"]=0
		club["draw"]=0
		club["lost"]=0
		club["gf"]=0
		club["ga"]=0
		club["points"]=0
	for p in footballers:
		p["age"]=int(p["age"])+1
		p["contract"]=int(p["contract"])-1
		p["fitness"]=100
		p["injury"]=0
		if int(p["contract"])<=0 and int(p["club"])==0:
			p["club"]=rng.randi_range(1,CLUB_NAMES.size()-1)
			p["starter"]=false
			push_news("Sözleşme sona erdi",str(p["name"])+" serbest kaldı.")
		if int(p["age"])>33 and rng.randf()<0.20:
			p["fiz"]=maxi(2,int(p["fiz"])-1)
	season+=1
	round_no=0
	current_match.clear()
	generate_fixtures()
	auto_choose_xi()
	familiarity=maxf(35.0,familiarity-8.0)
	push_news("YENİ SEZON",str(season)+"/"+str(season+1)+" sezonu başladı.")
	save_game()
	return "Yeni sezon başladı!"

func save_game() -> void:
	var file: FileAccess=FileAccess.open(SAVE_FILE,FileAccess.WRITE)
	if file==null:return
	var state: Dictionary={
		"clubs":clubs,"players":footballers,"fixtures":fixtures,"round":round_no,
		"season":season,"balance":balance,"familiarity":familiarity,"cohesion":cohesion,
		"confidence":confidence,"academy":academy_level,"scouts":scout_level,
		"coaches":coaching_level,"physio":physio_level,"mentality":mentality,
		"formation_on":formation_on,"formation_off":formation_off,"pressing":pressing,
		"tempo":tempo,"width":width,"intensity":intensity,"focus":focus,
		"inbox":inbox,"results":week_results,"history":history,"pending_scout":pending_scout,
		"next_id":next_id,"current_match":current_match,"money_log":money_log
	}
	file.store_string(JSON.stringify(state))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE):return false
	var f: FileAccess=FileAccess.open(SAVE_FILE,FileAccess.READ)
	if f==null:return false
	var d: Variant=JSON.parse_string(f.get_as_text())
	if not (d is Dictionary):return false
	if not d.has("clubs") or not d.has("players"):return false
	clubs.clear()
	for c in d.get("clubs",[]):
		if c is Dictionary: clubs.append(c)
	footballers.clear()
	for p in d.get("players",[]):
		if p is Dictionary:footballers.append(p)
	if clubs.size()!=CLUB_NAMES.size() or footballers.size()<150:return false
	fixtures=d.get("fixtures",[])
	round_no=int(d.get("round",0))
	season=int(d.get("season",2026))
	balance=int(d.get("balance",18500))
	familiarity=float(d.get("familiarity",64))
	cohesion=float(d.get("cohesion",69))
	confidence=float(d.get("confidence",62))
	academy_level=int(d.get("academy",1))
	scout_level=int(d.get("scouts",2))
	coaching_level=int(d.get("coaches",2))
	physio_level=int(d.get("physio",1))
	mentality=int(d.get("mentality",1))
	formation_on=int(d.get("formation_on",0))
	formation_off=int(d.get("formation_off",0))
	pressing=int(d.get("pressing",1))
	tempo=int(d.get("tempo",1))
	width=int(d.get("width",1))
	intensity=int(d.get("intensity",1))
	focus=int(d.get("focus",0))
	inbox.clear()
	for x in d.get("inbox",[]):
		if x is Dictionary:inbox.append(x)
	week_results.clear()
	for x in d.get("results",[]):
		if x is Dictionary:week_results.append(x)
	history.clear()
	for x in d.get("history",[]):
		if x is Dictionary:history.append(x)
	pending_scout.clear()
	for x in d.get("pending_scout",[]):
		if x is Dictionary:pending_scout.append(x)
	money_log.clear()
	for x in d.get("money_log",[]):
		if x is Dictionary:money_log.append(x)
	next_id=int(d.get("next_id",1000))
	current_match=d.get("current_match",{})
	if fixtures.size()==0:generate_fixtures()
	return true
