import struct
import zlib
import os


def make_png(size, r, g, b):
    """生成指定尺寸和颜色的纯色 PNG"""
    def chunk(name, data):
        c = zlib.crc32(name + data) & 0xffffffff
        return struct.pack(">I", len(data)) + name + data + struct.pack(">I", c)

    raw = b"".join(b"\x00" + bytes([r, g, b, 255] * size) for _ in range(size))
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw))
    png += chunk(b"IEND", b"")
    return png


# ForwardX 品牌蓝色 #1A73E8 -> RGB(26, 115, 232)
icons = [
    ("mipmap-mdpi",    48),
    ("mipmap-hdpi",    72),
    ("mipmap-xhdpi",   96),
    ("mipmap-xxhdpi",  144),
    ("mipmap-xxxhdpi", 192),
]

base = "android/app/src/main/res"
for folder, size in icons:
    path = os.path.join(base, folder)
    os.makedirs(path, exist_ok=True)
    with open(os.path.join(path, "ic_launcher.png"), "wb") as f:
        f.write(make_png(size, 26, 115, 232))
    print(f"Created {path}/ic_launcher.png ({size}x{size})")

print("All icons generated successfully!")
