/**
 * dochat.users: User and session management
 */

module dochat.users;

import backend.any;
import std.regex;
import std.container;
import std.container.array;
import std.format;
import config : USERSESSION_RESERVE;
import utils.ulid;
import utils.netrand : rsamplei;

/// User management
UserManager Users = void;

/// User and session manager
class UserManager {
	Array!UserSession sessions; /// User sessions in memory

	/// Compiled regex for username validation
	private auto ruser = ctRegex!(`([a-z]|_|-)\w+`);

	/// Make a new UserManager and reverse USERSESSION_RESERVE amount of
	/// sessions in memory.
	this() {
		sessions.reserve(USERSESSION_RESERVE);
	}

	/**
	 * Login as guest.
	 * Params: s = User session reference with socket copied
	 * Returns: Error code
	 */
	int login(ref UserSession s) {
		ULID utoken = void;
		do {
			utoken = ULID.create;
		} while (checkULID(utoken));

		string un = void;
		do { //TODO: use sformat
			un = format("guest%d", rsamplei);
		} while (checkGuestname(un));

		s.token = utoken;
		s.user.uname = un;
		return 0;
	}

	/**
	 * Login with a username and password.
	 * 
	 */
	int login(ref UserSession s, string username, string password) {
		return 0;
	}

	/**
	 * Register a UserSession after login.
	 */
	void registerSession(UserSession s) {
		sessions.insert(s);
	}

	/**
	 * Check if a selected ULID object exists in memory.
	 * Params: u = ULID structure to check
	 * Returns: true if exists
	 */
	bool checkULID(ULID u) {
		foreach (us; sessions) {
			if (u == us.token) return true;
		}
		return false;
	}
	UserSession fromToken(ULID u) {
		foreach (us; sessions) {
			if (u == us.token) return us;
		}
		UserSession s = void;
		s.type = 0;
		return s;
	}

	bool checkUsername(string u) {
		//TODO: checkUsername
		//Captures c = ruser.matchFirst(u);
		//return c.hit.length == u.length;
		return true;
	}
	bool checkGuestname(string u) {
		foreach (us; sessions) {
			if (u == us.user.uname) return true;
		}
		return false;
	}
}

struct UserSession {
	uint index; /// Internal index, internal id
	ULID token; /// User session ULID
	WebSocket ws; /// 
	ubyte type; /// none=0, normal=1 or guest=2
	User user;
}

struct User {
	uint id;
	/// Session index used in the session manager (internal)
	uint sindex;
	string uname; /// Username
	string dname; /// Display name

	//
	// Settings
	//
}

struct UserSettings {
	
}