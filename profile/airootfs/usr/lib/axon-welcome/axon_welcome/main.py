"""Окно приветствия AXON: «Выбери свой стиль» — три пресета рабочего стола.

axon-welcome              — открыть окно
axon-welcome --autostart  — открыть, только если стиль ещё не выбирали
"""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from axon_welcome import presets  # noqa: E402

HOME = Path.home()


def main() -> int:
    if "--autostart" in sys.argv and not presets.should_autostart(HOME):
        return 0

    from PySide6.QtCore import QObject, Slot
    from PySide6.QtGui import QGuiApplication, QIcon
    from PySide6.QtQml import QQmlApplicationEngine

    class Backend(QObject):
        @Slot(str)
        def apply(self, preset_id: str) -> None:
            subprocess.run(presets.apply_command(preset_id), check=False)
            presets.mark_done(HOME)
            app.quit()

        @Slot()
        def later(self) -> None:
            presets.mark_done(HOME)
            app.quit()

    app = QGuiApplication(sys.argv)
    app.setApplicationName("AXON")
    app.setDesktopFileName("axon-welcome")
    app.setWindowIcon(QIcon("/usr/share/pixmaps/axon-logo.png"))

    backend = Backend()
    engine = QQmlApplicationEngine()
    engine.setInitialProperties({"backend": backend, "presets": presets.PRESETS})
    engine.load(str(Path(__file__).with_name("Main.qml")))
    if not engine.rootObjects():
        return 1
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
