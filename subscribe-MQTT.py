#!/usr/bin/python

import argparse
import json
import logging
import sys
from datetime import datetime

import paho.mqtt.client as mqtt
import psycopg2
#from psycopg2.extras import Json

# Author: Gary A. Stafford
# Date: 10/11/2020
# Usage: python3 mosquitto_to_timescaledb.py \
#           –msqt_topic "sensor/output –msqt_host "192.168.1.12" –msqt_port 1883                                                                                                                 \
#           –ts_host "192.168.1.12" –ts_port 5432 \
#           –ts_username postgres –ts_password postgres1234 –ts_database demo_io                                                                                                                t

logger = logging.getLogger(__name__)
logging.basicConfig(stream=sys.stdout, level=logging.DEBUG)

args = argparse.Namespace
ts_connection: str = ""


def main():
    global args
   # args = parse_args()

    global ts_connection
    ts_connection = "postgres://postgres:14UMzQg7p@*!@44.197.13.126:5432/sensor_                                                                                                                data"
    logger.debug(ts_connection)

    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect("44.197.13.126", 1883, 60)

    # Blocking call that processes network traffic, dispatches callbacks and
    # handles reconnecting.
    # Other loop*() functions are available that give a threaded interface and a
    # manual interface.
    client.loop_forever()


# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    logger.debug("Connected with result code {}".format(str(rc)))

    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("MK114/+/device_to_app")
    msg = print(client.subscribe)

# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    logger.debug("Topic: {}, Message Payload: {}".format(msg.topic, str(msg.payload)))
    publish_message_to_db(msg)


def date_converter(o):
    if isinstance(o, datetime):
        return o.__str__()


def publish_message_to_db(message):
    message_payload = json.loads(message.payload)
    logger.debug("message.payload: {}".format(json.dumps(message_payload, default=date_converter)))

    sql = """INSERT INTO sensor_data(id, voltage, current, power)
                 VALUES (%s, %s, %s, %s);"""
#    data = (Json(message),)
#    ts_connection.execute(sql, data)
#    ts_connection.commit()

    data = (
        message_payload["id"],
        message_payload["data"]["voltage"],
        message_payload["data"]["current"],
        message_payload["data"]["power"],
#        message_payload["data"]["switch_state"]
#        message_payload["create_time"]
    )


# Read in command-line parameters
def parse_args():
    parser = argparse.ArgumentParser(description='Script arguments')
    parser.add_argument('–msqt_topic', nargs= '?',  help='Mosquitto topic', default='MK114/+/device_to_app')
    parser.add_argument('–msqt_host',  nargs= '?', help='Mosquitto host', default='44.197.13.126')
    parser.add_argument('–msqt_port', nargs= '?', help='Mosquitto port', type=int, default=1883)
    parser.add_argument('–ts_host', nargs= '?', help='TimescaleDB host', default='44.197.13.126')
    parser.add_argument('–ts_port', nargs= '?', help='TimescaleDB port', type=int, default=5432)
    parser.add_argument('–ts_username', nargs= '?', help='TimescaleDB username',                                                                                                                 default='postgres')
    parser.add_argument('–ts_password', nargs= '?', help='TimescaleDB password',                                                                                                                 default='postgres1234')
    parser.add_argument('–ts_database', nargs= '?', help='TimescaleDB database',                                                                                                                 default='postgres')

    return parser.parse_args()


if __name__ == "__main__":
     main()
