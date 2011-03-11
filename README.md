
This fork doesn't output a PIL image, but allows accessing pixels as nested tuples, or more conveniently, draw the QR code to a cairo surface as a vector graphic. (Although it would be more space efficient as a pixel surface with nearest neighbor interpolation)

The vector generation uses a crack chain-code to generate a simpler path.


Python bindings for [libqrencode](http://fukuchi.org/works/qrencode/index.en.html) using Cython


Credit and inspiration to:

 - [http://pyqrcode.sourceforge.net/]
 (this is essentially a cleaned up version of the Encoder, eliminating all the Java dependencies)
 
 - [libqrencode](http://megaui.net/fukuchi/works/qrencode/index.en.html), by Fukuchi Kentaro

 - [PyQrCodec](http://www.pedemonte.eu/pyqr/index.py/pyqrhome), by Stefano Pedemonte


Pre-requisites on all platforms:
--------------------------------
 * you need libqrencode somewhere in your LD path (/usr/local/lib)
 * you need qrencode.h somewhere on your include path (/usr/local/include)


Installation
------------
    $ python setup.py install



Usage
-----

See test.py:

    import qrencode

    # to render a QR code including white quiet margin:
    qrencode.render(cairo_context, size_in_cairo_units, some_string)

    # to get the path with useful outlines:
    qrencode.path(cairo_context, size_in_cairo_units, some_string)
    cairo_context.stroke_preserve()
    cairo_context.fill()
