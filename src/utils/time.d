/**
 * Time utilities
 */

module utils.time;

/// Get current time as a unix timestamp in the current timezone
/// Returns: Current time in the unix timestamp format
long unixtime() @property {
	//TODO: Make our own implementation (Posix)
	import std.datetime.systime : Clock, SysTime;
	return cast(long)Clock.currTime.toUnixTime;
}