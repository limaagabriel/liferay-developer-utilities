#!/bin/bash
# Usage: lp mysql reset

docker exec mysql mysql -uroot -proot -e "drop database lportal;"
docker exec mysql mysql -uroot -proot -e "create schema lportal default character set utf8;"
