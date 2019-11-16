module dochat.settings;

import backend.any;
import db.manager;
import sdlang;
import config;

enum : ubyte {
	DB_UNKNOWN, /// [0] Unknown database type
	DB_SQLITE3, /// [1] SQLite3 database type
	DB_POSTGRE, /// [2] Postgre database type
	DB_MARIADB, /// [3] MariaDB/MySQL database type
}

/// Server settings structure
struct ServerSettings_t { align(2):
	//
	// Server
	//

	/// TCP listening port
	ushort Port;

	//
	// Messages
	//

	/// Number of messages to keep in memory per TextChannels.
	/// Default: 100
	uint MessagesInMemory;
	/// Minimum milliseconds required before sending anew message.
	uint MessageMinimumTime;

	//
	// Users
	//

	/// Maximum amount of users that can registered.
	uint UsersRegistrationLimit;

	//
	// Database
	//

	/// Database type to use to store data (messages, images, etc.)
	/// See DB_* enumeration for database types
	ubyte dbtype;
}

/// Server settings
ServerSettings_t Server = void;

/**
 * Load settings into memory (ServerSettings structure).
 * Params: path = Settings file path
 */
int settings_load(string path) {
	Tag root = void;
	try {
		root = parseFile(path);
	} catch (ParseException e) {
		logError(e.msg);
		return 1;
	}

	Server.Port = cast(ushort)root.getTagValue("port", DEFAULT_PORT);

	/*Tag database = root.getTag("database");
	if (database) {
		//TODO: get db settings beforehand

		string dbtype = root.getTagValue("database.type", null);
		switch (dbtype) {
		case "sqlite3":
			//TODO: get sqlite3 settings
			db_init(DB_SQLITE3);
			break;
		default:
			logCritical("Unsupported database type: '%s'", dbtype);
			return 1;
		}
	}*/

	return 0;
}

/// Assign default values to server settings
void settings_default() {
	with (Server) {
		MessagesInMemory = 100;
		MessageMinimumTime = 1000;
		Port = DEFAULT_PORT;
	}
}

/**
 * Checks the setting files for any issues regarding server settings, database
 * connectivity, etc.
 */
int settings_verify() {


	return 0;
}