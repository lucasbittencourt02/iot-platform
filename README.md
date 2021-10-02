# Plataforma IoT - Mosquitto + PostgreSQL + Grafana

Plataforma IoT capaz de receber dados de sensores MQTT.

A plataforma inicialmente foi desenhada para coletar informações elétricas de um ponto de energia e publicar a leitura em uma Dashboard para monitoramento e acompanhamento de historico.


## Clone Repositório
```
git clone https://github.com/lucasbittencourt02/iot-platform.git
```
## Instalação aplicação

Acesse o local do arquivo clonado e execute os seguintes comandos:

```
sudo chmod +x setup.sh
sudo ./setup.sh
```

## Criar tabela
Para se criar a tabela, existem duas opções, ou se faz via PGAdmin ou executando o script no container.

Para executar o script no container de banco de dados, siga os seguintes passos:

```sudo docker exec -it db-postgresql psql -U postgres ```

Criando a tabela de sensores:

```
CREATE DATABASE sensor_data;

\c sensor_data

CREATE TABLE IF NOT EXISTS sensor_data
(
    id          text             NOT NULL,
    voltage     double PRECISION NOT NULL,
    current     double PRECISION NOT NULL,
    power       double PRECISION NOT NULL,
    create_at   timestamptz      NOT NULL,
    update_at   timestamptz      NOT NULL,
    completed_at timestamptz     
);


CREATE TRIGGER set_timestamp
BEFORE UPDATE ON sensor_data
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
```

## Criar View tabela
```
CREATE VIEW grandezas_eletricas_summary_minute WITH (timescaledb.continuous) AS
SELECT id,
       time_bucket(INTERVAL '1 minute', create_at) AS bucket,
       AVG(voltage) AS avg_voltage,
       AVG(current) AS avg_current,
       AVG(power)   AS avg_power
FROM sensor_data
GROUP BY id,
         bucket;
```

## Criar usuário de acesso Grafana
```
CREATE USER grafanareader WITH PASSWORD 'grafana1234';
GRANT USAGE ON SCHEMA public TO grafanareader;
GRANT SELECT ON public.sensor_data TO grafanareader;
GRANT SELECT ON public.grandezas_eletricas_summary_minute TO grafanareader;
```
