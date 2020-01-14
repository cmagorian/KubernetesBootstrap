SCRIPTS_PATH=scripts

all: validate setup

validate:
	chmod +x $(SCRIPTS_PATH)/validate.sh
	./$(SCRIPTS_PATH)/validate.sh

setup:
	chmod +x $(SCRIPTS_PATH)/setup.sh
	./$(SCRIPTS_PATH)/setup.sh

host: validate
	kubeadm init

join:
	printf "Not ready to join a cluster yet"