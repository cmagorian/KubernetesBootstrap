SCRIPTS_PATH=scripts

.PHONY: setup-host setup-worker clean

setup-host:
	chmod +x $(SCRIPTS_PATH)/validate.sh
	./$(SCRIPTS_PATH)/validate.sh host
	chmod +x $(SCRIPTS_PATH)/setup_rpi_master.sh
	./$(SCRIPTS_PATH)/setup_rpi_master.sh

setup-worker:
	chmod +x $(SCRIPTS_PATH)/validate.sh
	./$(SCRIPTS_PATH)/validate.sh worker
	chmod +x $(SCRIPTS_PATH)/setup_worker_node.sh
	./$(SCRIPTS_PATH)/setup_worker_node.sh

clean:
	kubeadm reset
	sudo apt purge -y docker-engine docker docker-ce docker-ce-cli
	sudo apt autoremove -y --purge docker-engine docker docker-ce docker-ce-cli
	sudo systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
	sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X