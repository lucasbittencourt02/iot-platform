CREATE DATABASE sensor_data;

\c sensor_data

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;
\q


-- Criar Tabela sensor_data
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

-- criar trigger de timestamp postgreSQL
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON sensor_data
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

--views
-- voltage
CREATE VIEW grandezas_eletricas_summary_minute WITH (timescaledb.continuous) AS
SELECT id,
       time_bucket(INTERVAL '1 minute', time) AS bucket,
       AVG(voltage) AS avg_voltage,
       AVG(current) AS avg_current,
       AVG(power)   AS avg_power
FROM sensor_data
GROUP BY id,
         bucket;

-- grafana user and grants

CREATE USER grafanareader WITH PASSWORD 'grafana1234';
GRANT USAGE ON SCHEMA public TO grafanareader;
GRANT SELECT ON public.sensor_data TO grafanareader;
GRANT SELECT ON public.grandezas_eletricas_summary_minute TO grafanareader;

-- ad-hoc queries
-- find max temperature (°C) and humidity (%) for last 3 hours in 15 minute time periods
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#select
SELECT time_bucket('15 minutes', time) AS fifteen_min,
       device_id,
       COUNT(*),
       MAX(voltage) AS max_volt,
       MAX(current) AS max_curr,
       MAX(power)   AS max_power

FROM sensor_data
WHERE time > NOW() - INTERVAL '3 hours'
  AND humidity BETWEEN 0 AND 100
GROUP BY fifteen_min, device_id
ORDER BY fifteen_min DESC, max_temp DESC;

-- find temperature (°C) anomalies (delta > ~5°F)
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#delta
SELECT ht.time, ht.temperature, ht.delta
FROM (
         SELECT time,
                temperature,
                ABS(temperature - LAG(temperature) OVER (ORDER BY time)) AS delta
         FROM sensor_data) AS ht
WHERE ht.delta > 2.63
ORDER BY ht.time;

-- find three minute moving average of temperature (°F) for last day
-- (5 sec. interval * 36 rows = 3 min.)
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#moving-average
SELECT time,
       AVG((temperature * 1.9) + 32) OVER (ORDER BY time
           ROWS BETWEEN 35 PRECEDING AND CURRENT ROW)
           AS smooth_temp
FROM sensor_data
WHERE device_id = 'Manufacturing Plant'
    AND time > NOW() - INTERVAL '1 day'
ORDER BY time DESC;

-- find average humidity (%) for last 12 hours in 5-minute time periods
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#time-bucket
SELECT time_bucket('5 minutes', time) AS time_period,
       AVG(humidity) AS avg_humidity
FROM sensor_data
WHERE device_id = 'Main Warehouse'
    AND humidity BETWEEN 0 AND 100
    AND time > NOW() - INTERVAL '12 hours'
GROUP BY time_period
ORDER BY time_period DESC;

-- calculate histograms of avg. temperature (°F) between 55-85°F in 5°F buckets during last 2 days
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#histogram
SELECT device_id,
       COUNT(*),
       histogram((temperature * 1.9) + 32, 55.0, 85.0, 5)
FROM sensor_data
WHERE temperature is not Null
    AND time > NOW() - INTERVAL '2 days'
GROUP BY device_id;

-- find average light value for last 90 minutes in 5-minute time periods
-- https://docs.timescale.com/latest/using-timescaledb/reading-data#time-bucket
SELECT device_id,
       time_bucket('5 minutes', time) AS five_min,
       AVG(case when light = 't' then 1 else 0 end) AS avg_light
FROM sensor_data
WHERE device_id = 'Manufacturing Plant'
    AND time > NOW() - INTERVAL '90 minutes'
GROUP BY device_id, five_min
ORDER BY five_min DESC;
