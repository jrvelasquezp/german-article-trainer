from __future__ import annotations

import csv
import time
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
import ST7789


# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

WIDTH = 284
HEIGHT = 76

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = BASE_DIR / "data" / "words.csv"
ICON_DIR = BASE_DIR / "assets" / "icons"

# Ajustar según cableado real
SPI_PORT = 0
SPI_CS = 0
DC_PIN = 9
BACKLIGHT_PIN = 13

SPI_SPEED = 40_000_000

# Estos offsets pueden requerir ajuste dependiendo del módulo concreto.
OFFSET_LEFT = 0
OFFSET_TOP = 0


# ------------------------------------------------------------
# Colours
# ------------------------------------------------------------

BG = (8, 14, 21)
FG = (240, 244, 248)

MUTED = (130, 145, 160)
SEPARATOR = (70, 85, 100)

BLUE = (70, 170, 255)
GREEN = (30, 220, 110)
RED = (255, 70, 70)
YELLOW = (255, 215, 60)


# ------------------------------------------------------------
# Fonts
# ------------------------------------------------------------

def load_font(size: int, bold: bool = False):
    candidates = []

    if bold:
        candidates.extend([
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf",
        ])
    else:
        candidates.extend([
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
        ])

    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)

    return ImageFont.load_default()


FONT_SMALL = load_font(10)
FONT_MEDIUM = load_font(13)
FONT_LARGE = load_font(26, bold=True)
FONT_FEEDBACK = load_font(16, bold=True)


# ------------------------------------------------------------
# Data model
# ------------------------------------------------------------

@dataclass
class Word:
    noun: str
    article: str
    icon: str | None = None


def load_words(filename: Path) -> list[Word]:
    words = []

    with filename.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)

        for row in reader:
            icon = row.get("icon", "").strip() or None

            words.append(
                Word(
                    noun=row["noun"].strip(),
                    article=row["article"].strip(),
                    icon=icon,
                )
            )

    return words


# ------------------------------------------------------------
# Display
# ------------------------------------------------------------

def create_display():
    display = ST7789.ST7789(
        height=HEIGHT,
        width=WIDTH,
        rotation=0,
        port=SPI_PORT,
        cs=SPI_CS,
        dc=DC_PIN,
        backlight=BACKLIGHT_PIN,
        spi_speed_hz=SPI_SPEED,
        offset_left=OFFSET_LEFT,
        offset_top=OFFSET_TOP,
    )

    display.begin()

    return display


# ------------------------------------------------------------
# Utility drawing functions
# ------------------------------------------------------------

def draw_progress(draw: ImageDraw.ImageDraw, current: int, total: int):
    draw.text(
        (4, 1),
        f"{current}/{total}",
        font=FONT_SMALL,
        fill=FG
    )

    x1 = 37
    y1 = 4
    x2 = 105
    y2 = 8

    draw.rounded_rectangle(
        (x1, y1, x2, y2),
        radius=2,
        fill=(45, 55, 65)
    )

    fraction = current / max(total, 1)
    filled = int((x2 - x1) * fraction)

    if filled > 0:
        draw.rounded_rectangle(
            (x1, y1, x1 + filled, y2),
            radius=2,
            fill=GREEN
        )


def draw_header(
    draw: ImageDraw.ImageDraw,
    current: int,
    total: int,
):
    draw_progress(draw, current, total)

    draw.text(
        (113, 0),
        "TRAIN",
        font=FONT_SMALL,
        fill=BLUE
    )

    # Status simplificado
    draw.text(
        (243, 0),
        "WiFi",
        font=FONT_SMALL,
        fill=MUTED
    )

    draw.line(
        (3, 12, WIDTH - 4, 12),
        fill=SEPARATOR,
        width=1
    )


def load_icon(word: Word) -> Image.Image | None:
    if not word.icon:
        return None

    path = ICON_DIR / word.icon

    if not path.exists():
        return None

    try:
        icon = Image.open(path).convert("RGBA")
        icon.thumbnail((40, 40))
        return icon
    except Exception:
        return None


