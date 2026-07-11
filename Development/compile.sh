#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="yebichu-mql5-compiler:latest"

INCLUDE_DIR="${PROJECT_DIR}/MQ5/Include"
LIBRARIES_DIR="${PROJECT_DIR}/MQ5/Libraries"
OUTPUT_DIR="${PROJECT_DIR}/MQ5/Experts"
SOURCE_FILE=""

usage() {
    echo "Usage: $0 [options] <source.mq5>"
    echo ""
    echo "Compile an MQL5 source file using a Docker-based MetaEditor."
    echo ""
    echo "  --include <dir>    Include directory for .mqh files (default: MQ5/Include)"
    echo "  --libraries <dir>  Libraries directory for .dll files (default: MQ5/Libraries)"
    echo "  --output <dir>     Output directory for .ex5 (default: MQ5/Experts)"
    echo ""
    echo "Example:"
    echo "  $0 --include MQ5/Include --libraries MQ5/Libraries MQ5/Experts/MyEA/MyEA.mq5"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include)   INCLUDE_DIR="$2"; shift 2 ;;
        --libraries) LIBRARIES_DIR="$2"; shift 2 ;;
        --output)    OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help)   usage ;;
        *) SOURCE_FILE="$1"; shift ;;
    esac
done

if [ -z "$SOURCE_FILE" ]; then
    usage
fi

SOURCE_FILE="$(realpath "$SOURCE_FILE")"
if [ ! -f "$SOURCE_FILE" ]; then
    echo "ERROR: source file not found: $SOURCE_FILE" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "[compile] Building compiler image..."
BUILD_OUT=$(docker build -q -t "$IMAGE_NAME" "$SCRIPT_DIR" 2>&1)
echo "[compile] Image: ${BUILD_OUT##*:}"

SRC_DIR=$(dirname "$SOURCE_FILE")
SRC_GRANDPA=$(dirname "$SRC_DIR")
SRC_SUBDIR=$(basename "$SRC_DIR")

DOCKER_ARGS=(
    --rm -i
    -v "$SRC_GRANDPA:/workspace/src:ro"
    -v "$OUTPUT_DIR:/workspace/out"
)

if [ -d "$INCLUDE_DIR" ]; then
    DOCKER_ARGS+=(-v "$INCLUDE_DIR:/workspace/include:ro")
fi

if [ -d "$LIBRARIES_DIR" ]; then
    DOCKER_ARGS+=(-v "$LIBRARIES_DIR:/workspace/libraries:ro")
fi

echo "[compile] src:     $SOURCE_FILE"
echo "[compile] include: ${INCLUDE_DIR:-none}"
echo "[compile] libr:    ${LIBRARIES_DIR:-none}"
echo "[compile] output:  $OUTPUT_DIR"
echo ""

docker run "${DOCKER_ARGS[@]}" \
    "$IMAGE_NAME" \
    "/workspace/src/$SRC_SUBDIR/$(basename "$SOURCE_FILE")" "/workspace/out"
