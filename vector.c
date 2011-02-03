#include <cairo.h>
#include <cairo-pdf.h>
#include <stdlib.h>
#include <qrencode.h>
#include <cv.h>

void render_outline( cairo_t *ctx, char *code, int width ) {
	#define px(x,y) code[(x) + (y) * width]
	#define c1v(x,y) c1v_[(x) + (y) * width]

	int x0,  x, y, i;
	char c1v_[(width + 2) * (width + 2)];

	for( int y0 = 0 ; y0 < width ; y0++ ) {
		if( !px(y0,x0 - 1) && px(y0, x0) && !c1v(y0, x0) ) {
			int x = x0, y = y0 + 1;
			c1v(y0, x0) = 1;
			cairo_move_to(ctx, x, y);
			char last_crack = 's', next_crack = 's';
			do {
				if( last_crack != next_crack )
					cairo_line_to( ctx, x, y );
				last_crack = next_crack;

				switch(last_crack) {
					case 'e':
						if( !px(y-1,x) ) goto n;
						if( !px(y ,x) ) goto e;
						goto s;
					case 's':
						if( !px(y,x) ) goto e;
						if( !px(y, x-1) ) goto s;
						goto w;
					case 'w':
						if( !px(y, x-1) ) goto s;
						if( !px(y-1,x-1) ) goto w;
						goto n;
					case 'n':
						if( !px(y-1,x-1) ) goto w;
						if( !px(y-1,x) ) goto n;
						goto e;
				}
				e:
					next_crack = 'e';
					x++;
					continue;
				s:
					next_crack = 's';
					c1v(y,x) = 1;
					y++;
					continue;
				w:
					next_crack = 'w';
					x--;
					continue;
				n:
					next_crack = 'n';
					c1v(y,x) = 1;
					y--;
					continue;
			} while( x != x0 || y != y0 );
		}
	}
}

// 1 path
void render_outline( cairo_t *ctx, char *code, int width ) {
	const int k = (width * 2 + 2);

	CvMat *mat = cvCreateMat(k, k, CV_8UC1);
	for( int i = 0 ; i < k * k ; i++ )
		mat->data.ptr[i] = 0;
	for( int x = 1 ; x < k - 1 ; x++ )
		for( int y = 1 ; y < k - 1; y++ ) {
			const int dx = (x - 1) / 2;
			const int dy = (y - 1) / 2;
			mat->data.ptr[x + y * k] = code[dx + dy * width];
		}

	CvMemStorage *stor = cvCreateMemStorage(0);
#if 0
	CvContourScanner sc = cvStartFindContours(mat, stor, sizeof(CvContour), CV_RETR_LIST, CV_CHAIN_APPROX_NONE, cvPoint(0,0));

	CvSeq *cont;
	while( cont = cvFindNextContour(sc) ) {
		CvPoint p;
		for( int i = 0 ; cont->total != 0 ; i++ ) {
			cvSeqPopFront(cont, &p);
			if( i == 0 ) cairo_move_to(ctx, p.x, p.y);
			else cairo_line_to(ctx, p.x, p.y);
		}
	}
#else
	CvSeq *cont;
	cvFindContours(mat, stor, &cont, sizeof(CvContour), CV_RETR_LIST, CV_CHAIN_APPROX_NONE, cvPoint(0,0));

	do {
		CvPoint p;
		for( int i = 0 ; cont->total != 0 ; i++ ) {
			cvSeqPopFront(cont, &p);
			const float x = (p.x - 1) * 0.5;
			const float y = (p.y - 1) * 0.5;
			if( i == 0 ) cairo_move_to(ctx, x, y);
			else cairo_line_to(ctx, x , y);
		}
	} while( cont = cont->h_next );
#endif
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

	// Encode
	const char *text = "This is a test-string with some data.";
	QRcode *code = QRcode_encodeString(text, 0, QR_ECLEVEL_M, QR_MODE_8, 1);

	for( int i = 0 ; i < code->width * code->width ; i++ )
		code->data[i] %= 2;

	// Render simple
	render_dumb(ctx, code->data, code->width);
	cairo_set_source_rgba(ctx, 0, 0, 0, 0.5f);
	cairo_fill(ctx);

	// Render optimized
	render_outline(ctx, code->data, code->width);
	cairo_set_source_rgba(ctx, 1, 0, 0, 1);
	cairo_set_line_width(ctx, 0.1f);
	cairo_stroke(ctx);

	// Clean
	cairo_surface_destroy(surf);
	cairo_destroy(ctx);

	return EXIT_SUCCESS;
}
