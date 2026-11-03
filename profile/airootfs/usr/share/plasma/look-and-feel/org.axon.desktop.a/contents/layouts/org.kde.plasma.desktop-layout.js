// AXON, пресет A «как Windows 11»: плавающая панель по центру снизу + отдельный блок трея и часов справа.
// Обои AXON на всех рабочих столах
var LAUNCHERS = "applications:firefox.desktop,applications:org.kde.dolphin.desktop,applications:steam.desktop,applications:net.lutris.Lutris.desktop,applications:discord.desktop,applications:org.kde.konsole.desktop";
var LOGO = "/usr/share/pixmaps/axon-logo.png";

var allDesktops = desktops();
for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", "file:///usr/share/wallpapers/AXON");
}

function configure(widget, group, values) {
    widget.currentConfigGroup = group;
    for (var key in values) widget.writeConfig(key, values[key]);
}

var main = new Panel;
main.location = "bottom";
main.floating = true;
main.lengthMode = "fit";
main.alignment = "center";
main.height = 50;
configure(main.addWidget("org.kde.plasma.kickoff"), ["General"], { icon: LOGO });
main.addWidget("org.kde.plasma.marginsseparator");
configure(main.addWidget("org.kde.plasma.icontasks"), ["General"], { launchers: LAUNCHERS });

var tray = new Panel;
tray.location = "bottom";
tray.floating = true;
tray.lengthMode = "fit";
tray.alignment = "right";
tray.height = 50;
tray.addWidget("org.kde.plasma.systemtray");
configure(tray.addWidget("org.kde.plasma.digitalclock"), ["Appearance"], { showDate: true, dateDisplayFormat: "BelowTime", dateFormat: "shortDate" });
