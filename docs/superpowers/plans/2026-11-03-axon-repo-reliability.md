# AXON Repo & Reliability Implementation Plan (план A из двух)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Signed AXON pacman repository on GitHub Pages that installed systems update from, with AXON's own files moved into packages, btrfs snapshots + rollback in the boot menu, and a «обновления не приходят» warning.

**Architecture:** PKGBUILDs live in `packages/` of the private `axon-linux` repo. A GitHub Actions workflow builds them in an Arch container, signs them with a CI-only GPG subkey, and publishes `axon-testing/` and `axon/` channels to the `gh-pages` branch of the public `DaCat-stack/axon-repo` (one orphan commit, force-pushed through a deploy key — Pages swaps the whole site at once, so pacman never sees a half-updated db). The ISO build compiles the same PKGBUILDs into its local repo, so ISO builds never depend on publishing.

**Tech Stack:** makepkg/repo-add/gpg, GitHub Actions, GitHub Pages, Calamares 3.4 (partition/mount/shellprocess), snapper + snap-pac + grub-btrfs, systemd user timer + notify-send.

**Spec:** `docs/superpowers/specs/2026-11-03-axon-repo-store-design.md`. План Б (подборка Магазина, ночная проверка совместимости, приложение «Магазин AXON», «Загрузить новые…») — отдельный план после этого.

## Global Constraints

- Public repo: `DaCat-stack/axon-repo`; site `https://dacat-stack.github.io/axon-repo/`; pacman servers `…/axon-repo/axon/$arch` and `…/axon-repo/axon-testing/$arch`.
- Every package and every db is signed; `[axon]` in pacman.conf has `SigLevel = Required DatabaseRequired` and sits before `[core]`. Package names all start with `axon-`.
- Master key stays on the owner's Mac (GnuPG, passphrase in macOS Keychain); CI gets only the signing subkey (`AXON_SIGN_SUBKEY` secret).
- Promotion `axon-testing` → `axon` is per package, only after the e2e install test passes.
- Packages never write into `/home`; system defaults only in `/etc/xdg`, `/usr/share`, `/etc/*.d` drop-ins not owned by other packages.
- btrfs is the default filesystem in the installer; subvolumes `@ / @home / @cache / @log / @snapshots`; snapshots only of `@`; keep 10 number + 5 daily.
- Staleness warning when `/var/lib/pacman/sync/axon.db` is older than 14 days, text «Обновления AXON не приходят».

## Review Focus

- **Owner picks ext4/xfs in the installer:** no snapper/grub-btrfs services may fail at boot → Task 6 cleanup test runs the btrfs branch only on btrfs (`tests/test_cleanup_fs.sh`).
- **Booting a read-only snapshot:** SDDM/Plasma must start (overlay) → Task 6 asserts `grub-btrfs-overlayfs` is in HOOKS after initcpiocfg.
- **Package file conflicts with Arch packages** (`/etc/plymouth/plymouthd.conf` belongs to `plymouth`) → Task 3 static check: no package ships a path owned by an official package (list in test).
- **Key/db mismatch during publish** → Task 4 e2e test syncs from the published site after every deploy and fails the workflow on a signature error.
- **Live-only files reaching the installed system** after the move into packages (autologin conf) → Task 3 keeps live autologin in a separate `zz-live.conf` and cleanup test asserts its removal.

---

### Task 1: Ключи и публичный репозиторий (нужен владелец на 2 минуты)

**Files:** Create `packages/axon-keyring/axon.gpg` (public key), `docs/keys.md` (fingerprints, how to rotate).

**Interfaces:** Produces secrets in `DaCat-stack/axon-linux`: `AXON_SIGN_SUBKEY` (armored secret subkey, no passphrase), `AXON_REPO_DEPLOY_KEY` (SSH private key with write access to `axon-repo`); key fingerprint `AXON_KEY_FPR` recorded in `docs/keys.md`.

