#class_name NetworkStatsWeb
extends Node

signal net_stats(ws: Dictionary, rtc: Dictionary)

var _timer := Timer.new()

func _ready():
	if OS.get_name() != "Web":
		queue_free()
		return

	# inject the shim
	#print("Applying JS shim...")
	var js_text: String = """(function () {
	const enc = new TextEncoder();
	const sizeOf = (d) => {
		if (typeof d === "string") return enc.encode(d).length;
		if (d instanceof ArrayBuffer) return d.byteLength;
		if (ArrayBuffer.isView(d)) return d.byteLength;
		try { return enc.encode(String(d)).length; } catch (_) { return 0; }
	};

	let rtc = { tx: 0, rx: 0, msgs_tx: 0, msgs_rx: 0 };

	// ---- WebRTC / DataChannel ----
	const RealPC = window.RTCPeerConnection;
	if (RealPC) {
		const patchDC = (dc) => {
			if (!dc || dc.__godot_patched) return;
			dc.__godot_patched = true;
			const origSend = dc.send.bind(dc);
			dc.send = (data) => {
				++rtc.msgs_tx;
				rtc.tx += sizeOf(data);
				return origSend(data);
			};
			dc.addEventListener("message", (ev) => {
				++rtc.msgs_rx;
				rtc.rx += sizeOf(ev.data);
			}, { capture: true });
		};

		window.RTCPeerConnection = function (cfg, constraints) {
			const pc = new RealPC(cfg, constraints);
			const origCreateDataChannel = pc.createDataChannel.bind(pc);
			pc.createDataChannel = (label, options) => {
				const dc = origCreateDataChannel(label, options);
				patchDC(dc);
				return dc;
			};
			pc.addEventListener("datachannel", (ev) => patchDC(ev.channel), { capture: true });
			return pc;
		};
		window.RTCPeerConnection.prototype = RealPC.prototype;
	}

	window.getNetStats = function() {
		const rtcJson = JSON.stringify(rtc);
		rtc = { tx: 0, rx: 0, msgs_tx: 0, msgs_rx: 0 };
		return rtcJson;
	}
})();"""
	JavaScriptBridge.eval(js_text)

	_timer.wait_time = 1
	_timer.autostart = true
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_poll_stats)

func _on_poll_stats():
	var json_str = JavaScriptBridge.eval("window.getNetStats()")
	if typeof(json_str) == TYPE_STRING and json_str != "":
		var rtc = JSON.parse_string(json_str)
		if typeof(rtc) == TYPE_DICTIONARY:
			# { tx, rx, msgs_tx, msgs_rx }
			emit_signal("net_stats", rtc)
