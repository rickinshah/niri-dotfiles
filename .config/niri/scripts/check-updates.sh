count=$(yay -Qu | wc -l)

if [[ $count == 0 ]]; then
	echo "No updates"
else
	echo "$count updates"
fi
