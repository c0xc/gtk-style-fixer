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

# Turn off user-global overlay animation
if [[ $(gsettings get org.gnome.desktop.interface overlay-scrolling) = "true" ]]; then
    echo "* fixing overlay setting ..."
    gsettings set org.gnome.desktop.interface overlay-scrolling false
fi

# GTK3 style
read -r -d '' gtk3_css_block <<-'EOF'
scrollbar {
    -GtkScrollbar-has-backward-stepper: true;
    -GtkScrollbar-has-forward-stepper: true;
    -GtkRange-slider-width: 20;
    -GtkRange-stepper-size: 20;
}

scrollbar slider {
    border: 0;
    border-radius: 0;
    min-width: 15px;
    min-height: 15px;
}
EOF
# Check for GTK3 style file, create it
gtk3_css_file="$HOME/.config/gtk-3.0/gtk.css"
if ! [ -f "$gtk3_css_file" ]; then
    mkdir -p "$HOME/.config/gtk-3.0/"
    touch "$gtk3_css_file"
else
    cp -v "$gtk3_css_file" "${gtk3_css_file}.old"
fi
gtk3_old_conf=$(cat "$gtk3_css_file" 2>/dev/null)
# Fix GTK3 user style file
if $(echo "$gtk3_old_conf" | grep -qF "scrollbar {"); then
    echo "gtk3 config already contains scrollbar section"
    skip_gtk3_conf=1
fi
if [ -z "$skip_gtk3_conf" ]; then
    echo "* setting gtk3 config ..."
    echo $'\n'"$gtk3_css_block" >>"$gtk3_css_file"
fi

# Check for GTK3 settings file, create it (with header) if missing
gtk3_settings_file="$HOME/.config/gtk-3.0/settings.ini"
if ! grep -qF '[Settings]' "$gtk3_settings_file"; then
    echo "* initializing GTK3 settings file ..."
    echo '[Settings]' >>"$gtk3_settings_file"
fi
# Fix GTK3 settings file
if grep -F 'gtk-primary-button-warps-slider' "$gtk3_settings_file"; then
    sed -ie 's/\(gtk-primary-button-warps-slider\s*=\s*\)\w*/\1false/' "$gtk3_settings_file"
else
    echo 'gtk-primary-button-warps-slider=false' >>"$gtk3_settings_file"
fi

# GTK2 style
read -r -d '' gtk2_conf_block <<-'EOF'
style "gtk2scrollbar"
{
    GtkRange::stepper-size = 16
    GtkRange::trough-under-steppers = 1
    GtkScrollbar::has-backward-stepper = 1
    GtkScrollbar::has-forward-stepper = 1
    GtkScrollbar::slider-width = 16
    GtkScrollbar::trough-border = 2
}
class "GtkScrollbar" style "gtk2scrollbar"
EOF
gtk2_file="$HOME/.gtkrc-2.0"
# Fix GTK2 style
# TODO this override might not be necessary
if [[ -n "$fix_gtk2_style" ]]; then
    if ! grep -qF 'gtk2scrollbar' "$gtk2_file"; then
        echo "* setting $HOME/.gtkrc-2.0 ..."
        echo $'\n'"$gtk2_conf_block" >>"$gtk2_file"
    fi
fi

# Switch theme, set a known working one
if [[ -n "$set_gtk2_theme" ]]; then
    theme_name=Materia
    if [ -d "/usr/share/themes/$theme_name" ]; then
        if ! grep -q '^\s*gtk-theme-name=' "$gtk2_file"; then
            echo "* setting GTK2 theme = $theme_name ..."
            sed -i -E 's/^\s*gtk-theme-name="(.+)"/gtk-theme-name='"$theme_name"'/' "$gtk2_file"
        fi
    else
        echo "not setting $theme_name theme: not found"
    fi
fi

# Fix Firefox settings - all *.default* profiles
# Firefox has its own settings that are set to break the scrollbars by default.
# Also, there's this: widget.gtk.alt-theme.scrollbar_active
for f in $HOME/.mozilla/firefox/*.default*/prefs.js $HOME/.thunderbird/*.default*/prefs.js; do
    if ! [ -f "$f" ]; then
        echo "file not found: $f"
        break
    fi
    file=$(dirname "$f")"/user.js"
    #if grep widget.non-native-theme.gtk.scrollbar.allow-buttons "$f" | grep -q false; then
    #    echo "setting firefox settings"
    #    sed -iE 's/\"\(widget.non-native-theme.gtk.scrollbar.allow-buttons\", false\)/("widget.non-native-theme.gtk.scrollbar.allow-buttons", true)/' "$f"
    #fi
    if ! grep -q 'widget.non-native-theme.gtk.scrollbar.allow-buttons' "$file"; then
        echo "* fixing Mozilla style settings: $file ..."
        echo 'user_pref("widget.non-native-theme.gtk.scrollbar.allow-buttons", true);' \
            >>"$file"
        echo 'user_pref("widget.gtk.overlay-scrollbars.enabled", false);' \
            >>"$file"

    fi
done

