/**
 * main: Initiation, settings, router
 */

import std.stdio;
import std.getopt;
import std.file : exists, isFile;
import core.stdc.stdlib : exit;
import utils.netrand : rinit;
import dochat.all;
import config;
import backend.any;

private:

void pversion() {
	writefln(
	"dochat-server-"~PLATFORM~" v"~SERVER_VERSION~"  API:v"~API_VERSION~"  ("~__TIMESTAMP__~")\n"~
	"Built using "~__VENDOR__~" v%d ("~BUILD_TYPE~"), runtime: "~C_RUNTIME~", backend: "~BACKEND,
	__VERSION__
	);
	exit(0);
}

void plicense() {
	write( // limited to 80 characters width to ease reading
		"Copyright (c) 2019 dd86k\n\n"~
		"Redistribution and use in source and binary forms, with or without\n"~
		"modification, are permitted provided that the following conditions are met:\n"~
		"1. Redistributions of source code must retain the above copyright notice, this\n"~
		"   list of conditions and the following disclaimer.\n"~
		"2. Redistributions in binary form must reproduce the above copyright notice,\n"~
		"   this list of conditions and the following disclaimer in the documentation\n"~
		"   and/or other materials provided with the distribution.\n"~
		"3. Neither the name of the copyright holder nor the names of its contributors\n"~
		"   may be used to endorse or promote products derived from this software\n"~
		"   without specific prior written permission.\n\n"~
		"THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND\n"~
		"ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED\n"~
		"WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\n"~
		"DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE\n"~
		"FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL\n"~
		"DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR\n"~
		"SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER\n"~
		"CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\n"~
		"OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE\n"~
		"OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n"
	);
	exit(0);
}

int main(string[] args) {
	//
	// CLI
	//

	string cli_configpath = null;
	bool cli_checkonly;
	GetoptResult opt;
	try {
		opt = args.getopt(
			// settings-related options
			"check", "Check settings and exit", &cli_checkonly,
			"settings", "Set the settings path", &cli_configpath, // path
			// db options
			//"check-db", "Check the integrety of the database", &dbrepair,
			//"repair-db", "Attempt to repair the database", &dbrepair,
			// informal
			"license", "Prints license screen and exit", &plicense,
			"v|version", "Prints version screen and exit", &pversion,
		);
	} catch (GetOptException ex) {
		writeln(ex.msg);
		return 1;
	}

	if (opt.helpWanted) {
		// --help is always the last option
		opt.options[$ - 1].help = "Prints this help screen and exit";
		writeln(
			"dochat, self-hosted team chat platform\n"~
			"OPTIONS"
		);
		foreach (o; opt.options) {
			string s = o.optShort;
			string l = o.optLong;
			if (s && l) {
				writef("\t%s, %s", s, l);
			} else {
				writef("\t%s", s ? s : l);
			}
			writefln("%10s %s",
				o.required ? "(Required)" : "",
				o.help);
		}
		return 0;
	}

	//
	// Setting file handling
	//

	// If user didn't specify config path, check defauls
	if (cli_configpath == null) {
		import std.path : dirSeparator;
		version (Windows) {
		immutable string[] pathtable = [
			`config.sdl`,
			`dochat\config.sdl`
		];
		} else { // Posix
		immutable string[] pathtable = [
			`config.sdl`,
			`dochat/config.sdl`,
			`/etc/dochat/config.sdl`
		];
		}
		foreach (p; pathtable) {
			if (exists(p)) {
				cli_configpath = p;
				goto HAS_SETTINGS; // go past ENV checking
			}
		}
		//TODO: check environment variables here? e.g. dochat_SETTINGS
	}

HAS_SETTINGS:
	int e = void; /// error code
	if (cli_configpath) {
		if (exists(cli_configpath) == false) {
			logCritical("'%s' does not exist, aborted", cli_configpath);
			return 1;
		}
		if (isFile(cli_configpath) == false) {
			logCritical("'%s' is not a file, aborted", cli_configpath);
			return 1;
		}
		logInfo("Using settings file at %s", cli_configpath);
		e = settings_load(cli_configpath);
		if (e) return e;
	} else {
		logInfo("No setting files were found, assuming defaults");
		settings_default;
	}
	e = settings_verify; // prints on errors
	if (cli_checkonly || e) {
		return e;
	}

	//
	// dochat initiation
	//

	rinit; // init random lib

	//TODO: Initiate database manager
	Users = new UserManager;
	Rooms = new RoomManager;

	return runApp;
}
