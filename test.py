#!/usr/bin/env python

import cairo
import qrencode

if __name__ == '__main__':
	surf = cairo.PDFSurface('test.pdf', 200, 200)
	c = cairo.Context(surf)

	c.translate(10, 10)
	c.scale(4, 4)
	c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
	c.set_line_width(0.1)

	qrencode.render(c, 'This is a test-string with some data.')
	c.set_source_rgba(1,0,0,1)
	c.stroke_preserve()
	c.set_source_rgba(0,0,0,0.3)
	c.fill()