# ------------------------------------------------------------
# Main UI states
# ------------------------------------------------------------

def render_question(
    word: Word,
    current: int,
    total: int,
) -> Image.Image:

    image = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(image)

    draw_header(draw, current, total)

    icon = load_icon(word)

    if icon:
        icon_x = 8
        icon_y = 23

        image.paste(
            icon,
            (icon_x, icon_y),
            icon
        )

        noun_x = 57
        noun_width = 100

    else:
        noun_x = 10
        noun_width = 145

    # Sustantivo
    draw.text(
        (noun_x, 26),
        word.noun,
        font=FONT_LARGE,
        fill=FG
    )

    # Separador vertical
    divider_x = noun_x + noun_width

    draw.line(
        (divider_x, 19, divider_x, 68),
        fill=SEPARATOR,
        width=1
    )

    # Pregunta
    draw.text(
        (divider_x + 8, 24),
        "Welcher",
        font=FONT_MEDIUM,
        fill=FG
    )

    draw.text(
        (divider_x + 8, 40),
        "Artikel?",
        font=FONT_MEDIUM,
        fill=FG
    )

    # Hint indicator
    draw.text(
        (259, 24),
        "?",
        font=FONT_FEEDBACK,
        fill=YELLOW
    )

    return image


def render_correct(
    word: Word,
    current: int,
    total: int,
) -> Image.Image:

    image = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(image)

    draw_header(draw, current, total)

    draw.text(
        (12, 29),
        word.noun,
        font=FONT_LARGE,
        fill=FG
    )

    draw.line(
        (145, 19, 145, 68),
        fill=SEPARATOR,
        width=1
    )

    draw.text(
        (158, 24),
        "✓ Richtig!",
        font=FONT_FEEDBACK,
        fill=GREEN
    )

    draw.text(
        (158, 47),
        f"{word.article} {word.noun}",
        font=FONT_MEDIUM,
        fill=FG
    )

    return image


def render_incorrect(
    word: Word,
    current: int,
    total: int,
) -> Image.Image:

    image = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(image)

    draw_header(draw, current, total)

    draw.text(
        (12, 29),
        word.noun,
        font=FONT_LARGE,
        fill=FG
    )

    draw.line(
        (145, 19, 145, 68),
        fill=SEPARATOR,
        width=1
    )

    draw.text(
        (158, 24),
        "✕ Falsch",
        font=FONT_FEEDBACK,
        fill=RED
    )

    draw.text(
        (158, 47),
        f"Richtig: {word.article}",
        font=FONT_MEDIUM,
        fill=FG
    )

    return image


def render_hint(
    word: Word,
    current: int,
    total: int,
) -> Image.Image:

    image = Image.new("RGB", (WIDTH, HEIGHT), BG)
    draw = ImageDraw.Draw(image)

    draw_header(draw, current, total)

    draw.text(
        (10, 28),
        word.noun,
        font=FONT_LARGE,
        fill=FG
    )

    draw.line(
        (145, 19, 145, 68),
        fill=SEPARATOR,
        width=1
    )

    draw.text(
        (158, 20),
        "TIPP",
        font=FONT_SMALL,
        fill=YELLOW
    )

    draw.text(
        (158, 37),
        "Artikel merken",
        font=FONT_MEDIUM,
        fill=FG
    )

    draw.text(
        (158, 54),
        "oder Regel nutzen",
        font=FONT_SMALL,
        fill=MUTED
    )

    return image


# ------------------------------------------------------------
# Demo
# ------------------------------------------------------------

def main():
    words = load_words(DATA_FILE)

    if not words:
        raise RuntimeError("No words found.")

    display = create_display()

    word = words[0]

    states = [
        render_question(word, 1, len(words)),
        render_correct(word, 1, len(words)),
        render_incorrect(word, 1, len(words)),
        render_hint(word, 1, len(words)),
    ]

    try:
        while True:
            for state in states:
                display.display(state)
                time.sleep(2)

    except KeyboardInterrupt:
        blank = Image.new("RGB", (WIDTH, HEIGHT), BG)
        display.display(blank)


if __name__ == "__main__":
    main()
