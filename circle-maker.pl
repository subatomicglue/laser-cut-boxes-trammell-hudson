#!/usr/bin/env perl
# Generate a space filled with random circles
use warnings;
use strict;
use Data::Dumper;
#use Math::Geometry::Voronoi;
#use Math::Clipper;
use Getopt::Long qw(:config no_ignore_case);

my @circles;
my $rmax = 20;
my $rmin = 1.5;
my $xsize = 89;
my $ysize = 50;
my $fail_iters = 0;

my $usage = <<__END_HELP__;
Usage: circle-maker [options] > circle.svg
Options:
    -h | -? | --help           This help
    -x N                       X dimension in mm
    -y N                       Y dimension in mm
    --max N                    Maximum radius for the circles
    --min N                    Minimum radius for the circles
 
__END_HELP__

GetOptions(
	'h|?|help'		=> sub { print $usage; exit 0 },
	'x=f'			=> \$xsize,
	'y=f'			=> \$ysize,
	'max=f'			=> \$rmax,
	'min=f'			=> \$rmin,
) or die $usage;

die "Max must be larger than min!\n"
	if $rmax < $rmin;

print <<"";
<!-- Created with circle-maker (http://trmm.net/) -->
<svg xmlns="http://www.w3.org/2000/svg">
<g transform="scale(3.543307)"><!-- scale to mm -->

#while (@circles < 100 and $fail_iters < 10000)
while ($fail_iters < 1000)
{
	# Decide where to put the circle
	my $x = rand $xsize;
	my $y = rand $ysize;
	my $rm = $rmax;
	#printf "%d,%d,%d\n", $x, $y, $rm;

	# Find the largest radius that will fit
	for my $circle (@circles)
	{
		my ($r1,$x2,$y2) = @$circle;
		my $dx = $x - $x2;
		my $dy = $y - $y2;
		my $d = sqrt($dx*$dx + $dy*$dy);
		my $r = $d - $r1;
		#printf "-- %d,%d,%d\n", $x2, $y2, $r;

		if ($r <= 0)
		{
			# Inside another circle.  abort
			$rm = 0;
			$fail_iters++;
			last;
		}

		if ($rm > $r)
		{
			# Smaller than the current min distance
			$rm = $r;
		}
	}

	# If we are too close to the side, limit our radius
	$rm = $x if $rm > $x;
	$rm = $y if $rm > $y;
	$rm = $xsize - $x if $rm > $xsize - $x;
	$rm = $ysize - $y if $rm > $ysize - $y;

	# If we are too close to any other circle or the edge, skip this
	next if $rm <= $rmin;

	# Limit the size to the maximum
	$rm = $rmax if $rm > $rmax;

	# Shrink in slightly
	my $r = $rm - $rmin/3;

	# Looks like a good candidate
	print <<"";
		<circle
			cx="$x"
			cy="$y"
			r="$r"
			stroke-width="0.1"
			stroke="#FF0000"
			fill="none"
		/>

	push @circles, [$rm, $x, $y];
	$fail_iters = 0;
}

printf STDERR "%d circles\n", scalar(@circles);

print <<"";
</g>
</svg>

__END__
