extends Control
class_name NetOverlay               # 0=top-left, 1=top-right, 2=bottom-right, 3=bottom-left

@onready var _out_l: Label = $PanelContainer/MarginContainer/VBoxContainer/OutLabel
@onready var _in_l:  Label = $PanelContainer/MarginContainer/VBoxContainer/InLabel

func _ready():
	NetworkStatsWeb.net_stats.connect(_on_net_stats)

func _format_bytes(n: int) -> String:
	if n < 1024: return "%d B" % n
	if n < 1024 * 1024: return "%.1f KB" % (n / 1024.0)
	return "%.2f MB" % (n / 1048576.0)

func _on_net_stats(rtc: Dictionary):
	var rtc_tx := int(rtc.get("tx", 0))
	var rtc_rx := int(rtc.get("rx", 0))
	var rtc_mtx := int(rtc.get("msgs_tx", 0))
	var rtc_mrx := int(rtc.get("msgs_rx", 0))
	_out_l.text = "out %s (%d msgs)" % [_format_bytes(rtc_tx), rtc_mtx]
	_in_l.text  = "in  %s (%d msgs)" % [_format_bytes(rtc_rx), rtc_mrx]
