// Copyright 2020 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package aes

import (
	"math/rand"
	"testing"
	"unsafe"
)

func TestAES(t *testing.T) {
	for size := 0; size < 1024; size++ {
		a := make([]byte, size)
		for i := range a {
			a[i] = byte(rand.Intn(256))
		}
		seed := uintptr(rand.Uint64())
		g := Go(a, seed)
		c := C(a, seed)
		if g != c {
			t.Errorf("size %d: Go hash %x, C hash %x", size, g, c)
			break
		}
	}
}

func TestAesEndOfPage(t *testing.T) {
	a := make([]byte, 4096 + 16);
	p := ((uintptr(unsafe.Pointer(&a[0])) + 4096) &^ 0xfff) - uintptr(unsafe.Pointer(&a[0]))
	p -= 16
	a = a[p:p+16]
	for i := range a {
		a[i] = byte(rand.Intn(256))
	}
	for size := 0; size < 17; size++ {
		seed := uintptr(rand.Uint64())
		g := Go(a[size:], seed)
		c := C(a[size:], seed)
		if g != c {
			t.Errorf("size %d: Go hash %x, C hash %x", size, g, c)
			break
		}
	}
}
