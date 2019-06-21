#!/bin/bash
#set -x

# Press [Enter] to go with the default value
# Ask user for host
read -p "Please provide the hostname: [default: openam.example.com] " host
host=${host:-openam.example.com}
# Ask user for port
read -p "Please provide the port number: [default: 18080] " port
port=${port:-18080}
# Ask user for realm
read -p "Please provide the realm: [default: /] " realm
realm=${realm:-/}
# Ask user for username
read -p "Please provide a username: [default: demo] " username
username=${username:-demo}
# Ask user for password
read -sp "Please provide a password: [default: changeit] " password
password=${password:-changeit}
 
protocol="http"
deployment="openam"
 
# Obtain a user Token
tokenid=`curl -v --request POST \
--header "Accept-API-Version: resource=2.0, protocol=1.0" \
--header "X-OpenAM-Username: $username" \
--header "X-OpenAM-Password: $password" \
--header "Content-Type: application/json" \
--data "{}" \
"$protocol://$host:$port/$deployment/json/authenticate?realm=$realm"| python -m json.tool | grep tokenId |cut -f4 -d'"'`
echo "tokenid is " $tokenid
