extends Control
## Dual-phase tactical pitch visualizer, original design (not copied from FM).
var formation_index: int=0
var phase: int=0 # 0 = in possession, 1 = out of possession
var title_text: String="TOP BİZDE"
const SHAPES := [
	[[0.08,0.50],[0.29,0.14],[0.29,0.38],[0.29,0.62],[0.29,0.86],[0.53,0.31],[0.53,0.69],[0.75,0.15],[0.75,0.50],[0.75,0.85],[0.93,0.50]],
	[[0.08,0.50],[0.29,0.14],[0.29,0.38],[0.29,0.62],[0.29,0.86],[0.52,0.22],[0.52,0.50],[0.52,0.78],[0.76,0.17],[0.76,0.83],[0.92,0.50]],
	[[0.08,0.50],[0.29,0.14],[0.29,0.38],[0.29,0.62],[0.29,0.86],[0.59,0.14],[0.59,0.38],[0.59,0.62],[0.59,0.86],[0.89,0.32],[0.89,0.68]],
	[[0.08,0.50],[0.29,0.25],[0.29,0.50],[0.29,0.75],[0.55,0.14],[0.55,0.37],[0.55,0.63],[0.55,0.86],[0.74,0.36],[0.74,0.64],[0.92,0.50]],
	[[0.08,0.50],[0.27,0.10],[0.27,0.29],[0.27,0.50],[0.27,0.71],[0.27,0.90],[0.56,0.25],[0.56,0.50],[0.56,0.75],[0.90,0.35],[0.90,0.65]]
]
const GOLD := Color("#efc56b")
const TEAL := Color("#4dd4bf")
const OFF := Color("#e68496")

func _ready() -> void:
	custom_minimum_size=Vector2(530,315)
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var r: Rect2=Rect2(Vector2(0,0),size)
	draw_rect(r,Color("#152c3e"))
	var inner: Rect2=Rect2(Vector2(13,54),Vector2(maxf(1,size.x-26),maxf(1,size.y-65)))
	draw_rect(inner,Color("#1b604e"))
	var cellw: float=inner.size.x/10.0
	for i in range(10):
		if i%2==0:draw_rect(Rect2(inner.position+Vector2(float(i)*cellw,0),Vector2(cellw,inner.size.y)),Color("#207058"))
	var white: Color=Color(0.82,0.94,0.89,0.85)
	draw_rect(inner,white,false,2.0)
	draw_line(Vector2(inner.position.x+inner.size.x/2,inner.position.y),Vector2(inner.position.x+inner.size.x/2,inner.end.y),white,1.6)
	draw_arc(inner.get_center(),inner.size.y*0.155,0,TAU,40,white,1.6)
	var penalty: float=inner.size.x*0.16
	var boxh: float=inner.size.y*0.47
	draw_rect(Rect2(inner.position.x,inner.get_center().y-boxh/2,penalty,boxh),white,false,1.4)
	draw_rect(Rect2(inner.end.x-penalty,inner.get_center().y-boxh/2,penalty,boxh),white,false,1.4)
	var color: Color=TEAL if phase==0 else OFF
	draw_rect(Rect2(0,0,size.x,42),Color("#203b50"))
	draw_rect(Rect2(0,0,6,42),color)
	var font: Font=ThemeDB.fallback_font
	draw_string(font,Vector2(18,29),title_text,HORIZONTAL_ALIGNMENT_LEFT,-1,22,GOLD)
	var selected: Array=SHAPES[clampi(formation_index,0,SHAPES.size()-1)]
	for n in range(11):
		var raw: Array=selected[n]
		var x: float=float(raw[0])
		var z: float=float(raw[1])
		if phase==1:x=clampf(x-0.08,0.08,0.92)
		var point: Vector2=inner.position+Vector2(x*inner.size.x,z*inner.size.y)
		draw_circle(point+Vector2(2,3),13,Color(0.03,0.10,0.15,0.7))
		draw_circle(point,12,color if n!=0 else GOLD)
		draw_arc(point,12,0,TAU,24,Color("#eff9f3"),1.5)
		var id: String=str(n+1)
		var offset: float=font.get_string_size(id,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x/2
		draw_string(font,point+Vector2(-offset,6),id,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#102633"))
