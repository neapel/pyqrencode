#!/usr/bin/env python

import cairo
import qrencode
import math

if __name__ == '__main__':
	surf = cairo.PDFSurface('test.pdf', 250, 150)
	c = cairo.Context(surf)
	c.rectangle(0, 0, 250, 150)
	c.set_source_rgba(0.9,0.9,1,1)
	c.fill()

	S = 100.0

	c.save()
	c.translate(10, 10)
	c.set_line_width(0.3)

	c.rectangle(0, 0, 100, 100)
	c.stroke()

	N = 'This is a test-string with some data'

	qrencode.path(c, S, N)
	c.set_source_rgba(1,0,0,1)
	c.stroke_preserve()
	c.set_source_rgba(0,0,0,0.3)
	c.fill()
	c.restore()

	c.translate(115,10)
	qrencode.render(c, S, N)

	lines, width = qrencode.points(N)
	border = 4
	f = S / (width + 2 * border)
	c.scale(f, f)
	c.translate(border, border)
	for line in lines:
		for x, y in line:
			c.move_to(x, y)
			c.arc(x, y, 0.2, 0, 2 * math.pi)
	c.set_source_rgba(0,1,0,1)
	c.fill()

	qrencode.to_image(N).save('test-0.png')
	qrencode.to_image(N, size=480).save('test-1.png')
	qrencode.to_image(N, size=480).save('test-1-o.png', optimize=True)
	qrencode.to_image(N, size=480).save('test-1-b.png', bits=1)
	qrencode.to_image(N, scale=2).save('test-2.png')

