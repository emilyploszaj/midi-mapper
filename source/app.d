import core.sys.windows.windows;
import core.thread;
import derelict.portmidi.portmidi;
import derelict.portmidi.porttime;
import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.string;
import vibe.d;

shared static this(){
	new PortMidi();
}
///Class wrapper for thread storage hacks
class PortMidi{
	public bool[long] keyStates;
	public bool webserver;
	public WebSocket[] sockets;
	public Json json;
	this(){
		File f = File("config.json");
		json = parseJsonString(f.byLine().join().to!string);
		webserver = json["run-webserver"].get!bool;
		Thread thread = new Thread(&run);
		thread.isDaemon(true);
		thread.start();
		disableDefaultSignalHandlers();
		signal(2, &sigHandler);
		if(webserver){
			URLRouter router = new URLRouter();
			router.get("/*", &handleFileRequest);
			router.get("/ws", handleWebSockets(&handleWebSocket));
			HTTPServerSettings settings = new HTTPServerSettings();
			settings.port = json["port"].get!int.to!ushort;
			listenHTTP(settings, router);
		}
	}
	void run(){
		Chord[] chords;
		foreach(j; json["inputs"]){
			long[] midi;
			foreach(m; j["midi"]){
				midi ~= m.get!int.to!long;
			}
			chords ~= Chord(midi, Key(j["keycode"].get!int.to!ushort));
		}
		bool log = json["log-midi"].get!bool;
		int input_id = json["input-id"].get!int;
		DerelictPortMidi.load();
		DerelictPortTime.load();
		Pm_Initialize();
		PortMidiStream* stream;
		PmEvent event;
		writeln("Input status: ", Pm_OpenInput(&stream, input_id, null, 128, null, null));
		int i;
		writeln("Starting midi input loop...");
		while((i = Pm_Poll(stream)) >= 0){
			if(i == 1){
				Pm_Read(stream, &event, 1);
				PmMessage message = event.message;
				long status = Pm_MessageStatus(message);
				long data1 = Pm_MessageData1(message);
				long data2 = Pm_MessageData2(message);
				if(log) writeln(status, " ", data1, " ", data2);
				keyStates[data1] = status == 144;
				foreach(Chord c; chords){
					if(c.presses.countUntil(data1) != -1) c.check(keyStates, status == 144);
				}
				if(webserver) sendAll(cast(int) data1, status == 144);
			}else Thread.sleep(dur!"msecs"(10));
		}
		Pm_Close(&stream);
		writeln("Midi loop closed with code, ", i);
	}
	void handleFileRequest(HTTPServerRequest req, HTTPServerResponse res){
		if(req.path == "/") res.writeBody(import("index.html"), "text/html; charset=UTF-8");
		else if(req.path == "/script.js") res.writeBody(import("script.js"), "text/javascript");
	}
	void handleWebSocket(scope WebSocket socket){
		scope(exit) socket.close();
		sockets ~= socket;
		while(socket.waitForData()){
			string data = socket.receiveText();
			writeln("Web Socket: ", data);
		}
		sockets = sockets.remove(sockets.countUntil(socket));
	}
	///Sends a message to all connected websockets
	void sendAll(int key, bool state){
		try{
			foreach(socket; sockets){
				if(!socket.connected) continue;
				socket.send(Json(["key": Json(key), "state": Json(state)]).toString());
			}
		}catch(Exception e){
			writeln(e);
		}
	}
}
///C signal function
extern(C) void signal(int sig, void function(int));
///Signal handler to ensure all threads close on ^C
extern(C) void sigHandler(int sig){
	writeln("Signal 2 received, shutting down...");
	exitEventLoop(true);
}
void keyEvent(Key key, bool down){
		if(down) key.input.ki.dwFlags = 0;
		else key.input.ki.dwFlags = KEYEVENTF_KEYUP;
		SendInput(1, &key.input, key.input.sizeof);
}
struct Key{
	INPUT input;
	this(ushort keycode){
		input.type = INPUT_KEYBOARD;
		input.ki.wScan = MapVirtualKey(keycode, MAPVK_VK_TO_VSC).to!ushort;
		input.ki.time = 0;
		input.ki.dwExtraInfo = 0;
		input.ki.wVk = keycode;
	}
}
///Sometimes it's not even a chord!
struct Chord{
	long[] presses;
	Key key;
	this(long[] presses, Key key){
		this.presses = presses;
		this.key = key;
	}
	void check(bool[long] keyStates, bool press){
		foreach(long l; presses){
			if(l !in keyStates || keyStates[l] != press) return;
		}
		keyEvent(key, press);
	}
}