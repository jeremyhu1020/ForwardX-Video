import struct
import zlib
import os


def make_png(width, height, r, g, b):
    """生成合法的纯色 RGB PNG 文件（无 alpha 通道，color type=2）"""

    def make_chunk(chunk_type, data):
        """构造一个 PNG chunk：长度 + 类型 + 数据 + CRC"""
        chunk_len = struct.pack(">I", len(data))
        crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
        return chunk_len + chunk_type + data + struct.pack(">I", crc)

    # PNG 文件签名
    signature = b"\x89PNG\r\n\x1a\n"

    # IHDR chunk: width(4) height(4) bit_depth(1) color_type(1) compression(1) filter(1) interlace(1)
    # color_type=2 -> RGB (每像素 3 字节，无 alpha)
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    ihdr = make_chunk(b"IHDR", ihdr_data)

    # IDAT chunk: 每行前置 filter byte=0，然后 RGB * width
    raw_rows = b""
    row_pixels = bytes([r, g, b] * width)
    for _ in range(height):
        raw_rows += b"\x00" + row_pixels  # filter type 0 = None

    idat = make_chunk(b"IDAT", zlib.compress(raw_rows, 9))

    # IEND chunk
    iend = make_chunk(b"IEND", b"")

    return signature + ihdr + idat + iend


# ForwardX 品牌蓝色 #1A73E8 -> RGB(26, 115, 232)
R, G, B = 26, 115, 232

icons = [
    ("mipmap-mdpi",    48,  48),
    ("mipmap-hdpi",    72,  72),
    ("mipmap-xhdpi",   96,  96),
    ("mipmap-xxhdpi",  144, 144),
    ("mipmap-xxxhdpi", 192, 192),
]

# 脚本在项目根目录运行
base = os.path.join("android", "app", "src", "main", "res")

for folder, w, h in icons:
    dir_path = os.path.join(base, folder)
    os.makedirs(dir_path, exist_ok=True)
    file_path = os.path.join(dir_path, "ic_launcher.png")
    with open(file_path, "wb") as f:
        f.write(make_png(w, h, R, G, B))
    print(f"Created {file_path} ({w}x{h})")

print("All icons generated successfully!")
