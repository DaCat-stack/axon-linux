// AXON, пресет C «как в Ubuntu»: тёмная верхняя панель (Обзор, часы по центру, трей) + док слева.
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

var top = new Panel;
top.location = "top";
top.height = 26;
top.opacity = "opaque";
configure(top.addWidget("org.kde.plasma.kickoff"), ["General"], { icon: LOGO, menuLabel: "Обзор" });
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.digitalclock");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");

var dock = new Panel;
dock.location = "left";
dock.floating = true;
dock.lengthMode = "fill";
dock.height = 56;
configure(dock.addWidget("org.kde.plasma.icontasks"), ["General"], { launchers: LAUNCHERS + ",applications:systemsettings.desktop" });
dock.addWidget("org.kde.plasma.kickerdash");
