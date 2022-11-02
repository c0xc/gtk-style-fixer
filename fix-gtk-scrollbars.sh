#!/usr/bin/env bash

# Someone broke all the scrollbars in GTK/Gnome/Mate:
# No more arrow buttons, it's impossible to carefully scroll through a huge
# document or very long lines.
# Who's the idiot who broke that basic gui feature? Someone should take his computer away.
# And since Mozilla has stopped improving their browser years ago
# and instead are now increasing the major version with every
# new useless button, even more "news" and other ad-ware,
# they had no way but to add a Firefox setting to break the scrollbars.
#
# This script attempts to fix the most common settings
# to restore scrollbars, mostly Gtk 3 applications like Gedit.
# It should also fix simple Gtk 2 applications like Leafpad.
# It can fix Firefox to some degree until they break it again which is likely.
#

if [[ $(gsettings get org.gnome.desktop.interface overlay-scrolling) = "true" ]]; then
    echo "setting overlay setting"
    gsettings set org.gnome.desktop.interface overlay-scrolling false
fi

if ! [ -f "$HOME/.config/gtk-3.0/gtk.css" ]; then
    mkdir -p "$HOME/.config/gtk-3.0/"
    touch "$HOME/.config/gtk-3.0/gtk.css"
else
    cp -v "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css.old"
fi
gtk_3=$(cat "$HOME/.config/gtk-3.0/gtk.css")
if $(echo "$gtk_3" | grep -qF "scrollbar {"); then
    echo "gtk3 config already contains scrollbar section"
    skip_gtk3_conf=1
fi
if [ -z "$skip_gtk3_conf" ]; then
    echo "setting gtk3 config"
cat <<EOF >>"$HOME/.config/gtk-3.0/gtk.css"

scrollbar {
        -GtkScrollbar-has-backward-stepper: true;
        -GtkScrollbar-has-forward-stepper: true;
}

scrollbar slider {
        border: 0;
        border-radius: 0;
        min-width: 15px;
        min-height: 15px;
}

EOF
fi

if ! grep -qF '[Settings]' $HOME/.config/gtk-3.0/settings.ini; then
    echo '[Settings]' >>$HOME/.config/gtk-3.0/settings.ini
fi
if grep -F 'gtk-primary-button-warps-slider' $HOME/.config/gtk-3.0/settings.ini; then
    sed -ie 's/\(gtk-primary-button-warps-slider\s*=\s*\)\w*/\1false/' $HOME/.config/gtk-3.0/settings.ini
else
    echo 'gtk-primary-button-warps-slider=false' >>$HOME/.config/gtk-3.0/settings.ini
fi

#if [ -d /usr/share/themes/Materia ]; then
#    if ! grep -q 'gtk-theme-name="Materia' $HOME/.gtkrc-2.0; then
#        echo "setting Materia theme"
#        sed -i -E 's/gtk-theme-name="(.+)"/gtk-theme-name=Materia/' $HOME/.gtkrc-2.0
#    fi
#else
#    echo "not setting Materia theme: not found"
#fi

for f in $HOME/.mozilla/firefox/*.default*/prefs.js; do
    if ! [ -f "$f" ]; then break; fi
    file=$(dirname "$f")"/user.js"
    #if grep widget.non-native-theme.gtk.scrollbar.allow-buttons "$f" | grep -q false; then
    #    echo "setting firefox settings"
    #    sed -iE 's/\"\(widget.non-native-theme.gtk.scrollbar.allow-buttons\", false\)/("widget.non-native-theme.gtk.scrollbar.allow-buttons", true)/' "$f"
    #fi
    if ! grep -q 'widget.non-native-theme.gtk.scrollbar.allow-buttons' "$file"; then
        echo "setting firefox settings"
        echo 'user_pref("widget.non-native-theme.gtk.scrollbar.allow-buttons", true);' \
            >>"$file"
        echo 'user_pref("widget.gtk.overlay-scrollbars.enabled", false);' \
            >>"$file"

    fi
done

