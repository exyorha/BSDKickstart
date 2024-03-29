/*
 * Copyright 2015 Google Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * Alternatively, this software may be distributed under the terms of the
 * GNU General Public License ("GPL") version 2 as published by the Free
 * Software Foundation.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
typedef signed char int8_t;
typedef signed short int16_t;
typedef signed int int32_t;
typedef signed long long int64_t;

typedef unsigned int size_t;

#define __packed __attribute__((packed))

#define MIN(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a < _b ? _a : _b; })

#define GiB (1024 * 1024 * 1024)

void* memmove(void *dst_void, const void *src_void, size_t length) {
	char *dst = dst_void;
	const char *src = src_void;

	if (src < dst && dst < src + length)
	{
		/* Have to copy backwards */
		src += length;
		dst += length;
		while (length--)
		{
			*--dst = *--src;
		}
	}
	else
	{
		while (length--)
		{
			*dst++ = *src++;
		}
	}

	return dst_void;
}

void* memcpy(void *restrict dest, const void *restrict src, size_t count) {
	void *result = dest;

	unsigned char *restrict cdest = dest;
	const unsigned char *restrict csrc = src;

	while (count--) {
		*cdest++ = *csrc++;
	}

	return result;
}



#include "lz4.h"

/* LZ4 comes with its own supposedly portable memory access functions, but they
 * seem to be very inefficient in practice (at least on ARM64). Since libpayload
 * knows about endinaness and allows some basic assumptions (such as unaligned
 * access support), we can easily write the ones we need ourselves. */

typedef __attribute__((aligned(1))) uint16_t unaligned_uint16_t;
typedef __attribute__((aligned(1))) uint64_t unaligned_uint32_t;
typedef __attribute__((aligned(1))) uint64_t unaligned_uint64_t;

static uint16_t LZ4_readLE16(const void *src)
{
  const unaligned_uint16_t *ptr = src;

  return *ptr;
}
static void LZ4_copy8(void *dst, const void *src)
{
	*(unaligned_uint64_t *)dst = *(const unaligned_uint64_t *)src;
}

typedef  uint8_t BYTE;
typedef uint16_t U16;
typedef uint32_t U32;
typedef  int32_t S32;
typedef uint64_t U64;

#define FORCE_INLINE static inline __attribute__((always_inline))
#define likely(expr) __builtin_expect((expr) != 0, 1)
#define unlikely(expr) __builtin_expect((expr) != 0, 0)

/* Unaltered (just removed unrelated code) from github.com/Cyan4973/lz4/dev. */
#include "lz4.c.inc"	/* #include for inlining, do not link! */

#define LZ4F_MAGICNUMBER 0x184D2204

struct lz4_frame_header {
	uint32_t magic;
	union {
		uint8_t flags;
		struct {
			uint8_t reserved0		: 2;
			uint8_t has_content_checksum	: 1;
			uint8_t has_content_size	: 1;
			uint8_t has_block_checksum	: 1;
			uint8_t independent_blocks	: 1;
			uint8_t version			: 2;
		};
	};
	union {
		uint8_t block_descriptor;
		struct {
			uint8_t reserved1		: 4;
			uint8_t max_block_size		: 3;
			uint8_t reserved2		: 1;
		};
	};
	/* + uint64_t content_size iff has_content_size is set */
	/* + uint8_t header_checksum */
} __packed;

struct lz4_block_header {
	union {
		uint32_t raw;
		struct {
			uint32_t size		: 31;
			uint32_t not_compressed	: 1;
		};
	};
	/* + size bytes of data */
	/* + uint32_t block_checksum iff has_block_checksum is set */
} __packed;

size_t ulz4fn(const void *src, size_t srcn, void *dst, size_t dstn)
{
	const void *in = src;
	void *out = dst;
	size_t out_size = 0;
	int has_block_checksum;

	{ /* With in-place decompression the header may become invalid later. */
		const struct lz4_frame_header *h = in;

		if (srcn < sizeof(*h) + sizeof(uint64_t) + sizeof(uint8_t))
			return 0;	/* input overrun */

		/* We assume there's always only a single, standard frame. */
		if (h->magic != LZ4F_MAGICNUMBER || h->version != 1)
			return 0;	/* unknown format */
		if (h->reserved0 || h->reserved1 || h->reserved2)
			return 0;	/* reserved must be zero */
		if (!h->independent_blocks)
			return 0;	/* we don't support block dependency */
		has_block_checksum = h->has_block_checksum;

		in += sizeof(*h);
		if (h->has_content_size)
			in += sizeof(uint64_t);
		in += sizeof(uint8_t);
	}

	while (1) {
		struct lz4_block_header b = { .raw = *(unaligned_uint32_t *)in };
		in += sizeof(struct lz4_block_header);

		if ((size_t)(in - src) + b.size > srcn)
			break;			/* input overrun */

		if (!b.size) {
			out_size = out - dst;
			break;			/* decompression successful */
		}

		if (b.not_compressed) {
			size_t size = MIN((uint32_t)b.size, (uint32_t)(dst + dstn - out));
			memcpy(out, in, size);
			if (size < b.size)
				break;		/* output overrun */
			else
				out += size;
		} else {
			/* constant folding essential, do not touch params! */
			int ret = LZ4_decompress_generic(in, out, b.size,
					dst + dstn - out, endOnInputSize,
					full, 0, noDict, out, NULL, 0);
			if (ret < 0)
				break;		/* decompression error */
			else
				out += ret;
		}

		in += b.size;
		if (has_block_checksum)
			in += sizeof(uint32_t);
	}

	return out_size;
}

size_t ulz4f(const void *src, void *dst)
{
	/* LZ4 uses signed size parameters, so can't just use ((u32)-1) here. */
	return ulz4fn(src, 1*GiB, dst, 1*GiB);
}
