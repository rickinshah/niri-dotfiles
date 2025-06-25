a=$(pamixer --get-volume)

# canberra-gtk-play -V 5.0 -i dialog-warning &
if [ $a -ge 145 ] && [ $a -ne 150 ]; then
	$(volumectl -b -u -d set 150)
elif [ $a -lt 150 ]; then
	$(volumectl -b -u -d up)
else
	$(volumectl -b -d -u set 150)
fi
# sleep 0.05
