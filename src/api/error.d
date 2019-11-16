/**
 * Error code and message string production facility for APIs.
 */
module api.error;

import std.format;

/// API error code
/// These are identified with an number to avoid the values to change
enum APIError {
	OK              = 0, /// Nothing bad happened
	Request         = 1,
	RequestType     = 2,
	Token           = 3,
	TokenFormat     = 4,
	NoLogin         = 5,
	NoGuest         = 6,
	Password        = 7,
	RoomID          = 8,
}

/// Generator a pre-formatted JSON error string
/// Params: code = API error
/// Returns: Formatted JSON (as string)
string EString(APIError code) {
	return format(`{"res":"error","status":%d}`, code);
}