- [ ] **Step 1:** Owner installs GnuPG for macOS (official installer from gnupg.org — I download the .dmg, owner double-clicks and enters the Mac password). Verify: `gpg --version` prints 2.4+.
- [ ] **Step 2:** Generate primary key `AXON Linux <packages@axon-project.ru>` (ed25519, cert-only, expires 5y) with a random passphrase stored via `security add-generic-password -s axon-gpg`; add a signing subkey (ed25519, expires 2y). Export public key → `packages/axon-keyring/axon.gpg`; export **only** the secret subkey (`--export-secret-subkeys FPR!`) → secret `AXON_SIGN_SUBKEY` via `gh secret set`. Back up the full secret key + revocation certificate to `~/Documents/axon-keys/` (owner told where).
- [ ] **Step 3:** `gh repo create DaCat-stack/axon-repo --public` with README «Пакеты AXON Linux»; `ssh-keygen -t ed25519` → deploy key with write (`gh repo deploy-key add --allow-write`), private part → secret `AXON_REPO_DEPLOY_KEY`; enable Pages from `gh-pages` (`gh api -X POST repos/DaCat-stack/axon-repo/pages`).
- [ ] **Step 4:** Verify: `gh secret list -R DaCat-stack/axon-linux` shows both secrets; `gpg --list-secret-keys` shows `sec` + `ssb`. Commit `keys: AXON public key`.

### Task 2: Сборка пакетов в CI

**Files:** Create `ci/build-packages.sh`, `packages/README.md`; Modify `build.sh`, `tests/static.sh`.

**Interfaces:**
- Produces `ci/build-packages.sh <outdir> [--sign]`: builds every `packages/*/PKGBUILD` as user `builder`, copies `*.pkg.tar.zst` to `<outdir>`; with `--sign` imports `$AXON_SIGN_SUBKEY` and creates detached `.sig` per package. Exit ≠ 0 on any failure.
- `build.sh` calls it into `/tmp/axon-repo` (the same local repo as Calamares), unsigned.

- [ ] **Step 1:** Static checks: every `packages/*/PKGBUILD` passes `bash -n`, defines `pkgname` starting with `axon-`, and has `arch=('any')` or `('x86_64')`. Run → FAIL (no packages yet → assert at least one dir, `axon-keyring`, exists).
- [ ] **Step 2:** `packages/axon-keyring/PKGBUILD`: installs `axon.gpg`, `axon-trusted` (`<FPR>:4:`), empty `axon-revoked` into `/usr/share/pacman/keyrings/`; `axon-keyring.install` runs `pacman-key --populate axon` on install/upgrade.
- [ ] **Step 3:** Implement `ci/build-packages.sh`; `build.sh`: call it before `repo-add`, so `axon-local` contains `axon-*` + calamares.
- [ ] **Step 4:** Static PASS; push; CI ISO build green with `axon-keyring` in the image (`pacman -Q axon-keyring` inside `airootfs` logged by build.sh). Commit `packages: axon-keyring + CI build`.

### Task 3: Перенос оформления AXON в пакеты

**Files:**
- Create: `packages/axon-branding/{PKGBUILD,axon-branding.install}`, `packages/axon-welcome/PKGBUILD`; sources are referenced from the repo tree (`source=()` empty, `package()` copies from `$startdir/../../pkgsrc/<pkgname>/`).
- Move (git mv): everything under `profile/airootfs/usr/share/{wallpapers,plymouth,sddm,plasma,pixmaps}`, `profile/airootfs/etc/xdg/{kdeglobals,kscreenlockerrc,ksplashrc}` → `pkgsrc/axon-branding/…`; `profile/airootfs/usr/lib/axon-welcome`, `usr/bin/axon-welcome`, `usr/share/applications/axon-welcome.desktop`, `etc/xdg/autostart/axon-welcome.desktop` → `pkgsrc/axon-welcome/…`.
- Modify: `profile/airootfs/etc/sddm.conf.d/` → `axon.conf` deleted; branding ships `/etc/sddm.conf.d/10-axon-theme.conf` (`[Theme] Current=axon`); live autologin moves to `profile/airootfs/etc/sddm.conf.d/zz-live.conf`. Delete `profile/airootfs/etc/plymouth/plymouthd.conf` (owned by `plymouth`); `axon-branding.install` runs `plymouth-set-default-theme axon` on install/upgrade.
- Modify: `profile/packages.x86_64` (+`axon-keyring axon-branding axon-welcome`), `build.sh` file_permissions (welcome launcher moves out of airootfs → drop its entry; keep live ones), `tests/static.sh` (paths now under `pkgsrc/`), `cleanup.sh` (remove `zz-live.conf` instead of rewriting `axon.conf`; drop `sddm-axon.conf` copy).

