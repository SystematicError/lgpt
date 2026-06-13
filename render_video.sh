#!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#ffmpeg nixpkgs#chafa --command bash

# Usage: ./render_video.sh [FILENAME] [RESOLUTION] [COLORS] [SYMBOLS] [FPS]
#
# [FILENAME] Video file to be rendered
# [RESOLUTION] Terminal output resolution
# [COLORS] Output color depth
# [SYMBOLS] Symbol set to use
# [FPS] Output frame rate
#
# Examples:
# ./render_video.sh badapple.mp4 40x15 none narrow 24
# ./render_video.sh thisisamerica.mp4 72x20 full all 24
#
# The script doesn't bother checking arguments or the current directory
# Just to be safe, make sure no files matching render* are on path
#
# Requires nix
# Alternatively modify the shebang and have ffmpeg and chafa installed

FILENAME="$1"
RESOLUTION="$2"
COLORS="$3"
SYMBOLS="$4"
FPS="$5"

# Encode the video as a GIF, and lower the framerate
ffmpeg -y -i "$FILENAME" -vf "fps=$FPS" render.gif

# Render the GIF into terminal text
chafa \
    --format symbols \
    --symbols "$SYMBOLS" \
    --colors "$COLORS" \
    --size "$RESOLUTION" \
    --stretch \
    --work 9 \
    --optimize 9 \
    --speed max \
    render.gif > "render_${RESOLUTION}_${COLORS}Bit_${SYMBOLS}Sym_${FPS}Fps"
