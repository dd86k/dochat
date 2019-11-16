module dochat.text;

import std.container;
import std.container.array;
import std.format;
import dochat.users;
import api.error : APIError;
import utils.ulid;

import vibe.data.json;

/// List of text channels.
RoomManager Rooms = void;

/// Room type
enum RoomType : ubyte {
	Unknown, Public, Private
}

/**
 * Manages text channels.
 */
class RoomManager {
	private Array!TextChannel rooms;

	/// Makes a new TextChannelManager instance. Reserves 25 TextChannel
	/// structures in memory by default and initiates text channels.
	/// If no text channels are found (from the database), a default 'main'
	/// text channel is created.
	this() {
		rooms.reserve(50);
		//rooms = new TextChannel[50];

		//TODO: fetch channels from db

		// If no channels exist
		TextChannel main;
		main.id = ULID.create;
		main.name = "main";
		main.type = RoomType.Public;
		rooms.insert(main);
		//rooms[0] = main;
	}

	/**
	 * Returns a list of text channels as JSON.
	 * Params: u = UserSession that performed the request
	 * Returns: JSON formatted array of text channels
	 */
	Json listTRoomsJson(UserSession u) {
		//TODO: Return APIError instead
		//TODO: check usersession access
		
		//TODO: Check if it's possible again to convert TextChannel[] as Json
		// Only way for now to encode this array as Json
		// Trust me, I've tried *EVERYTHING*
		// Error: vibe.data.json.Json.opAssign(UUID v) is not callable
		//        using argument types (TextChannel[])
		// THEREFORE, THIS IS TEMPORARY
		string o = "[";
		size_t l = rooms.length;
		foreach (r; rooms) {
			o ~= format(
				`{"id":"%s","name":"%s"}`,
				r.id.toString, r.name
			);
			if (--l > 0) o ~= `,`;
		}
		o ~= "]";
		return o.parseJsonString;
	}

	/**
	 * Send a message to a room ID.
	 * Params:
	 *   us = UserSession
	 *   rid = Room ID
	 *   msg = Text message
	 * Returns: API Status code
	 */
	APIError sendMsg(UserSession us, ULID rid, string msg) {
		import dochat.users : Users;
		//TODO: sendMsg
		//TODO: Check usersession permissions
		const TextChannel t = getRoom(rid);
		if (t.valid) {
			return APIError.RoomID;
		}

		Json j = Json.emptyObject;
		j["res"] = "msg";

		foreach (s; Users.sessions) {
			j["from"] = us.user.uname;
			j["content"] = msg;
			s.ws.send(j.toString);
		}

		return APIError.OK;
	}

	TextChannel getRoom(ULID id) {
		foreach (r; rooms) {
			if (r.id == id) return r;
		}
		TextChannel t = void;
		t.type = RoomType.Unknown;
		return t;
	}
}

/// Text channel structure
struct TextChannel {
	ULID id;
	string name;
	RoomType type;
	
	bool valid() const {
		return type != RoomType.Unknown;
	}

	//TODO: Json toJson() const {}
	//TODO: static TextChannel fromJson(Json) {}
}

/// Message structure
struct Message {
	ulong iid;
	ULID id;
	ULID sender;
	string data;
	union {
		uint date;
		struct {
			ushort year;
			ubyte month;
			ubyte day;
		}
	}
	union {
		uint time; /// Seconds from midnight
		ubyte timems; /// Milliseconds (1/16 resolution)
	}
}