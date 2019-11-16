/**
 * Universally Unique Lexicographically sortable Identifier utility
 *
 * This code is designed to be simple, light, and fast where ULIDs are stored
 * in memory and rarely promptled for their string representations.
 *
 * Standards: https://github.com/ulid/spec
 * Authors: dd86k
 */
module utils.ulid;

import utils.time : unixtime;
import utils.netrand : rsamplei;

version (D_SIMD)
	import core.simd : ubyte16;

//TODO: Implement SIMD

/**
 * ULID structure.
 *
 * The ULID structure contains a 128-bit/16-byte array only, 6 bytes for the
 * timestamp (unix, bigendian), and 10 bytes for random data. The functions
 * provided with the structure closely follows the binary specifications,
 * except that time_low in this case is 32-bit and time_high is 16-bit. And
 * do not respect endianness (uses system's endianness).
 *
 * For more uniform random data, this structure uses the PCG Random family
 * for pseudo-random number generation provided in the netrand module, which
 * is not crypto-secure, but gets the job done, as it is more secure than
 * most others.
 *
 * For performance reasons and to ease computation and comparison of fields,
 * there are a lot of field aliases (e.g. 1x u128, 2x u64, 4x u32).
 */
struct ULID {
	// ULID[127:96] 32_bit_uint_random -+
	// ULID[96:64]  32_bit_uint_random -+-> 80-bit RANDOM
	// ULID[63:46]  16_bit_uint_random -+
	// ULID[45:32]  32_bit_uint_time_low  -+-> 48-bit TIME
	// ULID[31:0]   16_bit_uint_time_high -+
	union {
		private ubyte [16]data;
		version (D_SIMD)
			ubyte16 __vdata16; /// SIMD byte16 type
		struct { align(1):
			ulong u64_0, u64_1;
		}
		struct { align(1):
			uint u32_0, u32_1, u32_2, u32_3;
		}
		struct { align(1):
			ushort timehigh;
			uint   timelow;
			ushort random0;
			uint   random1;
			uint   random2;
		}
	}
	/// Create and initiates an ULID object
	/// Returns: ULID initiated structure
	static ULID create() {
		ULID u = void;
		u.initiate;
		return u;
	}
	/// Iniates an ULID object
	void initiate() {
		dotime;
		dorand;
	}
	/// Update timestamp data
	void dotime() {
		const ulong u = unixtime;
		timelow = cast(uint)u;
		version (D_LP64)
			timehigh = cast(ushort)(u >> 32);
	}
	/// Update random data
	void dorand() {
		random0 = cast(ushort)rsamplei;
		random1 = cast(uint)rsamplei;
		random2 = cast(uint)rsamplei;
	}
	/// Retrieves the 6-byte timestamp
	/// Returns: timestamp
	long time() @trusted {
		long t = timelow;
		version (D_LP64) {
			uint *u = cast(uint*)&t;
			u[1] = timehigh;
		}
		return t;
	}
	string toString() {
		/// BASE32 encoding table
		// eq. to static const string
		enum ENC_TABLE = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
		char [26]s = void;
		//TODO: Seek optimization
		// 10-byte timestamp
		s[0] = ENC_TABLE[(data[0] & 224) >> 5];
		s[1] = ENC_TABLE[data[0] & 31];
		s[2] = ENC_TABLE[(data[1] & 248) >> 3];
		s[3] = ENC_TABLE[((data[1] & 7) << 2) | ((data[2] & 192) >> 6)];
		s[4] = ENC_TABLE[(data[2] & 62) >> 1];
		s[5] = ENC_TABLE[((data[2] & 1) << 4) | ((data[3] & 240) >> 4)];
		s[6] = ENC_TABLE[((data[3] & 15) << 1) | ((data[4] & 128) >> 7)];
		s[7] = ENC_TABLE[(data[4] & 124) >> 2];
		s[8] = ENC_TABLE[((data[4] & 3) << 3) | ((data[5] & 224) >> 5)];
		s[9] = ENC_TABLE[data[5] & 31];
		// 16-byte random
		s[10] = ENC_TABLE[(data[6] & 248) >> 3];
		s[11] = ENC_TABLE[((data[6] & 7) << 2) | ((data[7] & 192) >> 6)];
		s[12] = ENC_TABLE[(data[7] & 62) >> 1];
		s[13] = ENC_TABLE[((data[7] & 1) << 4) | ((data[8] & 240) >> 4)];
		s[14] = ENC_TABLE[((data[8] & 15) << 1) | ((data[9] & 128) >> 7)];
		s[15] = ENC_TABLE[(data[9] & 124) >> 2];
		s[16] = ENC_TABLE[((data[9] & 3) << 3) | ((data[10] & 224) >> 5)];
		s[17] = ENC_TABLE[data[10] & 31];
		s[18] = ENC_TABLE[(data[11] & 248) >> 3];
		s[19] = ENC_TABLE[((data[11] & 7) << 2) | ((data[12] & 192) >> 6)];
		s[20] = ENC_TABLE[(data[12] & 62) >> 1];
		s[21] = ENC_TABLE[((data[12] & 1) << 4) | ((data[13] & 240) >> 4)];
		s[22] = ENC_TABLE[((data[13] & 15) << 1) | ((data[14] & 128) >> 7)];
		s[23] = ENC_TABLE[(data[14] & 124) >> 2];
		s[24] = ENC_TABLE[((data[14] & 3) << 3) | ((data[15] & 224) >> 5)];
		s[25] = ENC_TABLE[data[15] & 31];
		return s.idup;
	}
	/**
	 * Create a ULID structure from a string.
	 * This function checks if the string is at least 26 characters and
	 * if the string starts with '7' or lower. Returns an empty struct
	 * if those one of those conditions fail.
	 * Params: s = ULID string
	 * Returns: ULID structure
	 */
	static ULID fromString(string s) {
		/// BASE32 decoding table
		// eq. ubyte[256]
		__gshared ubyte [256]DEC_TABLE = [
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x01,
			0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E,
			0x0F, 0x10, 0x11, 0xFF, 0x12, 0x13, 0xFF, 0x14, 0x15, 0xFF,
			0x16, 0x17, 0x18, 0x19, 0x1A, 0xFF, 0x1B, 0x1C, 0x1D, 0x1E,
			0x1F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
			0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
		];

		ULID u = void;

		if (s.length < 26 || s[0] > '7') {
			version (D_SIMD)
				u.__vdata16 = 0;
			else version (D_LP64) {
				u.u64_0 = u.u64_1 = 0;
			} else {
				u.u32_0 = u.u32_1 = u.u32_2 = u.u32_3 = 0;
			}
			//u.data[] = 0; uses memset
			return u;
		}

		// ASCII subset of utf-8
		const ubyte *p = cast(const ubyte*)&s[0];

		// time
		u.data[0] = cast(ubyte)
			((DEC_TABLE[p[0]] << 5) | DEC_TABLE[p[1]]);
		u.data[1] = cast(ubyte)
			((DEC_TABLE[p[2]] << 3) | (DEC_TABLE[p[3]] >> 2));
		u.data[2] = cast(ubyte)
			((DEC_TABLE[p[3]] << 6) | (DEC_TABLE[p[4]] << 1) |
			(DEC_TABLE[p[5]] >> 4));
		u.data[3] = cast(ubyte)
			((DEC_TABLE[p[5]] << 4) | (DEC_TABLE[p[6]] >> 1));
		u.data[4] = cast(ubyte)
			((DEC_TABLE[p[6]] << 7) | (DEC_TABLE[p[7]] << 2) |
			(DEC_TABLE[p[8]] >> 3));
		u.data[5] = cast(ubyte)
			((DEC_TABLE[p[8]] << 5) | DEC_TABLE[p[9]]);

		// random
		u.data[6] = cast(ubyte)
			((DEC_TABLE[p[10]] << 3) | (DEC_TABLE[p[11]] >> 2));
		u.data[7] = cast(ubyte)
			((DEC_TABLE[p[11]] << 6) | (DEC_TABLE[p[12]] << 1) |
			(DEC_TABLE[p[13]] >> 4));
		u.data[8] = cast(ubyte)
			((DEC_TABLE[p[13]] << 4) | (DEC_TABLE[p[14]] >> 1));
		u.data[9] = cast(ubyte)
			((DEC_TABLE[p[14]] << 7) | (DEC_TABLE[p[15]] << 2) |
			(DEC_TABLE[p[16]] >> 3));
		u.data[10] = cast(ubyte)
			((DEC_TABLE[p[16]] << 5) | DEC_TABLE[p[17]]);
		u.data[11] = cast(ubyte)
			((DEC_TABLE[p[18]] << 3) | (DEC_TABLE[p[19]] >> 2));
		u.data[12] = cast(ubyte)
			((DEC_TABLE[p[19]] << 6) | (DEC_TABLE[p[20]] << 1) |
			(DEC_TABLE[p[21]] >> 4));
		u.data[13] = cast(ubyte)
			((DEC_TABLE[p[21]] << 4) | (DEC_TABLE[p[22]] >> 1));
		u.data[14] = cast(ubyte)
			((DEC_TABLE[p[22]] << 7) | (DEC_TABLE[p[23]] << 2) |
			(DEC_TABLE[p[24]] >> 3));
		u.data[15] = cast(ubyte)
			((DEC_TABLE[p[24]] << 5) | DEC_TABLE[p[25]]);

		return u;
	}
	
