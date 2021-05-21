
# Fork of Trammell Hudson's laser scripts

It would appear that at the time of this writing 2021.05.21 that the bitbucket no longer exists for the `boxer.pl`, `lace-maker.pl`, and `circle-maker.pl` scripts referred by Trammel Hudson's laser cut projects pages:

- https://trmm.net/Boxer/
- https://trmm.net/Voronoi_boxes/

So this is a FORK to preserve, and extend, the work!

# Work beyond the original

- in `boxer.pl`:  output SVG units as "mm" instead of "pixels", this fixes a problem where Inkscape (96dpi) was importing .svg files from boxer.pl generated at 90dpi with the wrong "mm" units - very important for laser work to have the correct units.  (see comment in boxer.pl for details/implementation)
- new `fullbox-base.sh`: a helper to generate full boxes at once from given parameters, see projects directory for examples


# Install

Install perl modules
- sudo cpan install Math::Geometry::Voronoi
- sudo cpan install Math::Clipper

