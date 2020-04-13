// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// aes exists only to verify that the AES code in gofrontend and gc
// produces the same values.
package aes

import (
	"math/rand"
	"time"

	"aes/c"
)

func checkASM() bool
func aeshash(p *byte, seed, size uintptr) uintptr

const PtrSize = 4 << (^uintptr(0) >> 63)

const hashRandomBytes = PtrSize / 4 * 64

// used in asm_{386,amd64}.s to seed the hash function
var aeskeysched [hashRandomBytes]byte

func init() {
	if !checkASM() {
		panic("checkASM failed")
	}

	rand.Seed(time.Now().Unix())
	for i := range aeskeysched {
		aeskeysched[i] = byte(rand.Intn(256))
	}
}

func Go(s []byte, seed uintptr) uintptr {
	var p *byte
	if len(s) > 0 {
		p = &s[0]
	}
	return aeshash(p, seed, uintptr(len(s)))
}

func C(s []byte, seed uintptr) uintptr {
	return c.Hash(s, seed, aeskeysched[:])
}
