// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "go_asm.h"
#include "go_tls.h"
#include "tls_arm64.h"
#include "funcdata.h"
#include "textflag.h"

// func aeshash(p unsafe.Pointer, h, size uintptr) uintptr
TEXT runtime·aeshash(SB),NOSPLIT|NOFRAME,$0-32
	MOVD	p+0(FP), R0
	MOVD	s+16(FP), R1
	MOVD	h+8(FP), R3
	MOVD	$ret+24(FP), R2
	B	aeshashbody<>(SB)

// R0: data
// R1: length (maximum 32 bits)
// R2: address to put return value
// R3: seed data
TEXT aeshashbody<>(SB),NOSPLIT|NOFRAME,$0
	VEOR	V30.B16, V30.B16, V30.B16
	VMOV	R3, V30.D[0]
	VMOV	R1, V30.D[1] // load length into seed

	MOVD	$·aeskeysched+0(SB), R4
	VLD1.P	16(R4), [V0.B16]
	AESE	V30.B16, V0.B16
	AESMC	V0.B16, V0.B16
	CMP	$16, R1
	BLO	aes0to15
	BEQ	aes16
	CMP	$32, R1
	BLS	aes17to32
	CMP	$64, R1
	BLS	aes33to64
	CMP	$128, R1
	BLS	aes65to128
	B	aes129plus

aes0to15:
	CBZ	R1, aes0
	VEOR	V2.B16, V2.B16, V2.B16
	TBZ	$3, R1, less_than_8
	VLD1.P	8(R0), V2.D[0]

less_than_8:
	TBZ	$2, R1, less_than_4
	VLD1.P	4(R0), V2.S[2]

less_than_4:
	TBZ	$1, R1, less_than_2
	VLD1.P	2(R0), V2.H[6]

less_than_2:
	TBZ	$0, R1, done
	VLD1	(R0), V2.B[14]
done:
	AESE	V0.B16, V2.B16
	AESMC	V2.B16, V2.B16
	AESE	V0.B16, V2.B16
	AESMC	V2.B16, V2.B16
	AESE	V0.B16, V2.B16

	VST1	[V2.D1], (R2)
	RET
aes0:
	VST1	[V0.D1], (R2)
	RET
aes16:
	VLD1	(R0), [V2.B16]
	B	done

aes17to32:
	// make second seed
	VLD1	(R4), [V1.B16]
	AESE	V30.B16, V1.B16
	AESMC	V1.B16, V1.B16
	SUB	$16, R1, R10
	VLD1.P	(R0)(R10), [V2.B16]
	VLD1	(R0), [V3.B16]

	AESE	V0.B16, V2.B16
	AESMC	V2.B16, V2.B16
	AESE	V1.B16, V3.B16
	AESMC	V3.B16, V3.B16

	AESE	V0.B16, V2.B16
	AESMC	V2.B16, V2.B16
	AESE	V1.B16, V3.B16
	AESMC	V3.B16, V3.B16

	AESE	V0.B16, V2.B16
	AESE	V1.B16, V3.B16

	VEOR	V3.B16, V2.B16, V2.B16
	VST1	[V2.D1], (R2)
	RET

aes33to64:
	VLD1	(R4), [V1.B16, V2.B16, V3.B16]
	AESE	V30.B16, V1.B16
	AESMC	V1.B16, V1.B16
	AESE	V30.B16, V2.B16
	AESMC	V2.B16, V2.B16
	AESE	V30.B16, V3.B16
	AESMC	V3.B16, V3.B16
	SUB	$32, R1, R10

	VLD1.P	(R0)(R10), [V4.B16, V5.B16]
	VLD1	(R0), [V6.B16, V7.B16]

	AESE	V0.B16, V4.B16
	AESMC	V4.B16, V4.B16
	AESE	V1.B16, V5.B16
	AESMC	V5.B16, V5.B16
	AESE	V2.B16, V6.B16
	AESMC	V6.B16, V6.B16
	AESE	V3.B16, V7.B16
	AESMC	V7.B16, V7.B16

	AESE	V0.B16, V4.B16
	AESMC	V4.B16, V4.B16
	AESE	V1.B16, V5.B16
	AESMC	V5.B16, V5.B16
	AESE	V2.B16, V6.B16
	AESMC	V6.B16, V6.B16
	AESE	V3.B16, V7.B16
	AESMC	V7.B16, V7.B16

	AESE	V0.B16, V4.B16
	AESE	V1.B16, V5.B16
	AESE	V2.B16, V6.B16
	AESE	V3.B16, V7.B16

	VEOR	V6.B16, V4.B16, V4.B16
	VEOR	V7.B16, V5.B16, V5.B16
	VEOR	V5.B16, V4.B16, V4.B16

	VST1	[V4.D1], (R2)
	RET

