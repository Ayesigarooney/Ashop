"""
Ashop Launcher Icon Generator
Produces:
  assets/icon/app_icon.png          - 1024x1024 full icon (square, no transparency)
  assets/icon/app_icon_foreground.png - 1024x1024 foreground layer for adaptive icon (transparent bg)

Design:
  - Dark navy background (#0F172A)
  - White rounded rectangle card in center
  - Bold teal "A" letter
  - Small teal shopping bag icon below the A
  - Teal accent dot / underline
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

W = H = 1024
BG_COLOR = (15, 23, 42, 255)          # #0F172A dark navy
CARD_COLOR = (255, 255, 255, 255)     # white card
TEAL = (20, 184, 166, 255)            # #14B8A6 teal (matches app theme)
TEAL_DARK = (13, 148, 136, 255)       # #0D9488 darker teal for depth
ACCENT = (45, 212, 191, 255)          # #2DD4BF light teal accent

# ── helpers ──────────────────────────────────────────────────────────────────

def new_layer():
    return Image.new('RGBA', (W, H), (0, 0, 0, 0))


def composite(base, layer):
    return Image.alpha_composite(base, layer)


# ── 1. Base: solid dark background ───────────────────────────────────────────
base = Image.new('RGBA', (W, H), BG_COLOR)

# ── 2. Subtle radial glow in center ──────────────────────────────────────────
glow = new_layer()
gd = ImageDraw.Draw(glow)
cx, cy = W // 2, H // 2
for r in range(380, 0, -1):
    alpha = int(35 * (1 - r / 380))
    gd.ellipse([cx - r, cy - r, cx + r, cy + r],
               fill=(20, 184, 166, alpha))
base = composite(base, glow)

# ── 3. White rounded card ─────────────────────────────────────────────────────
card = new_layer()
cd = ImageDraw.Draw(card)
margin = 180
cd.rounded_rectangle(
    [margin, margin, W - margin, H - margin],
    radius=160,
    fill=CARD_COLOR
)
base = composite(base, card)

# ── 4. Inner teal gradient strip (top of card) ───────────────────────────────
strip = new_layer()
sd = ImageDraw.Draw(strip)
sd.rounded_rectangle(
    [margin, margin, W - margin, margin + 220],
    radius=160,
    fill=TEAL
)
# cover bottom corners of strip so only top corners are rounded
sd.rectangle(
    [margin, margin + 160, W - margin, margin + 220],
    fill=TEAL
)
base = composite(base, strip)

# ── 5. Bold "A" letter ────────────────────────────────────────────────────────
letter = new_layer()
ld = ImageDraw.Draw(letter)

# Draw the A as polygons — reliable across all machines (no font dependency)
# Outer A shape
ax = W // 2  # center x = 512
ay_top = 285
ay_bot = 630
half_w = 155
bar_y1 = 490
bar_y2 = 530

outer_A = [
    (ax,           ay_top),          # apex
    (ax + half_w,  ay_bot),          # bottom-right foot
    (ax + half_w - 52, ay_bot),      # foot inner-right
    (ax + 42,      bar_y2 + 10),     # crossbar right-inner
    (ax - 42,      bar_y2 + 10),     # crossbar left-inner
    (ax - half_w + 52, ay_bot),      # foot inner-left
    (ax - half_w,  ay_bot),          # bottom-left foot
]
ld.polygon(outer_A, fill=TEAL_DARK)

# Inner white triangle cutout (makes the A hollow)
inner_A = [
    (ax,           ay_top + 80),
    (ax + 80,      bar_y1 - 10),
    (ax - 80,      bar_y1 - 10),
]
ld.polygon(inner_A, fill=CARD_COLOR)

# Crossbar
ld.rounded_rectangle(
    [ax - half_w + 30, bar_y1, ax + half_w - 30, bar_y2],
    radius=14,
    fill=TEAL
)
base = composite(base, letter)

# ── 6. Small shopping bag below the A ────────────────────────────────────────
bag = new_layer()
bd = ImageDraw.Draw(bag)

bx, by = ax, 720        # bag center
bw, bh = 110, 95        # bag body width, height

# Bag body
bd.rounded_rectangle(
    [bx - bw // 2, by - bh // 2, bx + bw // 2, by + bh // 2],
    radius=18,
    fill=TEAL
)
# Bag handle (arc via thick ellipse outline)
handle_box = [bx - 38, by - bh // 2 - 44, bx + 38, by - bh // 2 + 14]
bd.arc(handle_box, start=200, end=340, fill=TEAL_DARK, width=14)

# Small white horizontal lines = "items in bag"
for i, line_y in enumerate([by - 18, by, by + 18]):
    w_line = 58 - i * 10
    bd.rounded_rectangle(
        [bx - w_line // 2, line_y - 4, bx + w_line // 2, line_y + 4],
        radius=4,
        fill=CARD_COLOR
    )

base = composite(base, bag)

# ── 7. Accent dot under shopping bag ─────────────────────────────────────────
acc = new_layer()
ad = ImageDraw.Draw(acc)
dot_y = 805
dot_r = 12
ad.ellipse(
    [ax - dot_r, dot_y - dot_r, ax + dot_r, dot_y + dot_r],
    fill=ACCENT
)
base = composite(base, acc)

# ── Save full icon ────────────────────────────────────────────────────────────
os.makedirs('assets/icon', exist_ok=True)
base.save(r'C:\Users\Administrator\ashop\assets\icon\app_icon.png')
print('Saved app_icon.png')

# ── Foreground-only (transparent bg, for adaptive icon) ───────────────────────
fg = new_layer()

# Re-draw card, letter, bag and accent on transparent background
# Card
fcd = ImageDraw.Draw(fg)
fcd.rounded_rectangle(
    [margin, margin, W - margin, H - margin],
    radius=160,
    fill=CARD_COLOR
)
fg = composite(fg, strip)   # teal header strip
fg = composite(fg, letter)  # A
fg = composite(fg, bag)     # bag
fg = composite(fg, acc)     # dot

fg.save(r'C:\Users\Administrator\ashop\assets\icon\app_icon_foreground.png')
print('Saved app_icon_foreground.png')
print('Done! Now run: dart run flutter_launcher_icons')
