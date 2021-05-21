#!/usr/bin/env perl
# Generate SVG files with a specified number of sides and tabs
# to make a self-locking acrylic or wooden laser cut box.
#
# (c) 2012 Trammell Hudson <hudson@osresearch.net>
#
# 5mm bamboo needs a larger kerf -- 0.2?  power 100, speed 4
# 3mm acrylic works well with 6mm fingers, power 100 speed 10
# 6mm acrylic kerf = 0.1 is ok, 0.2 shatters, power 100 speed 4
# Be sure to measure the acrylic -- some of them vary.
#
use warnings;
use strict;
use Math::Trig;
use Getopt::Long qw(:config no_ignore_case);
sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }

my $units = "mm"; # mm = 1, inches = 1000 / 25.4
my $thickness = 3;
my $sides = 4;
my $length = 50;
my $width = 30;
my $height = 20;
my $tab_width = 6;
my $kerf = 0.1;
my $spacing;
my $viewbox_w = 200;
my $viewbox_h = 200;

my $usage = <<"";
Usage: boxer [options] > box.svg
Options:
	-h | -? | --help	This help
	-T | --tab-width N	Tab width in mm
	-t | --thickness N	Material thickness in mm
	-H | --height N		Height of the box, in mm
	-w | --width N		Outside edge length, in mm
	-l | --length N		Outside edge length, in mm for rectangles
	-k | --kerf N		Kerf in mm (typically 0.1)
	-s | --spacing N	Spacing between pieces in mm


GetOptions(
	'h|?|help'		=> sub { print $usage; exit 0 },
	't|thickness=f'		=> \$thickness,
	'H|height=f'		=> \$height,
	'w|width=f'		=> \$width,
	'l|length=f'		=> \$length,
	'k|kerf=f'		=> \$kerf,
	'T|tab-width=f'		=> \$tab_width,
	's|spacing=f'		=> \$spacing,
) or die $usage;

die "tab should be wider than the material thickness\n"
	if $thickness > $tab_width;

my $num_x_tabs = int(($width - $thickness*2) / ($tab_width * 2));
my $num_y_tabs = int(($length - $thickness*2) / ($tab_width * 2));
my $num_z_tabs = int(($height - $thickness*2) / ($tab_width * 2));
die "tab width $tab_width too large for width $width\n"
	if $num_x_tabs == 0;
die "tab width $tab_width too large for length $length\n"
	if $num_y_tabs == 0;
die "tab width $tab_width too large for height $height\n"
	if $num_z_tabs == 0;

$spacing ||= $kerf * 10;

$viewbox_w = max( $width + $kerf*2 + $spacing + $width, $length + $kerf*2 + $spacing + $length );
$viewbox_h = $length + $kerf*2 + $spacing + $height + $kerf*2 + $spacing + $height;

# Compute the height of the interior triangle
#my $interior_angle = 360.0 / $sides;
#my $interior_len = $edge - $thickness * 2;
#my $interior_radius = ($interior_len/2) / tan(deg2rad($interior_angle/2));

