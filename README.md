# ZedBoard VGA Image Pipeline

A real-time image processing pipeline implemented in Verilog for the **Digilent ZedBoard (XC7Z020)**. The system composites a foreground image over a configurable background using **chroma key (green screen)**, applies **brightness/saturation enhancement**, and supports four real-time image filters — all displayed over a 640×480 VGA output at 60 Hz.

---

## Demo

The pipeline reads a 320×240 foreground image (`fg.mem`) and a 320×240 background image (`bg.mem`) from on-chip BRAM. Any green-screen pixels in the foreground are replaced with the corresponding background pixel. The composited result is 2× scaled and output on VGA. Filters and enhancements are controlled in real time via the board's switches and buttons.

---

## Features

- **VGA output** — 640×480 @ 60 Hz, pixel-doubled from 320×240 source images
- **Chroma key compositing** — HSV-based green-screen removal with tunable hue/saturation/value thresholds
- **Brightness & saturation enhancement** — per-frame HSV adjustment via pushbuttons
- **Four real-time filters** (switch-selectable):
  - Sepia tone
  - Colour invert
  - Edge detection (Sobel)
  - Cartoon effect (Gaussian blur + Sobel edge overlay)
- **Fully pipelined** — all processing runs at 100 MHz system clock; pixel clock enable (25 MHz) gates the pixel-rate logic

---

## Architecture

```
                       ┌─────────────────────────────────────────────────────────┐
                       │              top_combined                               │
                       │                                                         │
   100 MHz ──► clk_div ──► pix_ce          ┌──────────────────────────────────┐  │
                       │                   │       top_image_pipeline         │  │
   hcount / vcount ────┼──────────────────►│                                  │  │
   (VGA timing)        │                   │  pixel_addr ──► fg_image_rom     │  │
                       │                   │             ──► bg_image_rom     │  │
                       │                   │                                  │  │
                       │                   │  fg_rgb ──► rgbtohsv             │  │
                       │                   │         ──► chroma_key           │  │
                       │                   │         ──► enhance              │  │
                       │                   │         ──► hsvtorgb             │  │
                       │                   │                                  │  │
                       │                   │  bg_rgb ──► [16-cycle delay]     │  │
                       │                   │                                  │  │
                       │                   │  chroma_key_match? bg : fg ─────►│  │
                       │                   └──────────────────────────────────┘  │
                       │                                  │ rgb_composited       │
                       │                                  ▼                      │
                       │                           ┌────────────┐                │
                       │                           │  filters   │                │
                       │                           │  (sepia /  │                │
                       │                           │  invert /  │                │
                       │                           │  edge /    │                │
                       │                           │  cartoon)  │                │
                       │                           └─────┬──────┘                │
                       │                                 │ rgb_out               │
                       └─────────────────────────────────┼───────────────────────┘
                                                         ▼
                                                    VGA output
                                                 (R[3:0] G[3:0] B[3:0])
```

### Module Breakdown

| Module | Description |
|---|---|
| `zybo_vga_top` | Top-level; clock, reset, debounce, VGA output |
| `clk_div` | Divides 100 MHz system clock → 25 MHz pixel clock enable |
| `vga_timing` | Generates `hcount`, `vcount`, `hsync`, `vsync`, `active` |
| `top_combined` | Ties image pipeline and filter bank together |
| `top_image_pipeline` | ROM reads, chroma key, enhance, HSV conversion, BG compositing |
| `image_rom` | Synchronous ROM backed by BRAM; initialised from `.mem` file |
| `rgbtohsv` | 4-stage pipelined RGB → HSV converter |
| `chroma_key` | Detects green-screen pixels in HSV space |
| `enhance` | Per-frame brightness and saturation adjustment in HSV |
| `hsvtorgb` | 10-stage pipelined HSV → RGB converter |
| `filters` | Filter selector; routes to sepia / invert / edge / cartoon |
| `sepia` | 4-stage pipelined sepia tone filter |
| `invert` | 1-stage colour invert |
| `grayscale` | 3-stage luminance-weighted grayscale |
| `cartoon` | Gaussian blur + Sobel edges for cartoon effect |
| `line_buf` | 3×3 sliding-window line buffer (clock-enabled shift register) |
| `sobel_op` | 4-stage Sobel gradient magnitude |
| `gaussian` | 3-stage separable Gaussian blur (reduced bit-depth) |
| `edge_det` | Thresholds Sobel gradient → edge / cartoon-edge flags |

---

## Pipeline Latency

All modules are clocked at **100 MHz**. Pixel-rate logic is gated by `pix_ce` (25 MHz enable).

| Stage | Cycles (100 MHz) |
|---|---|
| BRAM ROM read | 1 |
| `rgbtohsv` | 4 |
| `chroma_key` | 1 |
| `enhance` | 1 |
| `hsvtorgb` | 10 |
| **Total (fg path)** | **17** |

The background pixel and `chroma_key_match` signal are delayed by matching shift registers to arrive in phase with the foreground pipeline output.

---

## Image Format

Images are stored as plain-text hex files — one 24-bit RGB pixel per line (no `0x` prefix):

```
FF0000    ← red pixel
00FF00    ← green pixel
0000FF    ← blue pixel
...
```

- Resolution: **320 × 240** pixels (76,800 entries per file)
- Pixel order: row-major, top-left first
- File names: `fg.mem` (foreground / green-screen subject), `bg.mem` (replacement background)

