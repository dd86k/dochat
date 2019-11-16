/*
 * db.manager: Database manager
 */

module db.manager;

import dochat.settings;
import db.sqlite3;

/**
 * Initiates DB connection/file and functions
 * Params: dbtype = Internal value of db to setup, see dochat.settings
 */
void db_init(int dbtype) {
	final switch (dbtype) {
	case DB_SQLITE3:

		break;
	}
}

/*
void function() db_add_msg;
void function() db_get_msg;
void function() db_del_msg;

void function() db_add_user;
void function() db_get_user;
void function() db_del_user;
*/