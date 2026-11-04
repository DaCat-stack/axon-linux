"""Пресеты рабочего стола AXON и логика автозапуска окна приветствия. Без Qt."""
from pathlib import Path

LNF = "/usr/share/plasma/look-and-feel"
PRESETS = [
    {"id": i, "package": f"org.axon.desktop.{i}", "title": t,
     "preview": f"{LNF}/org.axon.desktop.{i}/contents/previews/preview.png"}
    for i, t in (("a", "Как Windows 11"), ("b", "Как на маке"), ("c", "Как в Ubuntu"))
]
_BY_ID = {p["id"]: p for p in PRESETS}


def apply_command(preset_id: str) -> list[str]:
    if preset_id not in _BY_ID:
        raise ValueError(f"нет пресета {preset_id!r}")
    return ["plasma-apply-lookandfeel", "--apply", _BY_ID[preset_id]["package"], "--resetLayout"]


def splash_off_commands() -> list[list[str]]:
    """После применения пресета KDE включает заставку в ~/.config/kdedefaults — выключаем у пользователя."""
    return [["kwriteconfig6", "--file", "ksplashrc", "--group", "KSplash", "--key", key, value]
            for key, value in (("Engine", "none"), ("Theme", "None"))]


def marker_path(home: Path) -> Path:
    return home / ".config" / "axon-welcome-done"


def should_autostart(home: Path) -> bool:
    return not marker_path(home).exists()


def mark_done(home: Path) -> None:
    marker = marker_path(home)
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.touch()