> **Important:** Files must contain **exactly 76,800 lines**. Larger files will be silently truncated by `$readmemh`, but keeping them trimmed avoids Vivado BRAM inference issues (see [Known Issues](#known-issues--design-notes)).

### Generating `.mem` Files

Using Python + Pillow (resize to 320×240 first):

```python
from PIL import Image

def image_to_mem(path, out):
    img = Image.open(path).convert("RGB").resize((320, 240))
    with open(out, "w") as f:
        for r, g, b in img.getdata():
            f.write(f"{r:02X}{g:02X}{b:02X}\n")

image_to_mem("foreground.png", "fg.mem")
image_to_mem("background.png", "bg.mem")
```

---

## Controls

| Input | Function |
|---|---|
| `SW[0]` | Enable filters |
| `SW[1]` | Enable brightness/saturation enhancement |
| `SW[3:2]` = `00` | Select **Sepia** filter |
| `SW[3:2]` = `01` | Select **Invert** filter |
| `SW[3:2]` = `10` | Select **Edge detection** filter |
| `SW[3:2]` = `11` | Select **Cartoon** filter |
| `BTN[0]` | Increase brightness |
| `BTN[1]` | Decrease brightness |
| `BTN[2]` | Increase saturation |
| `BTN[3]` | Decrease saturation |
| `BTN[2]` + `BTN[3]` simultaneously | Reset saturation to default |
| `BTN[0]` + `BTN[1]` simultaneously | Reset brightness to default |

**LEDs:**

| LED | Meaning |
|---|---|
| `LED[0]` | Filters enabled |
| `LED[1]` | Enhancement enabled |
| `LED[3:2]` | Active filter index (binary) |

---

## Resource Utilisation (XC7Z020)

| Resource | Used | Available | % |
|---|---|---|---|
| BRAM36 | ~100 | 140 | ~71% |
| LUT | ~3,500 | 53,200 | ~6.6% |
| FF | ~5,000 | 106,400 | ~4.7% |
| DSP48 | ~18 | 220 | ~8.2% |

> BRAM is dominated by the two 76,800 × 24-bit image ROMs (50 BRAM36 each).

---

## Project Structure

```
srcs_v2/
├── zybo_vga_top.v          # Top-level
├── zybo_vga_top.xdc        # Pin constraints (ZedBoard)
├── clk_div.v               # 100 MHz → 25 MHz clock enable
├── vga_timing.v            # VGA sync generator
├── param.v                 # Shared parameters (include file)
│
├── top_combined.v          # Pipeline + filter integration
├── top_image_pipeline.v    # ROM → chroma key → enhance → composite
├── image_rom.v             # Parameterised BRAM ROM
│
├── rgbtohsv.v              # RGB → HSV (4 pipeline stages)
├── hsvtorgb.v              # HSV → RGB (10 pipeline stages)
├── chroma_key.v            # Green-screen detector
├── enhance.v               # Brightness / saturation control
│
├── filters.v               # Filter bank selector
├── sepia.v                 # Sepia filter
├── invert.v                # Invert filter
├── grayscale.v             # Grayscale conversion
├── cartoon.v               # Cartoon effect (Gaussian + Sobel)
├── line_buf.v              # 3×3 sliding window line buffer
├── sobel_op.v              # Sobel gradient operator
├── gaussian.v              # Gaussian blur kernel
├── edge_det.v              # Edge threshold detector
│
├── fg.mem                  # Foreground image (320×240, 76800 hex lines)
└── bg.mem                  # Background image (320×240, 76800 hex lines)
```

---

## Known Issues & Design Notes

### BRAM Sizing (Critical)
The `image_rom` module declares memory depth as exactly `MEM_DEPTH = 76800` (not `2^ADDR_WIDTH = 131072`). This is intentional and important:

- Two ROMs at depth 131,072 × 24-bit = **172 BRAM36s**, which exceeds the XC7Z020's 140 BRAM36s.
- Vivado would spill the overflow into LUT-distributed RAM, causing an enormous synthesis runtime and likely a failed implementation.
- At depth 76,800 × 24-bit = **100 BRAM36s total**, both ROMs fit comfortably.
- The `(* rom_style = "block" *)` attribute ensures Vivado always infers BRAM (never LUT-RAM).

When `fg.mem` and `bg.mem` contain identical data, Vivado may merge both ROMs into one, halving BRAM usage — this is why the design appeared to work before a different background was introduced.

### Clock Domain
All logic (VGA timing, pixel processing, filter pipeline) runs in a **single 100 MHz clock domain**. The 25 MHz pixel rate is implemented as a clock enable (`pix_ce`), not a separate clock, to avoid CDC complexity.

### `line_buf` Clock Enable
The 3×3 sliding-window line buffer (`line_buf`) must be gated by `pix_ce`. Without the clock enable, the shift register advances 4× too fast relative to the pixel stream, causing the Sobel and Gaussian windows to sample incorrect neighbours. All `line_buf` instances receive `pix_ce` via `cartoon.v` → `filters.v` → `top_combined.v`.

### `LINE_LEN` Parameter
`param.v` sets `LINE_LEN = 800` (full horizontal total, including blanking). Since `line_buf` advances once per `pix_ce` pulse (which fires every pixel clock cycle including blanking), the inter-line spacing in the shift register must equal the full 800-cycle line period, not just the 640-pixel active width.

---

## Building in Vivado

1. Create a new RTL project targeting **xc7z020clg484-1**.
2. Add all `.v` files from `srcs_v2/` as design sources.
3. Add `zybo_vga_top.xdc` as a constraints file.
4. Place `fg.mem` and `bg.mem` in the project directory (or set the appropriate path in `top_image_pipeline.v`).
5. Run Synthesis → Implementation → Generate Bitstream.
6. Program the device via JTAG.

> Synthesis typically completes in **3–6 minutes**. If it runs significantly longer, verify that both `.mem` files are exactly 76,800 lines and that `MEM_DEPTH = 76800` is set correctly in `image_rom.v`.

---