- [ ] **Step 1:** Update static checks to the new paths + add: «no package ships an Arch-owned path» — fail if any file under `pkgsrc/` matches the list `etc/plymouth/plymouthd.conf etc/pacman.conf etc/sddm.conf etc/mkinitcpio.conf`. Run → FAIL.
- [ ] **Step 2:** git mv + PKGBUILDs (`axon-branding` depends: `plymouth sddm plasma-desktop papirus-icon-theme inter-font`; `axon-welcome` depends: `pyside6 plasma-workspace axon-branding`); `install -Dm` with correct modes (fixes the «mkarchiso drops modes» issue for these files for good).
- [ ] **Step 3:** cleanup.sh: `rm -f /etc/sddm.conf.d/zz-live.conf`; test `tests/test_cleanup_fs.sh` (Task 6) covers it — here add static check `cleanup removes zz-live.conf`.
- [ ] **Step 4:** Static PASS (incl. `tests/test_presets.py` with new import path); push; ISO green; QEMU desktop screenshot still shows preset A + AXON wallpaper; greeter screenshot unchanged. Commit `packages: axon-branding, axon-welcome`.

### Task 4: Публикация в репозиторий и e2e-проверка

**Files:** Create `.github/workflows/packages.yml`, `ci/publish-repo.sh`, `ci/e2e-repo.sh`; Modify `profile/airootfs`-side pacman.conf generation in `build.sh`.

**Interfaces:**
- `ci/publish-repo.sh <pkgdir> <site-checkout>`: copies new `*.pkg.tar.zst{,.sig}` into `<site>/axon-testing/x86_64/`, runs `repo-add -s -k $FPR --remove axon-testing.db.tar.gz …`, writes plain copies `axon-testing.db`, `axon-testing.db.sig`, `axon-testing.files(.sig)` (no symlinks — Pages), keeps only the newest version of each package.
- `ci/promote.sh <site-checkout> <pkgname>`: same for `axon/` with the testing file of that package.
- `ci/e2e-repo.sh <base-url> <channel>`: fresh `archlinux` container, imports `axon.gpg` via `pacman-key --add` + `--lsign-key`, adds `[<channel>]` with `SigLevel = Required DatabaseRequired`, `pacman -Sy --noconfirm axon-keyring axon-branding axon-welcome`, asserts `/usr/share/plymouth/themes/axon/axon.script` and `/usr/bin/axon-welcome` exist and `pacman-key --list-keys AXON` succeeds.

