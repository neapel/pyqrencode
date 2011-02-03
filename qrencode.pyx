import array

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


def encode(char *text, int ec_level=ECC_MEDIUM, int version=0):
	cdef QRcode *_c_code
	cdef unsigned char *data

	# encode the text as a QR code
	str_copy = text + '\0'
	_c_code = QRcode_encodeString(str_copy, version, ec_level, QR_MODE_8, 1)
	version = _c_code.version
	width = _c_code.width
	data = _c_code.data

	# build raw image data
	rows = list()
	init = [0] * width
	for y in range(width):
		row = array.array('b', init)
		for x in range(width):
			row[x] = 1 if data[y * width + x] % 2 else 0
		rows.append(row)

	return rows
