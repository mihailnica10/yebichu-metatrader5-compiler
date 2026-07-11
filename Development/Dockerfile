FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    curl \
    wine \
    xvfb \
    xauth \
    && rm -rf /var/cache/apk/*

ENV WINEPREFIX=/opt/wine \
    WINEARCH=win64 \
    DISPLAY=:99 \
    WINEDLLOVERRIDES="mscoree,mshtml=" \
    WINEDEBUG=-all

RUN curl -fsSL -o /tmp/mt5setup.exe \
    "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe" && \
    echo "[build] Installing MetaTrader 5..." && \
    Xvfb :99 -screen 0 1024x768x16 -ac >/dev/null 2>&1 & \
    sleep 1 && \
    wine /tmp/mt5setup.exe /auto && \
    rm -f /tmp/mt5setup.exe && \
    kill %1 2>/dev/null || true && \
    echo "[build] MT5 install complete"

RUN echo "[build] Initializing MQL5 standard library via terminal64 first-run..." && \
    Xvfb :99 -screen 0 1024x768x16 -ac >/dev/null 2>&1 & \
    sleep 1 && \
    MT5_DIR="$WINEPREFIX/drive_c/Program Files/MetaTrader 5" && \
    timeout 30 wine "$MT5_DIR/terminal64.exe" 2>&1 || true && \
    kill %1 2>/dev/null || true && \
    HDR_COUNT=$(find "$MT5_DIR/MQL5/Include" -name "*.mqh" 2>/dev/null | wc -l) && \
    echo "[build] $HDR_COUNT MQL5 standard library headers initialized ($([ $HDR_COUNT -gt 0 ] && echo OK || echo MISSING))"

RUN MT5_DIR="$WINEPREFIX/drive_c/Program Files/MetaTrader 5" && \
    rm -f "$MT5_DIR/terminal64.exe" && \
    rm -rf "$MT5_DIR/Sound" "$MT5_DIR/Help" "$MT5_DIR/Config" && \
    rm -f "$WINEPREFIX/drive_c/windows/system32/mscoree.dll" 2>/dev/null && \
    echo "[build] Stripped terminal, headers preserved at $MT5_DIR/MQL5/"

COPY entrypoint.sh /usr/local/bin/compile
RUN chmod +x /usr/local/bin/compile

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/compile"]

LABEL org.opencontainers.image.source="https://github.com/mihailnica10/yebichu-metatrader5-compiler" \
      org.opencontainers.image.description="Alpine-based MQL5 compiler using Wine + MetaEditor" \
      org.opencontainers.image.version="0.1"
