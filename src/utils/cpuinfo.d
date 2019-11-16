module utils.cpuinfo;

version (D_InlineAsm_X86)
	version = ASM_X86;
version (D_InlineAsm_X86_64)
	version = ASM_X86;

string getCPUVendor() @trusted {
	version (ASM_X86) {
		__gshared ubyte[13] s = void;
		version (X86_64) asm @trusted {
			lea RDI, s;
			mov EAX, 0;
			cpuid;
			mov [RDI], EBX;
			mov [RDI + 4], EDX;
			mov [RDI + 8], ECX;
			mov byte ptr [RDI + 12], 0;
		}
		version (X86) asm @trusted {
			lea EDI, s;
			mov EAX, 0;
			cpuid;
			mov [EDI], EBX;
			mov [EDI + 4], EDX;
			mov [EDI + 8], ECX;
			mov byte ptr [EDI + 12], 0;
		}
		return cast(string)s;
	} else {
		return "";
	}
}

string getCPUString() @trusted {
	version (ASM_X86) {
		__gshared ubyte[49] s = void;
		version (X86_64) asm @trusted {
			lea RDI, s;
			mov EAX, 0x8000_0002;
			cpuid;
			mov [RDI], EAX;
			mov [RDI + 4], EBX;
			mov [RDI + 8], ECX;
			mov [RDI + 12], EDX;
			mov EAX, 0x8000_0003;
			cpuid;
			mov [RDI + 16], EAX;
			mov [RDI + 20], EBX;
			mov [RDI + 24], ECX;
			mov [RDI + 28], EDX;
			mov EAX, 0x8000_0004;
			cpuid;
			mov [RDI + 32], EAX;
			mov [RDI + 36], EBX;
			mov [RDI + 40], ECX;
			mov [RDI + 44], EDX;
			mov byte ptr [RDI + 48], 0;
		}
		version (X86) asm @trusted {
			lea EDI, s;
			mov EAX, 0x8000_0002;
			cpuid;
			mov [EDI], EAX;
			mov [EDI + 4], EBX;
			mov [EDI + 8], ECX;
			mov [EDI + 12], EDX;
			mov EAX, 0x8000_0003;
			cpuid;
			mov [EDI + 16], EAX;
			mov [EDI + 20], EBX;
			mov [EDI + 24], ECX;
			mov [EDI + 28], EDX;
			mov EAX, 0x8000_0004;
			cpuid;
			mov [EDI + 32], EAX;
			mov [EDI + 36], EBX;
			mov [EDI + 40], ECX;
			mov [EDI + 44], EDX;
			mov byte ptr [EDI + 48], 0;
		}
		return cast(string)s;
	} else {
		return "";
	}
}