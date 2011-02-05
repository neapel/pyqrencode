#!/usr/bin/env python

import qrencode
import cairo
import math
from itertools import izip_longest

def render(c, data):
	w = len(data)


	ds = set()
	for y, row in enumerate(data):
		for x, pixel in enumerate(row):
			if pixel:
				ds.add((x,y))
				d = 0.3
			else:
				d = 0.4
			c.rectangle(x + d, y + d, 1 - 2 * d, 1 - 2 * d)
	c.set_source_rgba(0,0,0,0.2)
	c.fill()

	def px(x, y):
		#if x < 0 or x >= w: return 0
		#if y < 0 or y >= w: return 0
		#return data[y][x] #== 1
		return (x,y) in ds

	got = set()

	N, E, S, W = 1, 2, 3, 4

	border = 4
	
	for x0 in range(border, w - border):
		for y0 in range(border, w - border):
			if (x0, y0) not in got and not px(x0 - 1, y0) and px(x0, y0):
				line = []

				last = S
				cur = S
				x = x0
				y = y0

				while not line or x != x0 or y != y0:
					# Choose next direction
					if last == E:
						x += 1
						if not px(x, y - 1): cur = N
						elif not px(x, y): cur = E
						else: cur = S
					elif last == S:
						got.add((x, y))
						y += 1
						if not px(x, y): cur = E
						elif not px(x - 1, y): cur = S
						else: cur = W
					elif last == W:
						x -= 1
						if not px(x - 1, y): cur = S
						elif not px(x - 1, y - 1): cur = W
						else: cur = N
					elif last == N:
						y -= 1
						if not px(x - 1, y - 1): cur = W
						elif not px(x, y - 1): cur = N
						else: cur = E

					# Append to list
					d = (x, y, last)
					if len(line) > 0 and line[-1][2] == last:
						line[-1] = d
					else:
						line.append(d)

					last = cur

				if line:
					points = iter(line)
					c.move_to(*points.next()[:2])
					for x, y, _ in points:
						c.line_to(x, y)
						c.arc(x, y, 0.1, 0, 2 * math.pi)
						c.line_to(x, y)
					c.close_path()

	c.set_source_rgba(1,0,0,1)
	c.stroke_preserve()
	c.set_source_rgba(0,0,0,0.2)
	c.fill()

	if False:
		for x, y in got:
			y += 0.5
			c.move_to(x, y)
			c.arc(x, y, 0.2, 0, 2 * math.pi)
		c.set_source_rgb(0,0,1)
		c.fill()



if __name__ == '__main__':
	surf = cairo.PDFSurface('test.pdf', 200, 200)
	c = cairo.Context(surf)

	c.translate(10, 10)
	c.scale(4, 4)
	c.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
	c.set_line_width(0.1)

	for i in range(100):
		render(c, qrencode.encode('This is a test-string with some data.'))
