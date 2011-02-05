import array
import math

cdef extern from "Python.h":
	int PY_MAJOR_VERSION

cdef extern from "stdlib.h":
	ctypedef unsigned long size_t
	void free(void *ptr)
	void *malloc(size_t size)

cdef extern from "string.h":
	void *memset(void *s, int c, size_t n)

cdef extern from "qrencode.h":
	int QR_ECLEVEL_L
	int QR_ECLEVEL_M
	int QR_ECLEVEL_Q
	int QR_ECLEVEL_H

	int QR_MODE_8

	ctypedef struct QRcode:
		int version
		int width
		unsigned char *data

	QRcode *QRcode_encodeString(char *string, int version, int level, int hint, int casesensitive)



ECC_LOW = QR_ECLEVEL_L
ECC_MEDIUM = QR_ECLEVEL_M
ECC_HIGH = QR_ECLEVEL_Q
ECC_HIGHEST = QR_ECLEVEL_H



cdef QRcode *encode_string(text, int ec_level, int version):
	'''
	encode the given string as QR code.
	'''

	if isinstance(text, unicode):
		text = text.encode('UTF-8')
	elif PY_MAJOR_VERSION < 3 and isinstance(text, str):
		text.decode('UTF-8')
	else:
		raise ValueError('requires text input, got %s' % type(text))

	# encode the text as a QR code
	str_copy = text + '\0'
	return QRcode_encodeString(str_copy, version, ec_level, QR_MODE_8, 1)




def encode(text, int ec_level=ECC_MEDIUM, int version=0):
	'''
	generates a QR code from the given string and returns the boolean image as a tuple of rows
	'''

	cdef QRcode *c = encode_string(text, ec_level, version)
	cdef int w = c.width
	cdef unsigned char *data = c.data

	# build tuples, add 4px border described by the standard:
	border = 4
	pad = (False,) * border
	emptyrow = (pad + (False,) * w + pad,) * border

	rows = emptyrow + tuple([
		(pad + tuple([
			bool(data[x + y * w] % 2)
			for x from 0 <= x < w
		]) + pad)
		for y from 0 <= y < w
	]) + emptyrow

	free(c)

	return rows





cdef int N = 1, E = 2, S = 3, W = 4


cdef inline int px(int x, int y, int w, unsigned char *data):
	if x < 0 or x >= w or y < 0 or y >= w: return 1
	return data[x + y * w] % 2 == 0




def encode_path(context, text, int ec_level=ECC_MEDIUM, int version=0):
	'''
	renders the QR code as a path to the given cairo context.
	Optimizes the path using Crack Code, so there are useful outlines.
	'''

	cdef QRcode *c = encode_string(text, ec_level, version)
	cdef int w = c.width
	cdef unsigned char *data = c.data

	cdef unsigned char *got = <unsigned char *> malloc(w * w)
	memset(got, 1, w * w)

	cdef int x, x0, y, y0, last, cur

	context.new_path()

	for x0 from 0 <= x0 < w:
		for y0 from 0 <= y0 < w:
			if got[x0 + y0 * w] and px(x0 - 1, y0, w, data) and not px(x0, y0, w, data):
				line = []

				last = S
				cur = S
				x = x0
				y = y0

				while not line or x != x0 or y != y0:
					# Choose next direction
					if last == E:
						x += 1
						if px(x, y - 1, w, data): cur = N
						elif px(x, y, w, data): cur = E
						else: cur = S
					elif last == S:
						got[x + y * w] = 0
						y += 1
						if px(x, y, w, data): cur = E
						elif px(x - 1, y, w, data): cur = S
						else: cur = W
					elif last == W:
						x -= 1
						if px(x - 1, y, w, data): cur = S
						elif px(x - 1, y - 1, w, data): cur = W
						else: cur = N
					elif last == N:
						y -= 1
						if px(x - 1, y - 1, w, data): cur = W
						elif px(x, y - 1, w, data): cur = N
						else: cur = E

					# Append to list
					if len(line) > 0 and line[-1][2] == last:
						line[-1] = (x, y, last)
					else:
						line.append((x, y, last))

					last = cur

				# draw group:
				if line:
					points = iter(line)
					context.move_to(*points.next()[:2])
					for x, y, _ in points:
						context.line_to(x, y)
					context.close_path()

	free(got)
	free(c)
