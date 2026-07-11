# Development — YEBICHU MetaTrader5 Compiler

<p align="center">
  <img src="https://yebichu.com/_next/image?url=%2Fart%2Fbyob-boy-giant-can.png&w=1200&q=75" width="500" alt="Everything in a can">
</p>

This directory is the engine room 🏭. The `Dockerfile` and scripts that turn
a bare Alpine image + Windows compiler into a portable MQL5 build system. 🔧

## Files

| File | Does what |
|---|---|
| `Dockerfile` | Alpine + Wine 9.0 + MetaEditor64 + 262 stdlib headers |
| `entrypoint.sh` | Runs *inside* the container. Copies sources, runs MetaEditor, copies back `.ex5`. |
| `compile.sh` | Your entry point. Builds the image, mounts `MQ5/` directories, runs the container. |
| `template/` | Scaffold files used by `make init` (MyEA.mq5, MyLib.mqh) |

---

## How the Dockerfile works

```
FROM alpine:3.20                       # 14 MB base

apk add wine xvfb xauth curl bash      # → 424 MB (Wine is huge, sorry)

curl mt5setup.exe                      # Download MetaTrader web installer
wine mt5setup.exe /auto                # Install silently (Xvfb virtual display)

wine terminal64.exe                    # First-run: generates 237 MQL5 stdlib headers
rm terminal64.exe                      # Strip terminal (~80 MB saved)
rm -rf Sound Help Config               # Strip non-essentials

COPY entrypoint.sh /usr/local/bin/compile
```

The result: a ~2 GB image that can compile any `.mq5` file.

<p align="center">
  <img src="https://yebichu.com/_next/image?url=%2Fart%2Fpricing-shelf-collage.png&w=1200&q=75" width="400" alt="Efficient layering">
  <br>
  <em>One build, many compiles. Docker layer caching keeps it fast.</em>
</p>

## Building the image

```bash
docker build -t yebichu-mql5-compiler .
```

| Stage | Time | Notes |
|---|---|---|
| `apk add` | ~13 s | 115 packages, 424 MB |
| `mt5setup.exe /auto` | ~30 s | Downloads + installs MT5 |
| `terminal64.exe` init | ~8 s | Generates 237 MQL5 headers |
| Strip + finalize | ~1 s | Removes terminal binary |
| **Total (first build)** | **~75 s** | With `--no-cache` |

Subsequent builds use Docker layer caching and take <1 s (unless you change
the Dockerfile).

## Container interface

The entrypoint (`/usr/local/bin/compile`) expects:

```
/workspace/src/<...>/<file>.mq5   → the source to compile
/workspace/include/                → custom .mqh files (merged with stdlib)
/workspace/libraries/              → .dll files (upserted before compile)
/workspace/out/                    → compiled .ex5 lands here (preserves subdirs)
```

You never call the entrypoint directly — `compile.sh` handles the mounts.

## compile.sh usage

```bash
./compile.sh [options] <source.mq5>

Options:
  --include <dir>     Custom .mqh directory (default: ../MQ5/Include)
  --libraries <dir>   .dll directory (default: ../MQ5/Libraries)
  --output <dir>      Output directory (default: ../MQ5/Experts)
  -h, --help          Show help
```

The script:
1. Resolves the source file's **grandparent** directory as the Docker mount root
   (so subdirectory structure is preserved in the output)
2. Builds the Docker image if needed
3. Mounts include, libraries, and output directories
4. Runs the container
5. Displays the compile log (decoded from UTF-16LE → readable text)
6. Exits with code 0 on success, 1 on compile failure

## What gets stripped from the image

| Removed | Size saved | Why it's safe |
|---|---|---|
| `terminal64.exe` | ~80 MB | Only needed for first-run header init |
| `Sound/` | ~5 MB | No audio in a headless container |
| `Help/` | ~10 MB | Documentation files |
| `Config/` | ~2 MB | Default configs, not needed |

**Kept**: `MetaEditor64.exe`, all 262 stdlib headers, `MQL5/Include/Trade/Trade.mqh`
and friends.

<p align="center">
  <img src="https://yebichu.com/_next/image?url=%2Fart%2Fhome-side-eye-girl.png&w=1920&q=75" width="350" alt="No runtime">
  <br>
  <em>Compile only. The terminal is gone. No charts, no trading, no backtester.</em>
</p>

## Debugging

If a compile fails, the full MetaEditor log is displayed — including line
numbers, error codes, and the exact token that caused the issue:

```
MQL5\Experts\MyEA\MyEA.mq5(4,1) : error 149: 'THIS' - unexpected token
Result: 1 error
```

The log file (UTF-16LE, decoded to plain text) is shown verbatim.
Zero mystery exits.

---

<p align="center">
  <small>🛒 <a href="https://yebichu.com/en/shop">Wear the label</a> — stickers, tees, mugs for compiler enthusiasts 🧢</small>
  <br><br>
  <small>A YEBICHU project.</small>
  <br>
  <small>Repo: <a href="https://github.com/mihailnica10/yebichu-metatrader5-compiler">mihailnica10/yebichu-metatrader5-compiler</a></small>
</p>
<!-- cached -->
