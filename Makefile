SCRIPTS_PATH=scripts

.PHONY: validate setup host clean

all: validate setup

build:
	go build ./.. -v

validate:
	chmod +x $(SCRIPTS_PATH)/validate.sh
	./$(SCRIPTS_PATH)/validate.sh

setup:
	chmod +x $(SCRIPTS_PATH)/setup.sh
	./$(SCRIPTS_PATH)/setup.sh

host: validate
	./$(SCRIPTS_PATH)/setup.sh -t host

join: validate
	./$(SCRIPTS_PATH)/setup.sh -t worker -H

clean:
	kubeadm reset
	sudo apt purge -y docker-engine docker docker-ce docker-ce-cli
	sudo apt autoremove -y --purge docker-engine docker docker-ce docker-ce-cli
	sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target