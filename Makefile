SCRIPTS_PATH=scripts/

all:
	printf "Nothing to be done here \n"

setup:
	chmod +x $(SCRIPTS_PATH)/setup.sh
	./$(SCRIPTS_PATH)/setup.sh

host:
	printf "Not ready to setup a host yet \n"

join:
	printf "Not ready to join a cluster yet"