- [ ] **Step 1:** Write `ci/e2e-repo.sh` first; run it against the empty site after Task 1 → FAIL (404 on db).
- [ ] **Step 2:** `packages.yml`: on push to `main`/`axon-look` touching `packages/** pkgsrc/**`, on `workflow_dispatch`, and nightly 03:00 UTC (heartbeat: re-deploy so the site's Last-Modified stays fresh). Steps: build (`--sign`) → checkout `gh-pages` of axon-repo via deploy key → publish to testing → orphan commit + force push → wait for Pages (`gh api …/pages/builds/latest` status `built`) → `e2e-repo.sh … axon-testing` → for each package that passed: promote → force push → `e2e-repo.sh … axon`.
- [ ] **Step 3:** `build.sh`: append to the airootfs pacman.conf (not the build one) before `[core]`:
  `[axon]` / `SigLevel = Required DatabaseRequired` / `Server = https://dacat-stack.github.io/axon-repo/axon/$arch`. Static check for this block.
- [ ] **Step 4:** Run the workflow; Expected: both e2e runs green, `curl -sI …/axon/x86_64/axon.db` → 200. Commit `ci: publish signed repo to axon-repo Pages`.

### Task 5: Предупреждение «Обновления AXON не приходят»

**Files:** Create `pkgsrc/axon-branding/usr/lib/axon/check-updates-age`, `…/usr/lib/systemd/user/axon-update-age.{service,timer}`, `tests/test_update_age.sh`; Modify `packages/axon-branding/PKGBUILD` (+`libnotify`; enable the user timer globally via `/usr/lib/systemd/user/timers.target.wants/` symlink).

**Interfaces:** `check-updates-age [db] [days]` — defaults `/var/lib/pacman/sync/axon.db`, `14`; exit 0 silent when fresh; when older (or missing) runs `notify-send -a AXON -i axon-logo "Обновления AXON не приходят" "Последнее обновление каталога AXON: <дата>. Проверь интернет или открой «Обновления» в Discover."` and exits 0.

- [ ] **Step 1:** Test with a temp file + fake `notify-send` on PATH: fresh file → no call; `touch -d '20 days ago'` → one call with the exact title; missing file → one call. Run → FAIL.
- [ ] **Step 2:** Implement; timer `OnBootSec=10min`, `OnUnitActiveSec=1d`. Test PASS. Commit `branding: update-age warning`.

### Task 6: btrfs по умолчанию, снимки и откат из меню загрузки

**Files:**
- Modify: `profile/airootfs/etc/calamares/modules/partition.conf` (`defaultFileSystemType: "btrfs"`, `availableFileSystemTypes: ["btrfs","ext4","xfs"]`), Create `…/modules/mount.conf` (subvolumes per Global Constraints, `btrfsSwapSubvol: /@swap`, btrfs options `defaults,noatime,compress=zstd`), `…/settings.conf` (new instance `shellprocess@snapshots` after `initcpiocfg`, before `initcpio`), `…/modules/shellprocess-snapshots.conf`.
- Create: `pkgsrc/axon-branding/usr/share/axon/target/snapper-root` (`SUBVOLUME="/"`, `NUMBER_LIMIT="10"`, `TIMELINE_CREATE="yes"`, `TIMELINE_LIMIT_DAILY="5"`, hourly/weekly/monthly/yearly `0`), `…/target/snapshots.sh`, `tests/test_cleanup_fs.sh`.
- Modify: `profile/packages.x86_64` (+`snapper snap-pac grub-btrfs inotify-tools btrfs-progs`), `tests/calamares_sequence.py` (sequence now has `shellprocess@snapshots` after `initcpiocfg`).

**Interfaces:** `snapshots.sh` (in chroot): if `findmnt -no FSTYPE /` ≠ `btrfs` → exit 0 doing nothing; else install `/etc/snapper/configs/root` from template, `SNAPPER_CONFIGS="root"` in `/etc/conf.d/snapper`, add `grub-btrfs-overlayfs` to the end of HOOKS in `/etc/mkinitcpio.conf`, enable `snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service`.

- [ ] **Step 1:** `tests/test_cleanup_fs.sh`: runs `snapshots.sh` in a temp root with stubbed `findmnt`/`systemctl` (PATH shims) for `ext4` → no files created, no systemctl calls; for `btrfs` → config file with `NUMBER_LIMIT="10"` and `TIMELINE_LIMIT_DAILY="5"`, HOOKS line ends with `grub-btrfs-overlayfs)`, three units enabled. Also asserts cleanup.sh removes `etc/sddm.conf.d/zz-live.conf`. Run → FAIL.
- [ ] **Step 2:** Implement (script takes optional `ROOT` env for tests, default `/`). PASS.
- [ ] **Step 3:** Calamares configs + sequence test update → static PASS.
- [ ] **Step 4:** Commit `installer: btrfs + snapper + rollback from GRUB`.

### Task 7: Финальная проверка

- [ ] ISO build green on `axon-look`; `screens/` boot + desktop look right; packages workflow green with both e2e runs.
- [ ] Кнопка «Оставить эту версию» (snapper rollback) — в плане Б, вместе с Магазином.
- [ ] Owner on the real PC: boots ISO, AXON look is there; installs (alongside Windows or to a spare disk) with btrfs; after first boot `pacman -Sy` sees `[axon]`; installs anything via Discover → GRUB menu shows «снимки»; booting a snapshot reaches the desktop.
