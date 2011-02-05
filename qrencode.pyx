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




def points(text, int ec_level=ECC_MEDIUM, int version=0):
	'''
	encodes the given text as a QR code and returns a list of points
	Optimizes the path using Crack Code, so there are useful outlines.
	'''

	cdef QRcode *c = encode_string(text, ec_level, version)
	cdef int w = c.width
	cdef unsigned char *data = c.data

	cdef unsigned char *got = <unsigned char *> malloc(w * w)
	memset(got, 1, w * w)

	cdef int x, x0, y, y0, last_last, last, cur

	lines = []

	for x0 from 0 <= x0 < w:
		for y0 from 0 <= y0 < w:
			# find next start point
			if got[x0 + y0 * w] and px(x0 - 1, y0, w, data) and not px(x0, y0, w, data):
				line = []

				last_last = 0
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
					if last_last == last:
						line[-1] = (x, y)
					else:
						line.append((x, y))
						last_last = last

					last = cur

				if len(line) > 1:
					lines.append(line)

	free(got)
	free(c)

	return lines, w




def path(context, double size, text, int ec_level=ECC_MEDIUM, int version=0):
	'''
	draws the QR code as a path to the given cairo context
	'''

	if size == 0:
		raise ValueError('size must be a number other than 0')

	lines, w = points(text, ec_level, version)

	context.save()
	border = 4
	f = size / (w + 2 * border)
	context.scale(f, f)
	context.translate(border, border)
	context.new_path()

	for line in lines:
		_points = iter(line)
		context.move_to(*_points.next())
		for p in _points:
			context.line_to(*p)
		context.close_path()

	context.restore()



def render(context, double size, text, int ec_level=ECC_MEDIUM, int version=0):
	'''
	draws the QR code in black on a white background at (0,0)--(size, size)
	'''

	context.save()
	context.rectangle(0, 0, size, size)
	context.set_source_rgba(1, 1, 1, 1)
	context.fill()
	path(context, size, text, ec_level, version)
	context.set_source_rgba(0, 0, 0, 1)
	context.fill()
	context.restore()