# KEVIN
# boxer.pl original script scaled output SVG to pixels, using an assumed DPI of 90dpi
# we could scale to pixels, but if so, we'd have to choose DPI to match target of the app (Illustrator, CorelDraw, Inkscape, etc...)
# that poses a problem for portability, and causes scaling errors on import when the app DPI doesn't match the DPI assumed here.
#
# doing the math for converting mm to SVG pixels at different DPIs:
#  boxer.pl originally scaled mm to SVG pixels using 3.543307    (<g transform="scale(3.543307)"><!-- scale to mm -->)
#  in to mm:  25.4
#  mm to in:  0.0393701
#  90dpi to dpmm: 90 * 0.0393701 = 3.543309        (looks familiar?)
#  96dpi to dpmm: 96 * 0.0393701 = 3.7795296
#  the ratio between these is 0.9375 (or 1.06667)
#
# Instead:
#   embed "mm" as the units in the .svg file (works with Inkscape, possibly others?)
#   avoid portability problems converting to pixels because of different DPI settings in Inkscape vs CorelDraw vs Illustrator, etc...
print <<"";
<!-- Created with boxer (http://trmm.net/) -->
<svg xmlns="http://www.w3.org/2000/svg" width="${viewbox_w}mm" height="${viewbox_h}mm" version="1.1" viewBox="0 0 ${viewbox_w} ${viewbox_h}">
<g transform="scale(1)"><!-- no scale...  we use actual mm units in the <svg> header -->

# original boxer.pl - scale mm to SVG pixels
#$dpi_scale=3.543307   # for 90dpi
##$dpi_scale=3.7795296  # for 96dpi
#print <<"";
#<!-- Created with boxer (http://trmm.net/) -->
#<svg xmlns="http://www.w3.org/2000/svg">
#<g transform="scale($dpi_scale)"><!-- scale mm to pixels @ 90dpi -->


sub make_translate
{
	my ($x,$y) = @_;
	return "translate($x,$y)";
}


sub make_path
{
	my $rc = <<"";
	<path
		stroke		= "#ff0000"
		fill		= "none"
		stroke-width	= "0.1px"
		d		= "M

	for my $pt (@_)
	{
		my ($x,$y) = @$pt;
		$rc .= "$x,$y\n";
	}

	$rc .= <<"";
	"/>

	return $rc;
}


#
# Applies a transform to a list of SVG objects (paths or other groups)
# Returns a SVG group
#
sub make_group
{
	my $transform = shift;

	my $rc = <<"";
	<g
		transform	= "$transform"
	>

	$rc .= join '\n', @_;
	$rc .= <<"";
	</g>

	return $rc;
}


#
# Generate the flat top and bottom pieces.
# Returns a SVG path
#
sub make_top
{
	my $rc;

	my @points;

	# Bottom edge
	push @points, [$thickness, $thickness];
	my $x = $width/2 - $tab_width * ($num_x_tabs - 0.5);
	for my $n (1..$num_x_tabs)
	{
		push @points,
			[$x - $kerf, $thickness],
			[$x - $kerf, 0],
			[$x + $tab_width + $kerf, 0],
			[$x + $tab_width + $kerf, $thickness],
			;
		$x += $tab_width * 2;
	}

	# Right edge
	push @points, [$width - $thickness, $thickness];
	my $y = $length/2 - $tab_width * ($num_y_tabs - 0.5);
	for my $n (1..$num_y_tabs)
	{
		push @points,
			[$width - $thickness, $y - $kerf],
			[$width, $y - $kerf],
			[$width, $y + $tab_width + $kerf],
			[$width - $thickness, $y + $tab_width + $kerf],
			;
		$y += $tab_width * 2;
	}

	# Top edge
	push @points, [$width - $thickness, $length - $thickness];
	$x = $width/2 + $tab_width * ($num_x_tabs - 0.5);
	for my $n (1..$num_x_tabs)
	{
		push @points,
			[$x + $kerf, $length - $thickness],
			[$x + $kerf, $length],
			[$x - $tab_width - $kerf, $length],
			[$x - $tab_width - $kerf, $length - $thickness],
			;
		$x -= $tab_width * 2;
	}

	# Left edge
	push @points, [$thickness, $length - $thickness];
	$y = $length/2 + $tab_width * ($num_y_tabs - 0.5);
	for my $n (1..$num_y_tabs)
	{
		push @points,
			[$thickness, $y + $kerf],
			[0, $y + $kerf],
			[0, $y - $tab_width - $kerf],
			[$thickness, $y - $tab_width - $kerf],
			;
		$y -= $tab_width * 2;
	}

	# Close the path
	push @points, [$thickness, $thickness];

	return make_path(@points);
}


sub make_side
{
	my ($x_dim, $num_x_tabs, $inset) = @_;
	my @points;

	# Bottom edge
	if ($inset)
	{
		push @points, [$thickness, 0];
	} else {
		push @points, [0,0];
	}

	my $x = $x_dim / 2 - $tab_width * ($num_x_tabs - 0.5);
	for my $n (1..$num_x_tabs)
	{
		push @points,
			[$x - $kerf, 0],
			[$x + $kerf, $thickness],
			[$x - $kerf + $tab_width, $thickness],
			[$x + $kerf + $tab_width, 0],
			;
		$x += $tab_width * 2;
	}

	# Height edge
	if ($inset)
	{
		push @points, [$x_dim - $thickness, 0];
	} else {
		push @points, [$x_dim, 0];
	}

	my $z = $height/2 - $tab_width * ($num_z_tabs - 0.5);
	for my $n (1..$num_z_tabs)
	{
		if ($inset)
		{
			push @points,
				[$x_dim - $thickness, $z - $kerf],
				[$x_dim, $z + $kerf],
				[$x_dim, $z + $tab_width - $kerf],
				[$x_dim - $thickness, $z + $tab_width + $kerf],
				;
		} else {
			push @points,
				[$x_dim, $z - $kerf],
				[$x_dim - $thickness, $z + $kerf],
				[$x_dim - $thickness, $z + $tab_width - $kerf],
				[$x_dim, $z + $tab_width + $kerf],
				;
		}

		$z += $tab_width * 2;
	}

	# Top edge
	if ($inset)
	{
		push @points, [$x_dim - $thickness, $height];
	} else {
		push @points, [$x_dim, $height];
	}

	$x = $x_dim / 2 + $tab_width * ($num_x_tabs - 0.5);

	for my $n (1..$num_x_tabs)
	{
		push @points,
			[$x + $kerf, $height],
			[$x - $kerf, $height - $thickness],
			[$x + $kerf - $tab_width, $height - $thickness],
			[$x - $kerf - $tab_width, $height],
			;
		$x -= $tab_width * 2;
	}

	# Height edge
	if ($inset)
	{
		push @points, [$thickness, $height];
	} else {
		push @points, [0, $height];
	}

	$z = $height/2 + $tab_width * ($num_z_tabs - 0.5);
	for my $n (1..$num_z_tabs)
	{
		if ($inset)
		{
			push @points,
				[$thickness, $z + $kerf],
				[0, $z - $kerf],
				[0, $z + $kerf - $tab_width],
				[$thickness, $z - $kerf - $tab_width],
				;
		} else {
			push @points,
				[0, $z + $kerf],
				[$thickness, $z - $kerf],
				[$thickness, $z + $kerf - $tab_width],
				[0, $z - $kerf - $tab_width],
				;
		}
		$z -= $tab_width * 2;
	}

	# Close it back to the bottom
	if ($inset)
	{
		push @points, [$thickness, 0];
	} else {
		push @points, [0, 0];
	}

	return make_path(@points);
}

print make_group("translate(0,0)", make_top());
print make_group("translate(" . ($width+$spacing) .",0)", make_top());
print make_group(
	make_translate(0, $length + $spacing),
	make_side($width, $num_x_tabs, 0)
);
print make_group(
	make_translate($width + $spacing, $length + $spacing),
	make_side($width, $num_x_tabs, 0)
);

print make_group(
	make_translate(0, $length + $height + $spacing * 2),
	make_side($length, $num_y_tabs, 1)
);
print make_group(
	make_translate($length + $spacing, $length + $height + $spacing * 2),
	make_side($length, $num_y_tabs, 1)
);

print <<"";
</g>
</svg>

__END__