	//
	// Comparison functions
	//
	
	/**
	 * Compare ULID with another
	 * Returns: True if they have the same data
	 */
	bool opEquals(ULID a, ULID b) const {
		version (D_SIMD) {
			version (LDC)
				return a.__vdata16 == b.__vdata16;
			else
				return a.__vdata16[] == b.__vdata16[];
		} else
		version (D_LP64) {
			if (a.u64_0 != b.u64_0) return false;
			if (a.u64_1 != b.u64_1) return false;
			return true;
		} else {
			if (a.u32_0 != b.u32_0) return false;
			if (a.u32_1 != b.u32_1) return false;
			if (a.u32_2 != b.u32_2) return false;
			if (a.u32_3 != b.u32_3) return false;
			return true;
		}
	}
	bool opEquals(const ULID a) const {
		return opEquals(a, this);
	}
	bool opEquals(bool b) const {
		return check == b;
	}
	/**
	 * Compute hash.
	 */
	ulong toHash() nothrow @trusted const {
		return u32_0 ^ u32_1 ^ u32_2 ^ u32_3;
	}
	/**
	 * Casts the type as a bool value, includes implicit casts (bool only).
	 * Returns: If all random bits are set.
	 */
	bool opCast() {
		return check;
	}
	/**
	 * Verify if this ULID structure has data (non-zero).
	 * Returns: True if ULID has data
	 */
	pragma(inline, true)
	bool check() const {
		/*version (D_SIMD)
			return __vdata16 != 0;
		else*/
		version (D_LP64)
			return u64_0 && u64_1;
		else
			return u32_0 && u32_1 && u32_2 && u32_3;
	}
}

static assert(ULID.sizeof == 16);
static assert(ULID.timehigh.offsetof == 0);
static assert(ULID.timelow.offsetof == 2);
static assert(ULID.random0.offsetof == 6);
static assert(ULID.random1.offsetof == 8);
static assert(ULID.random2.offsetof == 12);

//TODO: unittesting
unittest {
	ULID u = ULID.create;
	assert(u);
	
	
}