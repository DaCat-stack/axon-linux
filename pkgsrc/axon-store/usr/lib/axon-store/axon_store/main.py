"""Магазин AXON: проверенное оформление в один клик."""
import json
import os
import subprocess
import sys
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from axon_store import catalog  # noqa: E402

HOME = Path.home()
CATALOG = Path(os.environ.get("AXON_STORE_CATALOG", "/usr/share/axon-store/catalog.json"))
COMPAT_URL = "https://dacat-stack.github.io/axon-repo/compat.json"


def installed_packages() -> set:
    out = subprocess.run(["pacman", "-Qq"], capture_output=True, text=True).stdout
    return set(out.split())


def read_kde(file: str, group: str, key: str) -> str:
    return subprocess.run(["kreadconfig6", "--file", file, "--group", group, "--key", key],
                          capture_output=True, text=True).stdout.strip()


def current_look() -> dict:
    return {"lookandfeel": read_kde("kdeglobals", "KDE", "LookAndFeelPackage"),
            "icons": read_kde("kdeglobals", "Icons", "Theme"),
            "cursor": read_kde("kcminputrc", "Mouse", "cursorTheme")}


def fetch_compat():
    try:
        out = subprocess.run(["curl", "-fsSL", "--max-time", "5", COMPAT_URL], capture_output=True, text=True)
        return json.loads(out.stdout) if out.returncode == 0 else None
    except (OSError, ValueError):
        return None


def run_all(cmds) -> bool:
    ok = True
    for c in cmds:
        ok = subprocess.run(c).returncode == 0 and ok
    return ok


def main() -> int:
    from PySide6.QtCore import Property, QObject, Signal, Slot
    from PySide6.QtGui import QGuiApplication, QIcon
    from PySide6.QtQml import QQmlApplicationEngine

    class Store(QObject):
        changed = Signal()
        message = Signal(str)

        def __init__(self):
            super().__init__()
            self._cat = catalog.load(CATALOG)
            self._compat = None
            self._installed = installed_packages()
            self._busy = ""
            threading.Thread(target=self._load_compat, daemon=True).start()

        def _load_compat(self):
            self._compat = fetch_compat()
            self.changed.emit()

        @Property("QVariantList", notify=changed)
        def sections(self):
            return self._cat["sections"]

        @Property("QVariantList", notify=changed)
        def items(self):
            res = []
            for it in catalog.visible_items(self._cat["items"], self._compat):
                res.append({**it, "installed": catalog.is_installed(it, self._installed),
                            "busy": self._busy == it["id"]})
            return res

        @Property(bool, notify=changed)
        def checked(self):
            return self._compat is not None

        @Property(str, notify=changed)
        def plasmaVersion(self):
            return (self._compat or {}).get("plasma", "")

        def _item(self, item_id):
            return next(i for i in self._cat["items"] if i["id"] == item_id)

        def _job(self, item_id, work, done_text):
            def go():
                self._busy = item_id
                self.changed.emit()
                ok = work()
                self._installed = installed_packages()
                self._busy = ""
                self.changed.emit()
                self.message.emit(done_text if ok else "Не получилось — подробности в терминале")
            threading.Thread(target=go, daemon=True).start()

        @Slot(str)
        def install(self, item_id):
            it = self._item(item_id)
            self._job(item_id, lambda: run_all([catalog.install_command(it)]), f"«{it['name']}» установлено")

        @Slot(str)
        def remove(self, item_id):
            it = self._item(item_id)
            self._job(item_id, lambda: run_all([catalog.remove_command(it)]), f"«{it['name']}» удалено")

        @Slot(str)
        def apply(self, item_id):
            it = self._item(item_id)

            def work():
                catalog.save_snapshot(HOME, current_look())
                if it["apply"]["type"] in ("kwin-script", "kwin-effect"):
                    catalog.note_kwin_script(HOME, it["apply"]["value"])
                return run_all(catalog.apply_commands(it))
            self._job(item_id, work, f"«{it['name']}» применено")

        @Slot()
        def revert(self):
            snap = catalog.load_snapshot(HOME)
            if not snap:
                self.message.emit("Оформление ещё не меняли через магазин — возвращать нечего")
                return

            def work():
                ok = run_all(catalog.revert_commands(snap))
                if ok:
                    catalog.clear_snapshot(HOME)
                return ok
            self._job("", work, "Оформление возвращено как было")

    app = QGuiApplication(sys.argv)
    app.setApplicationName("Магазин AXON")
    app.setDesktopFileName("axon-store")
    app.setWindowIcon(QIcon("/usr/share/pixmaps/axon-logo.png"))
    store = Store()
    engine = QQmlApplicationEngine()
    engine.setInitialProperties({"store": store})
    engine.load(str(Path(__file__).with_name("Main.qml")))
    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
