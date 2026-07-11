#!/bin/bash
set -e

MT5_DIR=$(find "$WINEPREFIX/drive_c/Program Files" -name "MetaTrader 5" -type d 2>/dev/null | head -1)
if [ -z "$MT5_DIR" ]; then
    echo "ERROR: MetaTrader 5 not found in Wine prefix" >&2
    exit 1
fi

METAEDITOR="$MT5_DIR/MetaEditor64.exe"
if [ ! -f "$METAEDITOR" ]; then
    echo "ERROR: MetaEditor64.exe not found at $METAEDITOR" >&2
    exit 1
fi

SOURCE="${1:-}"
if [ -z "$SOURCE" ]; then
    echo "Usage: compile <source.mq5> [output-dir]" >&2
    echo "" >&2
    echo "Mount your source directory at /workspace/src and includes at /workspace/include" >&2
    exit 1
fi
OUTPUT_DIR="${2:-/workspace/out}"

SOURCE_FILE=$(basename "$SOURCE")
SOURCE_EXT="${SOURCE_FILE##*.}"

case "$SOURCE_EXT" in
    mq5) OUT_EXT="ex5" ;;
    *)   echo "ERROR: unknown source extension .$SOURCE_EXT (expected .mq5)" >&2; exit 1 ;;
esac

SOURCE_REL=$(dirname "$SOURCE" | sed 's|^/workspace/src/\?||')
MQL_DIR="$MT5_DIR/MQL5"
mkdir -p "$MQL_DIR/Include"

# Copy source to MT5 Experts tree using a safe temp name
DEST_DIR="$MQL_DIR/Experts/$SOURCE_REL"
mkdir -p "$DEST_DIR"
SAFE_NAME="__compile_input.mq5"
LOG_NAME="__compile_input.log"
OUT_NAME="__compile_input.$OUT_EXT"
cp "$SOURCE" "$DEST_DIR/$SAFE_NAME"

# Upsert custom includes
if [ -d "/workspace/include" ]; then
    shopt -s nullglob
    for f in "/workspace/include/"*; do
        cp -r "$f" "$MQL_DIR/Include/"
    done
fi

# Upsert libraries
if [ -d "/workspace/libraries" ]; then
    shopt -s nullglob
    mkdir -p "$MT5_DIR/Libraries"
    for f in "/workspace/libraries/"*; do
        cp -r "$f" "$MT5_DIR/Libraries/"
    done
fi

# Windows path for MetaEditor (safe name, no spaces/special chars)
WIN_BASE="MQL5\\Experts${SOURCE_REL:+\\$SOURCE_REL}"
WIN_SRC="$WIN_BASE\\$SAFE_NAME"
WIN_LOG="$WIN_BASE\\$LOG_NAME"

echo "[compile] Compiling $SOURCE_FILE ..."
Xvfb :99 -screen 0 1024x768x16 -ac >/dev/null 2>&1 &
XVFB_PID=$!
sleep 1

cd "$MT5_DIR"
set +e
wine64 "$METAEDITOR" \
    /portable \
    /compile:"$WIN_SRC" \
    /log:"$WIN_LOG" 2>/dev/null
META_EXIT=$?
set -e

EXIT_CODE=0
LOG_FILE="$DEST_DIR/$LOG_NAME"
if [ -f "$LOG_FILE" ]; then
    echo ""
    tr -d '\000' < "$LOG_FILE"
    echo ""
fi

OUTPUT_FILE="$DEST_DIR/$OUT_NAME"
if [ -f "$OUTPUT_FILE" ]; then
    OUT_DIR="$OUTPUT_DIR/$SOURCE_REL"
    mkdir -p "$OUT_DIR"
    TARGET_NAME="${SOURCE_FILE%.*}.$OUT_EXT"
    cp "$OUTPUT_FILE" "$OUT_DIR/$TARGET_NAME"
    echo "OK: $TARGET_NAME"
else
    echo ""
    echo "FAIL: no compiled output produced" >&2
    EXIT_CODE=1
fi

kill $XVFB_PID 2>/dev/null || true

exit $EXIT_CODE
