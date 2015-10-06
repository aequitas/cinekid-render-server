test:
	smbutil view -g //192.168.42.2 | grep Cinekid | grep Disk
	@echo -- All good --
