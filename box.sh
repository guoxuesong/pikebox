#! /bin/sh
if test -a ~/PikeBox/box.rc ; then
	true
elif test -a ~/PikeBox/box.rc.example ; then
	cp ~/PikeBox/box.rc.example ~/PikeBox/box.rc
else
	echo You should move PikeBox dir to ~/PikeBox
	exit
fi
mkdir ~/PikeBox/tmp 2>/dev/null
mkdir ~/PikeBox/gvim_tmp 2>/dev/null
mkdir ~/PikeBox/systems 2>/dev/null
bash --rcfile ~/PikeBox/box.rc $*

