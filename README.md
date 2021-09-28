## Plataforma IoT - Mosquitto + PostgreSQL + Grafana

Plataforma IoT capaz de receber dados de sensores MQTT.

A plataforma inicialmente foi desenhada para coletar informações elétricas de um ponto de energia e publicar a leitura em uma Dashboard para monitoramento e acompanhamento de historico.






## Instalação Docker e Docker Compose

sudo apt-get install  curl apt-transport-https ca-certificates software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce

sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

## Build Image Subscribe

sudo docker build -t subscribe-mqtt


## Setup de instalação

sudo docker-compose up




