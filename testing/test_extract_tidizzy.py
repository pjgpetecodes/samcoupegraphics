"""Synthetic disk fixtures for the tutorial sprite extractor."""

import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "extract_tidizzy",
    Path(__file__).resolve().parents[1] / ".vscode" / "extract_tidizzy.py",
)
extract = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(extract)


def disk_fixture(entry_number=0, cycle=False):
    disk = bytearray(extract.DISK_SIZE)
    track = entry_number // 20
    sector = (entry_number % 20) // 2
    directory = (track * 2 * 10 + sector) * 512 + (entry_number % 2) * 256
    disk[directory] = 19
    disk[directory + 1 : directory + 11] = b"AUTOmain.O"
    disk[directory + 13 : directory + 15] = bytes((4, 1))
    start = 4 * 2 * 10 * 512
    disk[start : start + 9] = bytes(9)
    disk[start + 9 : start + 13] = b"test"
    if cycle:
        disk[start + 510 : start + 512] = bytes((4, 1))
    return bytes(disk)


class ExtractTests(unittest.TestCase):
    def test_selected_graphics_reject_invalid_identifier_and_pointer(self):
        payload = bytearray(extract.FILE_LENGTH)
        for number in (-1, 100000):
            with self.assertRaisesRegex(ValueError, "identifier"):
                extract.read_graphic(payload, number)
        struct.pack_into("<BH", payload, extract.GRAPHICS_TABLE, 12, 0)
        with self.assertRaisesRegex(ValueError, "pointer"):
            extract.read_graphic(payload, 0)

    def test_selected_graphics_export_contains_only_requested_pixels_and_provenance(self):
        payload = bytearray(extract.FILE_LENGTH)
        struct.pack_into("<BH", payload, extract.GRAPHICS_TABLE + 215 * 3, 2, 0x300)
        payload[0x14300 : 0x14304] = bytes((2, 1, 0x12, 0x30))
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / "source.dsk"
            source.write_bytes(b"synthetic")
            output = Path(temp) / "graphics"
            with patch.object(extract, "known_payload", return_value=payload):
                extract.export_graphics(source, output, [215])
            self.assertEqual((output / "image-215.bin").read_bytes(), bytes((2, 1, 0x12, 0x30)))
            self.assertEqual(sorted(path.name for path in output.iterdir()),
                             ["image-215.bin", "provenance.json"])

    def test_collision_runs_preserve_partial_nibbles_and_full_screen_fill(self):
        source = bytes(6144) + bytes((15, 15, 240, 255, 0)) + bytes(0x6000 - 6149)
        runs = extract.collision_runs(source)
        self.assertEqual(runs[:5], [(6144, 0), (2, 15), (1, 240), (1, 255), (18428, 0)])
        self.assertEqual(b"".join(bytes((value,)) * count for count, value in runs), source)
        self.assertEqual(extract.collision_runs(bytes(0x6000)), [(0x6000, 0)])

    def test_collision_runs_reject_wrong_size_and_non_solidity_pixels(self):
        for source in (bytes(1), bytes((0x12,)) + bytes(0x5FFF)):
            with self.subTest(length=len(source)):
                with self.assertRaisesRegex(ValueError, "empty/solid"):
                    extract.collision_runs(source)

    def test_clut_channel_weights_and_shared_brightness(self):
        for value, expected in (
            (0x01, (0, 0, 72)),
            (0x10, (0, 0, 145)),
            (0x02, (72, 0, 0)),
            (0x20, (145, 0, 0)),
            (0x04, (0, 72, 0)),
            (0x40, (0, 145, 0)),
            (0x08, (36, 36, 36)),
            (0x7F, (255, 255, 255)),
        ):
            with self.subTest(value=value):
                self.assertEqual(extract.clut_rgb(value), expected)

    def test_reads_directory_entry_on_later_track(self):
        self.assertEqual(extract.read_file(disk_fixture(63), "AUTOmain.O")[:4], b"test")

    def test_rejects_file_chain_cycle(self):
        with self.assertRaisesRegex(ValueError, "Cycle"):
            extract.read_file(disk_fixture(cycle=True), "AUTOmain.O")

    def test_rejects_invalid_sector_and_truncated_disk(self):
        with self.assertRaisesRegex(ValueError, "Invalid sector"):
            extract.sector(disk_fixture(), 4, 11)
        with self.assertRaisesRegex(ValueError, "Invalid sector"):
            extract.sector(disk_fixture(), 256, 1)
        with self.assertRaisesRegex(ValueError, "raw MGT"):
            extract.read_file(disk_fixture()[:-1], "AUTOmain.O")

    def test_rejects_unsupported_disk_before_writing(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / "source.dsk"
            source.write_bytes(disk_fixture())
            output = Path(temp) / "output"
            with self.assertRaisesRegex(ValueError, "SHA-256"):
                extract.export_sprites(source, output)
            self.assertFalse(output.exists())

    def test_existing_destination_is_unchanged(self):
        with tempfile.TemporaryDirectory() as temp:
            source = Path(temp) / "source.dsk"
            source.write_bytes(b"synthetic")
            output = Path(temp) / "output"
            output.mkdir()
            asset = output / "tidizzy_all.asm"
            asset.write_text("user-edited data", encoding="ascii")
            with patch.object(extract, "extract_sprites", return_value=([], [], 0)):
                with self.assertRaises(FileExistsError):
                    extract.export_sprites(source, output)
            self.assertEqual(asset.read_text(encoding="ascii"), "user-edited data")

    def test_decodes_room_draw_flags_and_banked_graphics_pointer(self):
        payload = bytearray(extract.FILE_LENGTH)
        struct.pack_into("<HH", payload, extract.ROOM_TABLE + 77 * 2, 0x200, 0x207)
        payload[extract.ROOM_TABLE + 0x200] = 1
        struct.pack_into("<BBhh", payload, extract.ROOM_TABLE + 0x201, 0, 128, -1, 49)
        struct.pack_into("<BH", payload, extract.GRAPHICS_TABLE, 2, 0x300)
        payload[0x14300 : 0x14306] = bytes((2, 2, 0x12, 0x30, 0x04, 0x50))
        with patch.object(extract, "known_payload", return_value=payload):
            with patch.object(extract, "TUTORIAL_ROOMS", (77,)):
                _, rooms, graphics = extract.extract_rooms(b"synthetic")
        self.assertEqual(rooms[0]["entries"], [{
            "image": 0, "collision": True, "x_bytes": -1, "y": 49, "water": False,
        }])
        self.assertEqual(graphics[0]["offset"], 0x14300)
        self.assertEqual(graphics[0]["pixels"], bytes((0x12, 0x30, 0x04, 0x50)))

    def test_rejects_malformed_room_list_before_export(self):
        payload = bytearray(extract.FILE_LENGTH)
        struct.pack_into("<HH", payload, extract.ROOM_TABLE + 77 * 2, 0x200, 0x209)
        payload[extract.ROOM_TABLE + 0x200] = 1
        with patch.object(extract, "known_payload", return_value=payload):
            with self.assertRaisesRegex(ValueError, "draw-list length"):
                extract.extract_rooms(b"synthetic")

    def test_room_rendering_transparency_clipping_and_separate_collision(self):
        graphics = {
            1: {"width_bytes": 2, "height": 2, "pixels": bytes((0x12, 0x34, 0x56, 0x78))},
            2: {"width_bytes": 1, "height": 1, "pixels": bytes((0x90,))},
        }
        entries = [
            {"image": 1, "collision": True, "x_bytes": -1, "y": 47, "water": False},
            {"image": 2, "collision": False, "x_bytes": 0, "y": 48, "water": False},
        ]
        pixels, collision = extract.render_room(entries, graphics)
        self.assertEqual(pixels[48 * 128], 0x98)
        self.assertEqual(collision[48 * 128], 0xFF)
        self.assertEqual(pixels[:48 * 128], bytes(48 * 128))
        self.assertEqual(pixels[48 * 128 + 1:], bytes(0x6000 - 48 * 128 - 1))

    def test_draw_records_clip_source_and_destination_without_changing_stride(self):
        graphics = {6: {"width_bytes": 4, "height": 4}}
        entries = [
            {"image": 6, "x_bytes": -2, "y": 46, "water": False},
            {"image": 6, "x_bytes": 127, "y": 191, "water": True},
            {"image": 6, "x_bytes": 128, "y": 60, "water": False},
        ]
        self.assertEqual(extract.clipped_draws(entries, graphics), [
            {"image": 6, "source_skip": 12, "destination": 48 * 128,
             "width": 2, "height": 2, "stride": 4},
            {"image": 6, "source_skip": 2, "destination": 0x5FFF,
             "width": 1, "height": 1, "stride": 4},
        ])


if __name__ == "__main__":
    unittest.main()
