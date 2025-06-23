# a=$(pamixer --get-volume)

$(volumectl -b -u -d down)
canberra-gtk-play -V 5.0 -i dialog-warning
