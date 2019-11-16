module backend.any;


version (Backend_vibed) {
	enum BACKEND = "vibe.d";	/// Currently used back-end
	public import backend.vibed;
} else { // Default
	version = Backend_vibed;
	enum BACKEND = "vibe.d";	/// Currently used back-end
	public import backend.vibed;
}

pragma(msg, "* backend: ", BACKEND);