aes65to128:
	VLD1.P	64(R4), [V1.B16, V2.B16, V3.B16, V4.B16]
	VLD1	(R4), [V5.B16, V6.B16, V7.B16]
	AESE	V30.B16, V1.B16
	AESMC	V1.B16, V1.B16
	AESE	V30.B16, V2.B16
	AESMC	V2.B16, V2.B16
	AESE	V30.B16, V3.B16
	AESMC	V3.B16, V3.B16
	AESE	V30.B16, V4.B16
	AESMC	V4.B16, V4.B16
	AESE	V30.B16, V5.B16
	AESMC	V5.B16, V5.B16
	AESE	V30.B16, V6.B16
	AESMC	V6.B16, V6.B16
	AESE	V30.B16, V7.B16
	AESMC	V7.B16, V7.B16

	SUB	$64, R1, R10
	VLD1.P	(R0)(R10), [V8.B16, V9.B16, V10.B16, V11.B16]
	VLD1	(R0), [V12.B16, V13.B16, V14.B16, V15.B16]
	AESE	V0.B16,	 V8.B16
	AESMC	V8.B16,  V8.B16
	AESE	V1.B16,	 V9.B16
	AESMC	V9.B16,  V9.B16
	AESE	V2.B16, V10.B16
	AESMC	V10.B16,  V10.B16
	AESE	V3.B16, V11.B16
	AESMC	V11.B16,  V11.B16
	AESE	V4.B16, V12.B16
	AESMC	V12.B16,  V12.B16
	AESE	V5.B16, V13.B16
	AESMC	V13.B16,  V13.B16
	AESE	V6.B16, V14.B16
	AESMC	V14.B16,  V14.B16
	AESE	V7.B16, V15.B16
	AESMC	V15.B16,  V15.B16

	AESE	V0.B16,	 V8.B16
	AESMC	V8.B16,  V8.B16
	AESE	V1.B16,	 V9.B16
	AESMC	V9.B16,  V9.B16
	AESE	V2.B16, V10.B16
	AESMC	V10.B16,  V10.B16
	AESE	V3.B16, V11.B16
	AESMC	V11.B16,  V11.B16
	AESE	V4.B16, V12.B16
	AESMC	V12.B16,  V12.B16
	AESE	V5.B16, V13.B16
	AESMC	V13.B16,  V13.B16
	AESE	V6.B16, V14.B16
	AESMC	V14.B16,  V14.B16
	AESE	V7.B16, V15.B16
	AESMC	V15.B16,  V15.B16

	AESE	V0.B16,	 V8.B16
	AESE	V1.B16,	 V9.B16
	AESE	V2.B16, V10.B16
	AESE	V3.B16, V11.B16
	AESE	V4.B16, V12.B16
	AESE	V5.B16, V13.B16
	AESE	V6.B16, V14.B16
	AESE	V7.B16, V15.B16

	VEOR	V12.B16, V8.B16, V8.B16
	VEOR	V13.B16, V9.B16, V9.B16
	VEOR	V14.B16, V10.B16, V10.B16
	VEOR	V15.B16, V11.B16, V11.B16
	VEOR	V10.B16, V8.B16, V8.B16
	VEOR	V11.B16, V9.B16, V9.B16
	VEOR	V9.B16, V8.B16, V8.B16

	VST1	[V8.D1], (R2)
	RET

aes129plus:
	PRFM (R0), PLDL1KEEP
	VLD1.P	64(R4), [V1.B16, V2.B16, V3.B16, V4.B16]
	VLD1	(R4), [V5.B16, V6.B16, V7.B16]
	AESE	V30.B16, V1.B16
	AESMC	V1.B16, V1.B16
	AESE	V30.B16, V2.B16
	AESMC	V2.B16, V2.B16
	AESE	V30.B16, V3.B16
	AESMC	V3.B16, V3.B16
	AESE	V30.B16, V4.B16
	AESMC	V4.B16, V4.B16
	AESE	V30.B16, V5.B16
	AESMC	V5.B16, V5.B16
	AESE	V30.B16, V6.B16
	AESMC	V6.B16, V6.B16
	AESE	V30.B16, V7.B16
	AESMC	V7.B16, V7.B16
	ADD	R0, R1, R10
	SUB	$128, R10, R10
	VLD1.P	64(R10), [V8.B16, V9.B16, V10.B16, V11.B16]
	VLD1	(R10), [V12.B16, V13.B16, V14.B16, V15.B16]
	SUB	$1, R1, R1
	LSR	$7, R1, R1

