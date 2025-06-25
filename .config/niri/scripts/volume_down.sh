# a=$(pamixer --get-volume)

# canberra-gtk-play -V 5.0 -i dialog-warning &
$(volumectl -b -u -d down)
