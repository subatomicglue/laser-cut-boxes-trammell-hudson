#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dumper;
use Math::Geometry::Voronoi;
use Math::Clipper;
use Getopt::Long qw(:config no_ignore_case);

my $xsize = 100;
my $ysize = 100;
my $num = 32;
my $line_width = 2;

my $usage = <<__END_HELP__;
Usage: lace-maker [options] > lace.svg
Options:
    -h | -? | --help           This help
    -x N                       X dimension in mm
    -y N                       Y dimension in mm
    -n N                       Number of points
    -w N                       Line width in mm
 
Note that if the point density is too high the Voronoi generation might
fail, causing an empty SVG output.
__END_HELP__

GetOptions(
	'h|?|help'		=> sub { print $usage; exit 0 },
	'x=f'			=> \$xsize,
	'y=f'			=> \$ysize,
	'n=i'			=> \$num,
	'w=f'			=> \$line_width,
) or die $usage;


my @points = map { [
	(rand $xsize*1.1) - $xsize*.05,
	(rand $ysize*1.1) - $ysize*.05,
] } 0..$num;

my $geo = Math::Geometry::Voronoi->new(points => \@points);
$geo->compute;

my @polys = $geo->polygons;

# Inset everything and then replace the polygons inplace
for my $poly (@polys)
{
	# Remove index value
	shift @$poly;

	# Inset the polygon by the line width (negative == towards center)
	my $n = Math::Clipper::offset([$poly], -$line_width);
	$poly = $n->[0];
}


# Clip it by the bounding box
my $bounding = [
	[0,0],
	[$xsize,0],
	[$xsize,$ysize],
	[0,$ysize],
];

my $clipper = Math::Clipper->new;
my $scale = Math::Clipper::integerize_coordinate_sets($bounding, @polys);

eval {
	$clipper->add_subject_polygons(\@polys);
	1;;
} or die "Bad polygons?  Try reducing number of points or line width.\n";

$clipper->add_clip_polygon($bounding);

my $n = $clipper->execute(Math::Clipper::CT_INTERSECTION);
Math::Clipper::unscale_coordinate_sets($scale, $n);
@polys = @$n;

#print Dumper(\@polys);
#__END__

print <<"";
<!-- Created with lace-maker (http://trmm.net/) -->
<svg xmlns="http://www.w3.org/2000/svg">
<g transform="scale(3.543307)"><!-- scale to mm -->


for my $poly (@polys)
{
	print <<"";
		<path
			stroke		= "#ff0000"
			fill		= "none"
			stroke-width	= "0.1px"
			d		= "M

	for my $pt (@$poly)
	{
		my ($x,$y) = @$pt;
		print "$x,$y\n";
	}

	# Close the path
	print <<"";
		Z"/>

	#print Dumper($poly);
}


print <<"";
</g>
</svg>

__END__
