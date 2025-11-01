extends Control
class_name NetOverlay               # 0=top-left, 1=top-right, 2=bottom-right, 3=bottom-left

@onready var _ws: Label = $PanelContainer/MarginContainer/VBoxContainer/WsLabel
@onready var _rtc: Label = $PanelContainer/MarginContainer/VBoxContainer/RtcLabel

func _ready():
	position = Vector2(16, 400)
	NetworkStatsWeb.net_stats.connect(_on_net_stats)

func _format_bytes(n: int) -> String:
	if n < 1024: return "%d B" % n
	if n < 1024 * 1024: return "%.1f KB" % (n / 1024.0)
	return "%.2f MB" % (n / 1048576.0)

func _on_net_stats(ws: Dictionary, rtc: Dictionary):
	#print("GOT")
	#print("ws ", ws)
	#print("rtc ", rtc)
	var ws_tx := int(ws.get("tx", 0))
	var ws_rx := int(ws.get("rx", 0))
	var ws_mtx := int(ws.get("msgs_tx", 0))
	var ws_mrx := int(ws.get("msgs_rx", 0))

	var rtc_tx := int(rtc.get("tx", 0))
	var rtc_rx := int(rtc.get("rx", 0))
	var rtc_mtx := int(rtc.get("msgs_tx", 0))
	var rtc_mrx := int(rtc.get("msgs_rx", 0))

	_ws.text = "WS   | out %s (%d msgs) | in %s (%d msgs)" % [
		_format_bytes(ws_tx), ws_mtx,
		_format_bytes(ws_rx), ws_mrx
	]
	_rtc.text = "RTC  | out %s (%d msgs) | in %s (%d msgs)" % [
		_format_bytes(rtc_tx), rtc_mtx,
		_format_bytes(rtc_rx), rtc_mrx,
	]
