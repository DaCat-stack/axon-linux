"""Логика Магазина AXON без Qt: каталог, команды установки/применения, «Вернуть как было»."""
import json
from pathlib import Path

APPLY_TYPES = {"lookandfeel", "icons", "cursor", "kwin-script", "kwin-effect"}

SPLASH_OFF = [["kwriteconfig6", "--file", "ksplashrc", "--group", "KSplash", "--key", k, v]
              for k, v in (("Engine", "none"), ("Theme", "None"))]
KWIN_RECONFIGURE = ["qdbus6", "org.kde.KWin", "/KWin", "reconfigure"]


def load(path) -> dict:
    return json.loads(Path(path).read_text(encoding="utf-8"))


def install_command(item: dict) -> list[str]:
    return ["pkexec", "pacman", "-S", "--noconfirm", "--needed", *item["packages"]]


def remove_command(item: dict) -> list[str]:
    return ["pkexec", "pacman", "-Rns", "--noconfirm", *item["packages"]]


def _kwin_plugin(name: str, enabled: bool) -> list[list[str]]:
    return [["kwriteconfig6", "--file", "kwinrc", "--group", "Plugins", "--key", f"{name}Enabled",
             "true" if enabled else "false"], KWIN_RECONFIGURE]


def apply_commands(item: dict) -> list[list[str]]:
    kind, value = item["apply"]["type"], item["apply"]["value"]
    if kind == "lookandfeel":
        # без --resetLayout: панели пользователя не трогаем; темы часто включают свою заставку — выключаем
        return [["plasma-apply-lookandfeel", "--apply", value], *SPLASH_OFF]
    if kind == "icons":
        return [["/usr/lib/plasma-changeicons", value]]
    if kind == "cursor":
        return [["plasma-apply-cursortheme", value]]
    if kind in ("kwin-script", "kwin-effect"):
        return _kwin_plugin(value, True)
    raise ValueError(f"неизвестный тип применения: {kind}")


# --- «Вернуть как было» -------------------------------------------------------

def snapshot_path(home: Path) -> Path:
    return home / ".config" / "axon-store" / "before.json"


def load_snapshot(home: Path):
    p = snapshot_path(home)
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else None


def save_snapshot(home: Path, current: dict) -> None:
    """Запоминает оформление только перед ПЕРВЫМ применением — потом не перезаписывает."""
    p = snapshot_path(home)
    if p.exists():
        return
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps({**current, "kwin_scripts": []}, ensure_ascii=False, indent=2), encoding="utf-8")


def note_kwin_script(home: Path, name: str) -> None:
    snap = load_snapshot(home)
    if snap is None:
        return
    if name not in snap.setdefault("kwin_scripts", []):
        snap["kwin_scripts"].append(name)
        snapshot_path(home).write_text(json.dumps(snap, ensure_ascii=False, indent=2), encoding="utf-8")


def clear_snapshot(home: Path) -> None:
    snapshot_path(home).unlink(missing_ok=True)


def revert_commands(snap: dict) -> list[list[str]]:
    cmds = []
    if snap.get("lookandfeel"):
        cmds += [["plasma-apply-lookandfeel", "--apply", snap["lookandfeel"]], *SPLASH_OFF]
    if snap.get("icons"):
        cmds.append(["/usr/lib/plasma-changeicons", snap["icons"]])
    if snap.get("cursor"):
        cmds.append(["plasma-apply-cursortheme", snap["cursor"]])
    for name in snap.get("kwin_scripts", []):
        cmds += _kwin_plugin(name, False)
    return cmds


# --- состояние -----------------------------------------------------------------

def is_installed(item: dict, installed: set) -> bool:
    return all(p in installed for p in item["packages"])


def visible_items(items: list, compat) -> list:
    """Вещи, которые ночная проверка пометила сломанными, в магазине не показываем."""
    if not compat:
        return items
    status = compat.get("items", {})
    return [i for i in items if status.get(i["id"], {}).get("ok", True)]
