// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// c is a cgo interface to the code in the gofrontend repo.
// To use this you'll need to adjust CPPFLAGS to point to your copy.
package c

/*
#cgo CPPFLAGS: -I /home/iant/gofrontend3/libgo/runtime -I /home/iant/gcc/gccgo3-objdir/x86_64-pc-linux-gnu/libgo
#cgo CFLAGS: -msse2 -msse3 -mssse3 -maes

#include "aeshash.c"
*/
import "C"

import (
	"unsafe"
)

func Hash(s []byte, seed uintptr, aeskeysched []byte) uintptr {
	var p *byte
	if len(s) > 0 {
		p = &s[0]
	}
	h := C.aeshashbody(unsafe.Pointer(p), C.uintptr(seed), C.uintptr(len(s)), *(*C.Slice)(unsafe.Pointer(&aeskeysched)))
	return uintptr(h)
}
