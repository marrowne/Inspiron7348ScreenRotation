# Dell Inspiron 7348 Screen Auto-Rotation Script for Linux

Tested on:

+ Arch Linux and Budgie Desktop

I dare say script works on the vast majority of distros.

##Script run

Please check if _/etc/systemd/user.conf_ has this line:

	DefaultEnvironment=DISPLAY=:0

Remember to make script file executable:

    chmod +x /path/to/directory/inspironRotationScript.sh


##Systemd quickstart

You can use _systemd_ to run script as a service, as well.

Copy *screen-auto-rotation.service* to _~/.config/systemd/user_ and *inspironRotationScript.sh* to _/usr/bin_ and do one of the following.


#####Start as a service

	systemctl --user start screen-auto-rotation.service

#####Start on system launch

	systemctl --user enable screen-auto-rotation.service
	
##Power consumption

Because of the way sensors data are provided in Linux, continuous running this script may cause your battery life shorter. You can stop the service by running

	systemctl --user stop screen-auto-rotation.service

You can also adjust refresh interval by changing value in _inspironRotationScript.sh_ in the 3rd line (default is 2 seconds)

    INTERVAL=2

Enjoy!<br />
[Michał Mordawski](http://mordawski.it)