"""Create Marketplace media and compliant action-list icons from original key art.

Requires Pillow. This script never reads conversations or contacts the network.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
PLUGIN = ROOT / "com.davidedicillo.muse.sdPlugin"
MEDIA = ROOT / "marketplace-media"
MEDIA.mkdir(exist_ok=True)

CREAM = "#FFF0D8"
MUTED = "#C8BBD8"
CORAL = "#F47E78"
LAVENDER = "#B8A8F2"
FONT = "/System/Library/Fonts/Avenir Next.ttc"
NAMES = ["open", "side-chat", "dictate", "finish-send", "send-prompt"]
LABELS = ["Open Muse", "New Side Chat", "Dictate", "Finish & Send", "Saved Prompt"]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT, size, index=1 if bold else 0)


def key(name: str, size: int) -> Image.Image:
    source = PLUGIN / "imgs" / "actions" / name / "key@2x.png"
    return Image.open(source).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)


def make_list_icon(name: str, size: int) -> Image.Image:
    image = key(name, 144)
    alpha = Image.new("L", image.size)
    source = image.load()
    mask = alpha.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, original_alpha = source[x, y]
            # Cream, lavender and coral foreground survive; plum shell and border do not.
            brightness = r + g + b
            opacity = max(0, min(255, round((brightness - 390) * 2.2)))
            mask[x, y] = round(opacity * original_alpha / 255)
    alpha = alpha.resize((size, size), Image.Resampling.LANCZOS)
    result = Image.new("RGBA", (size, size), "white")
    result.putalpha(alpha)
    return result


for name in NAMES:
    icon_dir = PLUGIN / "imgs" / "actions" / name
    make_list_icon(name, 20).save(icon_dir / "icon.png")
    make_list_icon(name, 40).save(icon_dir / "icon@2x.png")

for filename in ("icon.png", "icon@2x.png"):
    unused = PLUGIN / "imgs" / "actions" / "dictate-stop" / filename
    if unused.exists():
        unused.unlink()

plugin_icon_dir = PLUGIN / "imgs" / "plugin"
make_list_icon("open", 28).save(plugin_icon_dir / "category-icon.png")
make_list_icon("open", 56).save(plugin_icon_dir / "category-icon@2x.png")


def canvas() -> Image.Image:
    image = Image.new("RGB", (1920, 960), "#1B1429")
    pixels = image.load()
    for y in range(960):
        for x in range(1920):
            t = 0.28 * x / 1920 + 0.30 * y / 960
            pixels[x, y] = (round(27 + 22 * t), round(20 + 13 * t), round(41 + 31 * t))
    glow = Image.new("RGBA", image.size)
    draw = ImageDraw.Draw(glow)
    draw.ellipse((1220, -270, 2150, 660), fill=(148, 110, 195, 30))
    draw.ellipse((-350, 610, 450, 1410), fill=(244, 126, 120, 20))
    image = Image.alpha_composite(image.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(100)))
    return image


def text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], value: str, size: int,
         fill: str = CREAM, bold: bool = False) -> None:
    draw.text(xy, value, font=font(size, bold), fill=fill)


def pill(draw: ImageDraw.ImageDraw, xy: tuple[int, int], label: str) -> None:
    x, y = xy
    width = round(draw.textlength(label, font=font(23, True))) + 44
    draw.rounded_rectangle((x, y, x + width, y + 52), radius=26,
                           fill="#382B50", outline="#6E598B", width=2)
    text(draw, (x + 22, y + 9), label, 23, LAVENDER, True)


def card(image: Image.Image, xy: tuple[int, int], name: str, title: str,
         subtitle: str | None = None, width: int = 310, height: int = 350) -> None:
    x, y = xy
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((x, y, x + width, y + height), radius=34,
                           fill="#30233F", outline="#705B87", width=2)
    icon_size = 152 if height >= 340 else 126
    image.alpha_composite(key(name, icon_size), (x + (width - icon_size) // 2, y + 40))
    title_width = draw.textlength(title, font=font(31, True))
    text(draw, (round(x + (width - title_width) / 2), y + 222), title, 31, CREAM, True)
    if subtitle:
        sub_width = draw.textlength(subtitle, font=font(22))
        text(draw, (round(x + (width - sub_width) / 2), y + 278), subtitle, 22, MUTED)


def footer(draw: ImageDraw.ImageDraw) -> None:
    text(draw, (94, 883), "Independent plugin for Meta Muse on macOS", 22, MUTED)


# Marketplace app icon, matching the packaged plugin icon.
Image.open(plugin_icon_dir / "marketplace.png").convert("RGBA").save(MEDIA / "app-icon.png")

# Thumbnail.
image = canvas()
draw = ImageDraw.Draw(image)
pill(draw, (106, 112), "STREAM DECK PLUGIN")
image.alpha_composite(Image.open(MEDIA / "app-icon.png"), (111, 303))
text(draw, (467, 309), "Muse Controls", 112, CREAM, True)
text(draw, (473, 481), "Your Muse chats, one key away.", 55, MUTED)
text(draw, (473, 602), "Open  ·  Chat  ·  Dictate  ·  Send", 39, LAVENDER)
footer(draw)
image.convert("RGB").save(MEDIA / "thumbnail.png", optimize=True)

# Gallery 1: all five actions.
image = canvas()
draw = ImageDraw.Draw(image)
pill(draw, (94, 82), "FIVE MUSE ACTIONS")
text(draw, (94, 169), "A key for every part of the conversation", 71, CREAM, True)
for index, (name, label) in enumerate(zip(NAMES, LABELS)):
    card(image, (95 + index * 345, 383), name, label, width=310, height=350)
footer(draw)
image.convert("RGB").save(MEDIA / "gallery-actions.png", optimize=True)

# Gallery 2: dictation and submission.
image = canvas()
draw = ImageDraw.Draw(image)
pill(draw, (94, 82), "HANDS-FREE FLOW")
text(draw, (94, 169), "Speak, finish, send", 83, CREAM, True)
text(draw, (98, 278), "The Dictate key changes to Stop while Muse is recording.", 35, MUTED)
card(image, (230, 415), "dictate", "Dictate", "Tap to start", width=420, height=360)
card(image, (1240, 415), "finish-send", "Finish & Send", "Submit the transcript", width=420, height=360)
draw.line((720, 585, 1150, 585), fill=CORAL, width=10)
draw.polygon([(1150, 585), (1110, 560), (1110, 610)], fill=CORAL)
footer(draw)
image.convert("RGB").save(MEDIA / "gallery-dictation.png", optimize=True)

# Gallery 3: navigation and saved prompts.
image = canvas()
draw = ImageDraw.Draw(image)
pill(draw, (94, 82), "YOUR WORKFLOW")
text(draw, (94, 169), "Start where you want. Send what you need.", 69, CREAM, True)
card(image, (162, 395), "open", "Open Muse", "Main chat", width=420, height=360)
card(image, (750, 395), "side-chat", "New Side Chat", "Fresh conversation", width=420, height=360)
card(image, (1338, 395), "send-prompt", "Saved Prompt", "Set per key", width=420, height=360)
footer(draw)
image.convert("RGB").save(MEDIA / "gallery-workflow.png", optimize=True)

print(f"Created compliant action-list icons and Marketplace media in {MEDIA}")
