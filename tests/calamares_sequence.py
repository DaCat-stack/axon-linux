"""Проверяет порядок шагов Calamares в settings.conf (без PyYAML: простой разбор списка)."""
import re
import sys

SHOW1 = ["welcome", "locale", "keyboard", "partition", "users", "summary"]
EXEC = ["partition", "mount", "unpackfs", "machineid", "fstab", "locale", "keyboard", "localecfg",
        "users", "displaymanager", "networkcfg", "hwclock", "services-systemd", "shellprocess@cleanup",
        "initcpiocfg", "shellprocess@snapshots", "initcpio", "grubcfg", "bootloader", "umount"]
SHOW2 = ["finished"]

text = open(sys.argv[1]).read()
seq = text.split("\nsequence:", 1)[1]
blocks = re.findall(r"- (show|exec):\n((?:\s+- \S+\n)+)", seq)
got = [(kind, re.findall(r"- (\S+)", body)) for kind, body in blocks]
want = [("show", SHOW1), ("exec", EXEC), ("show", SHOW2)]
if got != want:
    sys.exit(f"ожидалось {want}\nполучено {got}")
