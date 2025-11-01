#class_name NetworkStatsWeb
extends Node

signal net_stats(ws: Dictionary, rtc: Dictionary)

var _timer := Timer.new()

func _ready():
	if OS.get_name() != "Web":
		queue_free()
		return

	# inject the shim
	print("Applying JS shim...")
	var js_text: String = """(function () {
	const enc = new TextEncoder();
	const sizeOf = (d) => {
		if (typeof d === "string") return enc.encode(d).length;
		if (d instanceof ArrayBuffer) return d.byteLength;
		if (ArrayBuffer.isView(d)) return d.byteLength; // TypedArray/DataView
		// Fallback (rare): best-effort stringify
		try { return enc.encode(String(d)).length; } catch (_) { return 0; }
	};

	const st = {
		ws:  { tx: 0, rx: 0, msgs_tx: 0, msgs_rx: 0 },
		rtc: { tx: 0, rx: 0, msgs_tx: 0, msgs_rx: 0 }
	};

	// ---- WebSocket ----
	const RealWS = window.WebSocket;
	if (RealWS) {
		window.WebSocket = function (url, protocols) {
			const ws = new RealWS(url, protocols);
			const origSend = ws.send;
			ws.send = function (data) {
				++st.ws.msgs_tx;
				st.ws.tx += sizeOf(data);
				return origSend.call(ws, data);
			};
			ws.addEventListener("message", (ev) => {
				++st.ws.msgs_rx;
				st.ws.rx += sizeOf(ev.data);
			}, { capture: true });
			return ws;
		};
		window.WebSocket.prototype = RealWS.prototype;
	}

	// ---- WebRTC / DataChannel ----
	const RealPC = window.RTCPeerConnection;
	if (RealPC) {
		const patchDC = (dc) => {
			if (!dc || dc.__godot_patched) return;
			dc.__godot_patched = true;
			const origSend = dc.send.bind(dc);
			dc.send = (data) => {
				++st.rtc.msgs_tx;
				st.rtc.tx += sizeOf(data);
				return origSend(data);
			};
			dc.addEventListener("message", (ev) => {
				++st.rtc.msgs_rx;
				st.rtc.rx += sizeOf(ev.data);
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
		const stJson = JSON.stringify(st);
		st.ws  = { tx: 0, rx: 0, msgs_tx: 0, msgs_rx: 0 };
		st.rtc = { tx: 0, rx: 0, msgs_tx: 0, msgs_rx: 0 };
		return stJson;
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
		var data = JSON.parse_string(json_str)
		if typeof(data) == TYPE_DICTIONARY:
			# { tx, rx, msgs_tx, msgs_rx }
			var ws = data.get("ws", {})
			var rtc = data.get("rtc", {})
			emit_signal("net_stats", ws, rtc)
			print('data 3')
