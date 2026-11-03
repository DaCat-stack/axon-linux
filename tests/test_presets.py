"""Тесты логики окна приветствия AXON (без Qt, запускаются и на маке)."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "pkgsrc/axon-welcome/usr/lib/axon-welcome"))
from axon_welcome import presets  # noqa: E402


class PresetsTest(unittest.TestCase):
    def test_three_presets_in_order(self):
        self.assertEqual([p["id"] for p in presets.PRESETS], ["a", "b", "c"])

    def test_preset_titles(self):
        self.assertEqual([p["title"] for p in presets.PRESETS],
                         ["Как Windows 11", "Как на маке", "Как в Ubuntu"])

    def test_preview_paths_point_to_lookandfeel(self):
        self.assertEqual(presets.PRESETS[1]["preview"],
                         "/usr/share/plasma/look-and-feel/org.axon.desktop.b/contents/previews/preview.png")

    def test_apply_command(self):
        self.assertEqual(presets.apply_command("b"),
                         ["plasma-apply-lookandfeel", "--apply", "org.axon.desktop.b", "--resetLayout"])

    def test_apply_command_unknown_id(self):
        with self.assertRaises(ValueError):
            presets.apply_command("x")

    def test_autostart_until_marked(self):
        with tempfile.TemporaryDirectory() as home:
            home = Path(home)
            self.assertTrue(presets.should_autostart(home))
            presets.mark_done(home)
            self.assertFalse(presets.should_autostart(home))

    def test_marker_location(self):
        self.assertEqual(presets.marker_path(Path("/home/x")), Path("/home/x/.config/axon-welcome-done"))

    def test_mark_done_creates_config_dir(self):
        with tempfile.TemporaryDirectory() as home:
            presets.mark_done(Path(home))
            self.assertTrue((Path(home) / ".config/axon-welcome-done").exists())


if __name__ == "__main__":
    unittest.main()
