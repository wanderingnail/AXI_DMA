#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

SHOW_WAVE=${SHOW_WAVE:-"false"}

WAVE_SBIN=wave.sbin
WAVE_LXT=wave.vcd
BUILD_DIR=build
GFLAGS="-S ../gtkw.tcl"

mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Simulation
for TB in `ls ../sim/tb*.v`
do
    iverilog -v -g2012 -Wall -Winfloop -o $WAVE_SBIN -I ../rtl -y ../rtl $TB
    vvp -v -N -lxt2 $WAVE_SBIN
done

gtkwave DMAC.vcd

# if [ "$SHOW_WAVE" = "true" ]; then
#     GTKWAVE_PID=`pgrep gtkwave || echo "none"`
#     if [ "$GTKWAVE_PID" != "none" ]; then
#         pkill gtkwave
#     fi
#     OS=`uname -s`
#     if [ "$OS" = "Darwin" ]; then
#         /Applications/gtkwave.app/Contents/Resources/bin/gtkwave $GFLAGS $WAVE_LXT &
#     else
#         gtkwave $GFLAGS $WAVE_LXT &
#     fi
# fi