aesloop:
	AESE	V8.B16,	 V0.B16
	AESMC	V0.B16,  V0.B16
	AESE	V9.B16,	 V1.B16
	AESMC	V1.B16,  V1.B16
	AESE	V10.B16, V2.B16
	AESMC	V2.B16,  V2.B16
	AESE	V11.B16, V3.B16
	AESMC	V3.B16,  V3.B16
	AESE	V12.B16, V4.B16
	AESMC	V4.B16,  V4.B16
	AESE	V13.B16, V5.B16
	AESMC	V5.B16,  V5.B16
	AESE	V14.B16, V6.B16
	AESMC	V6.B16,  V6.B16
	AESE	V15.B16, V7.B16
	AESMC	V7.B16,  V7.B16

	VLD1.P	64(R0), [V8.B16, V9.B16, V10.B16, V11.B16]
	AESE	V8.B16,	 V0.B16
	AESMC	V0.B16,  V0.B16
	AESE	V9.B16,	 V1.B16
	AESMC	V1.B16,  V1.B16
	AESE	V10.B16, V2.B16
	AESMC	V2.B16,  V2.B16
	AESE	V11.B16, V3.B16
	AESMC	V3.B16,  V3.B16

	VLD1.P	64(R0), [V12.B16, V13.B16, V14.B16, V15.B16]
	AESE	V12.B16, V4.B16
	AESMC	V4.B16,  V4.B16
	AESE	V13.B16, V5.B16
	AESMC	V5.B16,  V5.B16
	AESE	V14.B16, V6.B16
	AESMC	V6.B16,  V6.B16
	AESE	V15.B16, V7.B16
	AESMC	V7.B16,  V7.B16
	SUB	$1, R1, R1
	CBNZ	R1, aesloop

	AESE	V8.B16,	 V0.B16
	AESMC	V0.B16,  V0.B16
	AESE	V9.B16,	 V1.B16
	AESMC	V1.B16,  V1.B16
	AESE	V10.B16, V2.B16
	AESMC	V2.B16,  V2.B16
	AESE	V11.B16, V3.B16
	AESMC	V3.B16,  V3.B16
	AESE	V12.B16, V4.B16
	AESMC	V4.B16,  V4.B16
	AESE	V13.B16, V5.B16
	AESMC	V5.B16,  V5.B16
	AESE	V14.B16, V6.B16
	AESMC	V6.B16,  V6.B16
	AESE	V15.B16, V7.B16
	AESMC	V7.B16,  V7.B16

	AESE	V8.B16,	 V0.B16
	AESMC	V0.B16,  V0.B16
	AESE	V9.B16,	 V1.B16
	AESMC	V1.B16,  V1.B16
	AESE	V10.B16, V2.B16
	AESMC	V2.B16,  V2.B16
	AESE	V11.B16, V3.B16
	AESMC	V3.B16,  V3.B16
	AESE	V12.B16, V4.B16
	AESMC	V4.B16,  V4.B16
	AESE	V13.B16, V5.B16
	AESMC	V5.B16,  V5.B16
	AESE	V14.B16, V6.B16
	AESMC	V6.B16,  V6.B16
	AESE	V15.B16, V7.B16
	AESMC	V7.B16,  V7.B16

	AESE	V8.B16,	 V0.B16
	AESE	V9.B16,	 V1.B16
	AESE	V10.B16, V2.B16
	AESE	V11.B16, V3.B16
	AESE	V12.B16, V4.B16
	AESE	V13.B16, V5.B16
	AESE	V14.B16, V6.B16
	AESE	V15.B16, V7.B16

	VEOR	V0.B16, V1.B16, V0.B16
	VEOR	V2.B16, V3.B16, V2.B16
	VEOR	V4.B16, V5.B16, V4.B16
	VEOR	V6.B16, V7.B16, V6.B16
	VEOR	V0.B16, V2.B16, V0.B16
	VEOR	V4.B16, V6.B16, V4.B16
	VEOR	V4.B16, V0.B16, V0.B16

	VST1	[V0.D1], (R2)
	RET

TEXT ·checkASM(SB),NOSPLIT,$0-1
	MOVW	$1, R3
	MOVB	R3, ret+0(FP)
	RET
