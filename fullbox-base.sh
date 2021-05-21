#!/bin/bash

# Helper for running the boxer.pl and lace-maker.pl scripts
#
# NOTE: you should source this into another script
#       see projects/ folder for examples!

source_path=$(dirname $BASH_SOURCE)
[[ $0 == $BASH_SOURCE ]] && echo "This script is intended to be sourced from another script" && exit -1


# config (with defaults)
[ -z ${PREFIX+x} ] && PREFIX="fullbox-base-you-should-include-in-another-script" || PREFIX="$PREFIX"
[ -z ${WIDTH+x} ] && WIDTH=40 || WIDTH="$WIDTH"
[ -z ${HEIGHT+x} ] && HEIGHT=40 || HEIGHT="$HEIGHT"
[ -z ${DEPTH+x} ] && DEPTH=40 || DEPTH="$DEPTH"
[ -z ${MATERIAL_THICKNESS+x} ] && MATERIAL_THICKNESS=3.25 || MATERIAL_THICKNESS="$MATERIAL_THICKNESS"
[ -z ${KERF+x} ] && KERF=0.2 || KERF="$KERF"
[ -z ${SPACING_BETWEEN_PIECES+x} ] && SPACING_BETWEEN_PIECES=1 || SPACING_BETWEEN_PIECES="$SPACING_BETWEEN_PIECES"
[ -z ${TAB_WIDTH+x} ] && TAB_WIDTH=5 || TAB_WIDTH="$TAB_WIDTH"
[ -z ${LACE_LINE_WIDTH+x} ] && LACE_LINE_WIDTH=1 || LACE_LINE_WIDTH="$LACE_LINE_WIDTH"
[ -z ${LACE_NUM_POINTS+x} ] && LACE_NUM_POINTS=40 || LACE_NUM_POINTS="$LACE_NUM_POINTS"
[ -z ${LACE_DIST_FROM_EDGE+x} ] && LACE_DIST_FROM_EDGE=2.2 || LACE_DIST_FROM_EDGE="$LACE_DIST_FROM_EDGE"

echo "Creating ${WIDTH}x${HEIGHT}x${DEPTH}mm box, named like $PREFIX*.svg..."

echo "Outputs into SVG like:"
echo "[1][2]"
echo "[3][4]"
echo "[5][6]"
echo
echo "Assemble the box like:"
echo "   [1]"
echo "[3][5][4][6]"
echo "   [2]"
echo

# utility to run a bash command until success
function do_until_success
{
  CMD="$1"
  echo "- Running command until success: $CMD"
  printf "  "
  RET=255
  while [ $RET -eq 255 ]; do
    #echo "Running $CMD"
    eval $CMD
    RET=$?
    #echo $RET
    printf "."
  done
  echo
  return 0 # success
}

# run 6 lace-maker commands, one per box side
function make_lace_sides
{
  X=$1
  Y=$2
  N=$3
  W=$4
  NAME=$5

  # Usage: lace-maker [options] > lace.svg
  # Options:
  #     -h | -? | --help           This help
  #     -x N                       X dimension in mm
  #     -y N                       Y dimension in mm
  #     -n N                       Number of points
  #     -w N                       Line width in mm
  #
  # Note that if the point density is too high the Voronoi generation might
  # fail, causing an empty SVG output.   So we rerun the command until success
  do_until_success "$source_path/lace-maker.pl -x $X -y $Y -n $N -w $W > \"./$NAME-lace1.svg\" 2> /dev/null"
  do_until_success "$source_path/lace-maker.pl -x $X -y $Y -n $N -w $W > \"./$NAME-lace2.svg\" 2> /dev/null"
  do_until_success "$source_path/lace-maker.pl -x $X -y $Y -n $N -w $W > \"./$NAME-lace3.svg\" 2> /dev/null"
  do_until_success "$source_path/lace-maker.pl -x $X -y $Y -n $N -w $W > \"./$NAME-lace4.svg\" 2> /dev/null"
  do_until_success "$source_path/lace-maker.pl -x $X -y $Y -n $N -w $W > \"./$NAME-lace5.svg\" 2> /dev/null"
  do_until_success "$source_path/lace-maker.pl -x $X -y $Y -n $N -w $W > \"./$NAME-lace6.svg\" 2> /dev/null"
}

# do some arithmetic to figure out final lace params
LACE_WIDTH=`echo "$WIDTH - ($MATERIAL_THICKNESS*2 + $LACE_DIST_FROM_EDGE*2)" | bc`
LACE_HEIGHT=`echo "$HEIGHT - ($MATERIAL_THICKNESS*2 + $LACE_DIST_FROM_EDGE*2)" | bc`
LACE_LINE_WIDTH=`echo "$LACE_LINE_WIDTH * 0.5" | bc`

echo "Creating Lace sides:"
make_lace_sides $LACE_WIDTH $LACE_HEIGHT $LACE_NUM_POINTS $LACE_LINE_WIDTH "$PREFIX"
echo ""

# Usage: boxer [options] > box.svg
# Options:
# -h | -? | --help	This help
# -T | --tab-width N	Tab width in mm
# -t | --thickness N	Material thickness in mm
# -H | --height N		Height of the box, in mm
# -w | --width N		Outside edge length, in mm
# -l | --length N		Outside edge length, in mm for rectangles
# -k | --kerf N		Kerf in mm (typically 0.1)
# -s | --spacing N	Spacing between pieces in mm
echo "Running boxer.pl to create \"./$PREFIX.svg\""
$source_path/boxer.pl -T $TAB_WIDTH -k $KERF -s $SPACING_BETWEEN_PIECES -t $MATERIAL_THICKNESS -H $HEIGHT -w $WIDTH -l $DEPTH > "$PREFIX.svg"
echo "Done"
echo ""

