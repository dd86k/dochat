/**
 * JSON/Socket API.
 */
module api.websocket;

import std.format;
import vibe.vibe;
import config;
import dochat.all;
import api.error;
import utils.ulid;

/**
 * Handles a WebSocket connection message loop. API v0
 * Params: sock = WebSocket connection
 */
void handleWSv0(scope WebSocket sock) {
WS_START: // Shameless indentation removal
	if (sock.waitForData == false) return;
	string req = sock.receiveText(false);
	Json jreq = parseJsonString(req);
	Json jres = Json.emptyObject;
	string res = null; /// response
	switch (jreq["req"].to!string) {
	case "send": // message, image, etc.
		string tstr = jreq["token"].to!string;
		ULID uid = ULID.fromString(tstr);
		if (uid == false) {
			res = EString(APIError.TokenFormat);
			goto WS_SEND;
		}
		UserSession s = Users.fromToken(uid);
		if (s.type == 0) {
			res = EString(APIError.Token);
			goto WS_SEND;
		}
		
		//TODO: Validate user token
		
		ULID room = ULID.fromString(jreq["room"].to!string);
		string msg = jreq["content"].to!string;

		switch (jreq["type"].to!string) {
		case "message":
			APIError e = Rooms.sendMsg(s, room, msg);
			if (e) {
				res = EString(e);
				goto WS_SEND;
			}
			break;
		default:
			res = EString(APIError.RequestType);
			goto WS_SEND;
		}
		break;
	/*case "get": // content

		break;*/
	case "list": // get list of channels/etc. + last updated, good for updates
		UserSession u;
		
		jres["res"] = "list";
		
		switch (jreq["type"].to!string) {
		case "all":

			break;
		case "members": // of a room

			break;
		case "rooms": // text and voice channels
			jres["rooms"] = Rooms.listTRoomsJson(u);
			res = jres.toString;
			break;
		default:
			res = EString(APIError.RequestType);
			goto WS_SEND;
		}
		break;
	case "login": // get auth token and such
		UserSession us = void;
		us.ws = sock;
		int r = void;
		switch (jreq["type"].to!string) {
		case "guest":
			//TODO: check if guest enabled
			r = Users.login(us);
			if (r) {
				res = EString(cast(APIError)r);
				goto WS_SEND;
			}
			Users.registerSession(us);
			//jres["res"] = "login";
			//jres["username"] = us.user.uname;
			//jres["token"] = us.token.toString;
			//res = Json(jres).toString;
			res = format(
				`{"res":"login","username":"%s","token":"%s"}`,
				us.user.uname,
				us.token.toString
			);
			break;
		case "passwd":

			break;
		default:
			res = EString(APIError.RequestType);
			goto WS_SEND;
		}
		break;
	case "version":
		res = `{"res":"version","svrapp":"dochat-server","svrver":"`~
			SERVER_VERSION~`","apiver":"`~API_VERSION~`"}`;
		break;
	case "sysinfo": // get system info
		//TODO: check for operator privilege
		import core.memory : GC;
		import utils.cpuinfo : getCPUVendor, getCPUString;
		jres["cpuvendor"] = getCPUVendor;
		jres["cpumodel"] = getCPUString;
		//jres["totalmem"]
		//jres["totaldisk"]
		//jres["totalgc"] = GC.Stats.freeSize + GC.Stats.usedSize;
		//res = Json(jres).toString;
		res = jres.toString;
		break;
	case "sysusage": // get system usage
		import core.memory : GC;
		//TODO: check for operator privilege
		//Json[string] jres;
		//jres["usedcpu"] // 0-100%
		//FIXME: need "this" for usedSize of type uint
		//jres["usedgc"] = GC.Stats.usedSize;
		//jres["usedmem"]
		//jres["useddisk"]
		
		//res = Json(jres).toString;
		break;
	case "features": // list supported features
		break;
	case "ping":
		res = `{"res":"pong"}`;
		break;
	default:
		res = EString(APIError.Request);
	}
WS_SEND:
	sock.send(res);
	goto WS_START;
}