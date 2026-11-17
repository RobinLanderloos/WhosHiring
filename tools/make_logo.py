"""Draws Who's Hiring?'s project logo (a recruitment notice pinned to a wooden
board, with a big question mark) to media/logo.png. Original artwork, no game
assets.

    python tools/make_logo.py
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFilter

S = 4  # supersampling
W = 400 * S


def p(x, y):
    return (x * S, y * S)


img = Image.new("RGB", (W, W), (24, 30, 44))

# Warm glow behind the board.
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse(p(40, 40) + p(360, 360), fill=170)
glow = glow.filter(ImageFilter.GaussianBlur(60 * S))
img.paste(Image.new("RGB", (W, W), (120, 80, 40)), (0, 0), glow)

d = ImageDraw.Draw(img)

# Wooden board: planks with grain lines and a dark frame.
d.rounded_rectangle(p(38, 52) + p(362, 348), radius=14 * S, fill=(62, 38, 22))
random.seed(5)
for i in range(5):
    top = 66 + i * 55
    d.rectangle(p(52, top) + p(348, top + 50), fill=(118 + i % 2 * 10, 76 + i % 2 * 6, 42))
    for _ in range(6):
        y = top + random.uniform(6, 44)
        d.line([p(56, y), p(344, y + random.uniform(-3, 3))], fill=(96, 60, 32), width=S)
d.rounded_rectangle(p(38, 52) + p(362, 348), radius=14 * S, outline=(40, 24, 14), width=8 * S)

# Parchment notice, slightly rotated.
note = Image.new("RGBA", (W, W), (0, 0, 0, 0))
nd = ImageDraw.Draw(note)
nd.rounded_rectangle(p(112, 88) + p(288, 318), radius=6 * S, fill=(236, 220, 178, 255))
# Edge shading.
nd.rounded_rectangle(p(112, 88) + p(288, 318), radius=6 * S, outline=(190, 160, 110, 255), width=4 * S)
# Writing lines under the question mark.
for i, width in enumerate((120, 100, 130, 80)):
    y = 262 + i * 13
    nd.line([p(200 - width / 2, y), p(200 + width / 2, y)], fill=(150, 120, 80, 255), width=3 * S)
# The question mark: an arc, a stem and a dot.
cx, cy, r = 200, 150, 42
nd.arc(p(cx - r, cy - r) + p(cx + r, cy + r), start=180, end=40, fill=(150, 40, 30, 255), width=19 * S)
end_x = cx + r * math.cos(math.radians(40)) - 4
end_y = cy + r * math.sin(math.radians(40)) - 2
nd.line([p(end_x, end_y), p(200, 208)], fill=(150, 40, 30, 255), width=19 * S, joint="curve")
# Round the joints so the curve flows into the stem.
for jx, jy in ((end_x, end_y), (200, 208)):
    nd.ellipse(p(jx - 9.5, jy - 9.5) + p(jx + 9.5, jy + 9.5), fill=(150, 40, 30, 255))
nd.ellipse(p(189, 222) + p(211, 244), fill=(150, 40, 30, 255))
note = note.rotate(-5, resample=Image.BICUBIC, center=(200 * S, 200 * S))

shadow = Image.new("L", (W, W), 0)
shadow.paste(note.split()[3], (6 * S, 8 * S))
shadow = shadow.filter(ImageFilter.GaussianBlur(6 * S))
img.paste(Image.new("RGB", (W, W), (30, 18, 10)), (0, 0), shadow.point(lambda v: v * 0.6))
img.paste(note, (0, 0), note)

# A red pin at the top of the notice.
d = ImageDraw.Draw(img)
d.ellipse(p(188, 84) + p(214, 110), fill=(200, 40, 40))
d.ellipse(p(193, 88) + p(202, 97), fill=(250, 140, 140))

img = img.resize((400, 400), Image.LANCZOS)
out = os.path.join(os.path.dirname(__file__), "..", "media", "logo.png")
os.makedirs(os.path.dirname(out), exist_ok=True)
img.save(out)
print(os.path.normpath(out))
