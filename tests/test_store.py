"""Тесты логики Магазина AXON (без Qt, запускаются и на маке)."""
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "pkgsrc/axon-store/usr/lib/axon-store"))
from axon_store import catalog  # noqa: E402

CATALOG = ROOT / "pkgsrc/axon-store/usr/share/axon-store/catalog.json"


class CatalogFileTest(unittest.TestCase):
    def setUp(self):
        self.cat = catalog.load(CATALOG)

    def test_sections_in_order(self):
        self.assertEqual([s["id"] for s in self.cat["sections"]],
                         ["themes", "icons", "cursors", "fx", "tiling", "widgets", "mon", "wall", "term"])

    def test_first_stage_items(self):
        ids = {i["id"] for i in self.cat["items"]}
        self.assertTrue({"sweet", "candy", "bibata", "kzones"} <= ids)

    def test_every_item_is_complete(self):
        sections = {s["id"] for s in self.cat["sections"]}
        for it in self.cat["items"]:
            with self.subTest(it=it["id"]):
                self.assertIn(it["section"], sections)
                self.assertTrue(it["packages"])
                self.assertIn(it["apply"]["type"], catalog.APPLY_TYPES)
                self.assertTrue(it["name"] and it["author"])

    def test_store_packages_listed_for_ci(self):
        # всё, что магазин ставит, CI должен собрать в репозиторий AXON
        listed = {ln.split()[0] for ln in (ROOT / "aur/store.txt").read_text().splitlines()
                  if ln.strip() and not ln.lstrip().startswith("#")}
        for it in self.cat["items"]:
            for p in it["packages"]:
                self.assertIn(p, listed, f"{p} нет в aur/store.txt")


class CommandsTest(unittest.TestCase):
    def test_install_uses_pkexec_pacman(self):
        it = {"packages": ["candy-icons-git"]}
        self.assertEqual(catalog.install_command(it),
                         ["pkexec", "pacman", "-S", "--noconfirm", "--needed", "candy-icons-git"])

    def test_remove_command(self):
        it = {"packages": ["candy-icons-git"]}
        self.assertEqual(catalog.remove_command(it), ["pkexec", "pacman", "-Rns", "--noconfirm", "candy-icons-git"])

    def test_apply_lookandfeel_keeps_panels_and_turns_splash_off(self):
        cmds = catalog.apply_commands({"apply": {"type": "lookandfeel", "value": "Sweet"}})
        self.assertEqual(cmds[0], ["plasma-apply-lookandfeel", "--apply", "Sweet"])
        self.assertNotIn("--resetLayout", cmds[0])
        self.assertIn(["kwriteconfig6", "--file", "ksplashrc", "--group", "KSplash", "--key", "Engine", "none"], cmds)

    def test_apply_icons(self):
        self.assertEqual(catalog.apply_commands({"apply": {"type": "icons", "value": "candy-icons"}}),
                         [["/usr/lib/plasma-changeicons", "candy-icons"]])

    def test_apply_cursor(self):
        self.assertEqual(catalog.apply_commands({"apply": {"type": "cursor", "value": "Bibata-Modern-Ice"}}),
                         [["plasma-apply-cursortheme", "Bibata-Modern-Ice"]])

    def test_apply_kwin_script(self):
        self.assertEqual(catalog.apply_commands({"apply": {"type": "kwin-script", "value": "kzones"}}), [
            ["kwriteconfig6", "--file", "kwinrc", "--group", "Plugins", "--key", "kzonesEnabled", "true"],
            ["qdbus6", "org.kde.KWin", "/KWin", "reconfigure"],
        ])

    def test_unknown_apply_type(self):
        with self.assertRaises(ValueError):
            catalog.apply_commands({"apply": {"type": "magic", "value": "x"}})


class SnapshotTest(unittest.TestCase):
    """«Вернуть как было»: перед первым применением запоминаем текущее оформление."""

    def test_snapshot_saved_once(self):
        with tempfile.TemporaryDirectory() as home:
            home = Path(home)
            catalog.save_snapshot(home, {"lookandfeel": "org.axon.desktop.a", "icons": "Papirus-Dark",
                                         "cursor": "breeze_cursors"})
            catalog.save_snapshot(home, {"lookandfeel": "Sweet", "icons": "candy-icons", "cursor": "x"})
            self.assertEqual(catalog.load_snapshot(home)["icons"], "Papirus-Dark")

    def test_revert_commands(self):
        snap = {"lookandfeel": "org.axon.desktop.a", "icons": "Papirus-Dark", "cursor": "breeze_cursors",
                "kwin_scripts": ["kzones"]}
        cmds = catalog.revert_commands(snap)
        self.assertIn(["plasma-apply-lookandfeel", "--apply", "org.axon.desktop.a"], cmds)
        self.assertIn(["/usr/lib/plasma-changeicons", "Papirus-Dark"], cmds)
        self.assertIn(["plasma-apply-cursortheme", "breeze_cursors"], cmds)
        self.assertIn(["kwriteconfig6", "--file", "kwinrc", "--group", "Plugins", "--key", "kzonesEnabled", "false"], cmds)

    def test_clear_snapshot_after_revert(self):
        with tempfile.TemporaryDirectory() as home:
            home = Path(home)
            catalog.save_snapshot(home, {"icons": "Papirus-Dark"})
            catalog.clear_snapshot(home)
            self.assertIsNone(catalog.load_snapshot(home))

    def test_track_enabled_kwin_scripts(self):
        with tempfile.TemporaryDirectory() as home:
            home = Path(home)
            catalog.save_snapshot(home, {"icons": "Papirus-Dark"})
            catalog.note_kwin_script(home, "kzones")
            catalog.note_kwin_script(home, "kzones")
            self.assertEqual(catalog.load_snapshot(home)["kwin_scripts"], ["kzones"])


class StateTest(unittest.TestCase):
    def test_item_installed_only_if_all_packages_installed(self):
        it = {"packages": ["a", "b"]}
        self.assertTrue(catalog.is_installed(it, {"a", "b", "c"}))
        self.assertFalse(catalog.is_installed(it, {"a"}))

    def test_broken_items_hidden_by_compat(self):
        items = [{"id": "sweet"}, {"id": "candy"}]
        compat = {"items": {"sweet": {"ok": False}, "candy": {"ok": True}}}
        self.assertEqual([i["id"] for i in catalog.visible_items(items, compat)], ["candy"])

    def test_no_compat_file_shows_everything(self):
        items = [{"id": "sweet"}]
        self.assertEqual(catalog.visible_items(items, None), items)


if __name__ == "__main__":
    unittest.main()
