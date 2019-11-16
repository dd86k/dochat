module backend.vibed;

version (Backend_vibed):

private:

import vibe.vibe;
import dochat.all;
import api.websocket : handleWSv0;

public:

import vibe.core.log;
import vibe.http.websockets : WebSocket;

int runApp() {
	URLRouter router = new URLRouter;
	router	// GET requests
		.get("/", serveStaticFile("pub/home.html"))
		.get("/chat", serveStaticFile("pub/app.html"))
		//.get("/chat", staticTemplate!("app.dt"))
		//.get("/res", staticTemplate!"")	// db/fs media from channels
		//.get("/invite/:id", staticTemplate!"")
		.get("/*", serveStaticFiles("pub/"))	// /css /js
		//
		// v0 API
		//
		.get("/ws", handleWebSockets(&handleWSv0))
		//.get("/wss", )?
	;

	HTTPServerSettings settings = new HTTPServerSettings;
	settings.port = Server.Port;
	settings.errorPageHandler = toDelegate(&showError);

	try {
		listenHTTP(settings, router);
	} catch (Exception e) {
		logError(e.msg);
		return 2;
	}
	return runApplication;
}

void showError(HTTPServerRequest req,
	HTTPServerResponse res, HTTPServerErrorInfo error) {
	res.render!("error.dt", req, error);
}
