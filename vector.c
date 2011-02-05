#include <cairo.h>
#include <cairo-pdf.h>
#include <stdlib.h>
#include <qrencode.h>
#include <string.h>
#include <math.h>
#include <stdio.h>


typedef struct {
	int x, y;
	char t;
} point;



void render_outline( cairo_t *ctx, char *code, int width ) {
	#define px(x, y) (\
		((x) < 0 || (x) >= width || (y) < 0 || (y) >= width ) \
			? 0 \
			: (code[(x) + (y) * width]) \
	)

	const size_t got_n = width * width;
	char got[got_n];
	memset(got, 0, got_n);

	const size_t lines_n = 500;
	point *const lines = malloc(sizeof(point) * lines_n);

	char run = 0;
	for( int x0 = 0 ; x0 < width ; x0++ ) {
		for( int y0 = 0 ; y0 < width ; y0++ ) {
			if( !px(x0 - 1, y0) && px(x0, y0) && !got[x0 + y0 * width] ) {
				int x = x0, y = y0;
				char tt = 's', t = 's';
				int i = 0;

				do {
					switch(tt) {
						case 'e':
							x++;
							if( !px(x, y - 1) ) t = 'n';
							else if( !px(x, y) ) t = 'e';
							else t = 's';
							break;
						case 's':
							if(x >= 0 && x < width && y >= 0 && y < width )
								got[x + y * width] = 1;
							y++;
							if( !px(x, y) ) t = 'e';
							else if( !px(x - 1, y) ) t = 's';
							else t = 'w';
							break;
						case 'w':
							x--;
							if( !px(x - 1, y) ) t = 's';
							else if( !px(x - 1, y - 1) ) t = 'w';
							else t = 'n';
							break;
						case 'n':
							y--;
							if( !px(x - 1, y - 1) ) t = 'w';
							else if( !px(x, y - 1) ) t = 'n';
							else t = 'e';
							break;
					}

					if( i > 0 && lines[i - 1].t == tt )
						i--;
					lines[i].x = x;
					lines[i].y = y;
					lines[i].t = tt;

					tt = t;
					i++;

				} while( i < lines_n && (x != x0 || y != y0) );

				if( i > 2 ) {
					cairo_move_to(ctx, lines[0].x, lines[0].y);
					for( int j = 1 ; j < i ; j++ )
						cairo_line_to(ctx, lines[j].x, lines[j].y);
					cairo_close_path(ctx);
				}
			}
		} // y
	} // x

	free(lines);

	cairo_set_source_rgba(ctx, 1, 0, 0, 1);
	cairo_stroke_preserve(ctx);
	cairo_set_source_rgba(ctx, 0, 0, 0, 0.2);
	cairo_fill(ctx);

	#undef px
}


// 1 rect/pixel
void render_dumb( cairo_t *ctx, char *code, int width ) {
	for( int x = 0 ; x < width ; x++ )
		for( int y = 0 ; y < width ; y++ )
			if( code[x + y * width] )
				cairo_rectangle(ctx, x + 0.1f, y + 0.1f, 0.8f, 0.8f);
}



int main(int argc, char**argv) {
	// Init cairo
	cairo_surface_t *surf = cairo_pdf_surface_create("test.pdf", 200, 200);
	cairo_t *ctx = cairo_create(surf);
	cairo_translate(ctx, 10, 10);
	cairo_scale(ctx, 5, 5);
	cairo_set_line_width(ctx, 0.1);

	// Encode
	const char *text = "This is Xa test-string with some data.";
	QRcode *code = QRcode_encodeString(text, 0, QR_ECLEVEL_M, QR_MODE_8, 1);

	for( int i = 0 ; i < code->width * code->width ; i++ )
		code->data[i] = (code->data[i] % 2 == 0) ? 0 : 1;

	// Render simple
	render_dumb(ctx, code->data, code->width);
	cairo_set_source_rgba(ctx, 0, 0, 0, 0.2f);
	cairo_fill(ctx);

	// Render optimized
	render_outline(ctx, code->data, code->width);


	// Clean
	cairo_surface_destroy(surf);
	cairo_destroy(ctx);

	return EXIT_SUCCESS;
}
