import array

cdef extern from "Python.h":
	int PY_MAJOR_VERSION

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



def encode(text, int ec_level=ECC_MEDIUM, int version=0):
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
	cdef QRcode *c = QRcode_encodeString(str_copy, version, ec_level, QR_MODE_8, 1)
	width = c.width
	cdef unsigned char *data = c.data

	# build raw image data, add 4px border described by the standard:
	border = 4
	pad = (False,) * border
	emptyrow = (pad + (False,) * width + pad,) * border

	return emptyrow + tuple([
		(pad + tuple([
			bool(data[x + y * width] % 2)
			for x from 0 <= x < width
		]) + pad)
		for y from 0 <= y < width
	]) + emptyrow


