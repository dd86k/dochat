"use strict";

var APP_VERSION = "0.0.0";

//TODO: Put token as cookie

onload = function() {
	API = new API(function () {
		User = new User();
		Rooms = new Rooms();
		Chatbox = new Chatbox();
	});
}

/**
 * Self
 */
function User() {
	
}
User.prototype = {
	token: String,
	uname: String,
	dname: String,
}

//
// Connection manager
//

/**
 * Construct a new API connection
 * @param callback Function Function to be executed when connection is open
 */
function API(callback) {
	this.url =
		(document.location.protocol == "http:" ? "ws:" : "wss:") +
		"//" + document.location.host + "/ws";
	//TODO: try to load wss:// first
	if (document.location.protocol == "http:")
		console.warn("[API] Using insecure connection (ws://)");
	this.sock = new WebSocket("ws://localhost:3311/ws");
	this.sock.beforeunload = function() {
		API.sock.close();
	}
	this.sock.onopen = function(e) {
		console.log("[API] Connected");
		callback();
	}
	this.sock.onerror = function(e) {
		console.log("[API] "+e.type);
	}
	this.sock.onmessage = function(e) {
		console.log(e.data);
		var j = JSON.parse(e.data);
		switch (j["res"]) {
		case "login":
			User.token = j["token"];
			User.uname = User.dname = j["username"];
			break;
		case "version":
			Chatbox.appendMsg({
			from: "system",
			content:
				j["svrapp"]+":"+j["svrver"]+" API:"+j["apiver"]
			});
			break;
		case "list":
			if (j["rooms"]) { // text rooms
				Rooms.cur_text = j["rooms"][0]["id"]; // temp
				Rooms.updateList(j["rooms"]);
			}
			break;
		case "msg":
			Chatbox.appendMsg({
				from: j["from"],
				content: j["content"]
			});
			break;
		case "pong": console.log("Pong!"); break;
		default: console.error("[API] Unknown response: " + j["res"]);
		}
	}
}
/**
 * Server connection manager
 */
API.prototype = {
	sock: WebSocket,
	/** URL API string */
	url: undefined,
	/**
	 * Session token
	 */
	login: function() {
		API.sock.send('{"req":"login","type":"guest"}');
	},
	version: function() {
		API.sock.send('{"req":"version"}');
	},
	sendMsg: function(msg) {
		console.log(JSON.stringify({
			req: "send",
			type: "message",
			token: User.token,
			room: Rooms.cur_text,
			content: msg
		}));
		API.sock.send(JSON.stringify({
			req: "send",
			type: "message",
			token: User.token,
			room: Rooms.cur_text,
			content: msg
		}));
	},
	list: function(type) {
		API.sock.send(JSON.stringify({
			req: "list",
			type: type,
			token: User.token
		}));
	},
	/**
	 * Send a post http request
	 * @param {String} url URL Path
	 * @param {Object} obj Dictionary object
	 * @param {Function} callback onreadystatechange
	 */
	post: function(eurl, obj, callback) {
		var x = new XMLHttpRequest();
		x.open("POST", eurl, true);
		//this.xhttp.setRequestHeader(
		//	'Content-type', 'application/x-www-form-urlencoded');
		x.setRequestHeader('Content-type', 'text/plain');
		if (obj)
		for (var k in obj) {
			x.setRequestHeader(k, obj[k]);
		}
		x.onloadend = callback;
		x.onerror = function() {
			console.error("error from " + this.caller);
		}
		x.send();
	}
}

//
// Chatbox management
//

function Chatbox() {
	this.chatnode = document.getElementById("n_chat");
	this.input = document.getElementById("n_inputbox");
	this.input.onkeydown = checkkey;
}
/**
 * Chat input and output manager
 */
Chatbox.prototype = {
	chatnode: HTMLElement,
	input: HTMLElement,
	/**
	 * Append a message into the chatnode
	 * @param {Object} 
	 */
	appendMsg: function(a) {
		var msg = document.createElement("div");
		msg.className = "message";

		var fromnode = document.createElement("div");
		fromnode.textContent = a.from;
		var msgnode = document.createElement("div");
		msgnode.textContent = a.content;

		msg.appendChild(fromnode);
		msg.appendChild(msgnode);

		this.chatnode.appendChild(msg);
	}
}

//
// Channel management
//

function Rooms() {
	this.roomlist = [];
	this.node_channels = document.getElementById("n_channels");
}
/**
 * Channel manager
 */
Rooms.prototype = {
	node_channels: HTMLElement,
	/** current text channel id (last selected) */
	cur_text: String,
	/** current voice channel id (last selected) */
	cur_voice: String,
	roomlist: Array,
	fetchRooms: function() {
		API.list("rooms");
	},
	clear: function() {
		this.rooms = [];
	},
	updateList: function(rooms) {
		console.log(rooms);
		this.clear();
		while (this.node_channels.firstChild) {
			this.node_channels.removeChild(
				this.node_channels.firstChild
			);
		}
		rooms.forEach(r => {
			this.roomlist.push(r);
			
			var button = document.createElement("div");
			button.innerText = r["name"];
			this.node_channels.appendChild(button);
		});
	}
}

//
// Misc.
//

/**
 * Prepares to send text over API or interprets command.
 */
function prepsend() {
	var text = Chatbox.input.value;
	Chatbox.input.value = null;
	switch (text) {
	case "/version":
		API.version();
		return;
	}
	API.sendMsg(text);
}

//
// Events
//

/**
 * Check a keypress, used for the input textarea
 * @param {KeyboardEvent} e Keyboard event
 */
function checkkey(e) {
	var keyc = e.which || e.keycode;
	switch (keyc) {
	case 13: // Return and Enter
		prepsend();
		return false;
	}
	return true;
}