// AXON, пресет B «как на маке»: тонкая полупрозрачная полоска сверху + плавающий док снизу.
// Увеличения иконок при наведении нет: в штатном Plasma его нет, а сторонние виджеты не ставим.
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
top.opacity = "translucent";
configure(top.addWidget("org.kde.plasma.kickoff"), ["General"], { icon: LOGO });
top.addWidget("org.kde.plasma.appmenu");
top.addWidget("org.kde.plasma.panelspacer");
top.addWidget("org.kde.plasma.systemtray");
configure(top.addWidget("org.kde.plasma.digitalclock"), ["Appearance"], { showDate: true, dateDisplayFormat: "BesideTime" });

var dock = new Panel;
dock.location = "bottom";
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.height = 58;
configure(dock.addWidget("org.kde.plasma.icontasks"), ["General"], { launchers: LAUNCHERS + ",applications:systemsettings.desktop" });
