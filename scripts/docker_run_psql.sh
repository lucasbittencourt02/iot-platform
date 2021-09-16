#!/bin/bash
docker run -it –rm postgres psql \
    -U postgres -h localhost -p 5432 -d demo_iot-net