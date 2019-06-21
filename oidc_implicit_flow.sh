#!/bin/bash
#set -x
 
PROTOCOL="http"
HOST="openam.example.com"
PORT="28080"
DEPLOYMENT="openam"
REALM="/"
USER="demo"
PASSWORD="changeit"
OAUTH2CLIENT="myClientID"
OAUTH2PASSWORD="password"
REDIRECT_URI="http://test.com"
SCOPE="openid profile"
NONCE="n-0S6_WzA2Mj"
 
# Obtain a user Token
tokenid=`curl -s --request POST \
 --header "Accept-API-Version: resource=2.0, protocol=1.0" \
 --header "X-OpenAM-Username: $USER" \
 --header "X-OpenAM-Password: $PASSWORD" \
 --header "Content-Type: application/json" \
 --data "{}" "$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/json/authenticate?realm=$REALM" | jq -r .tokenId`
echo "tokenid is " $tokenid
 
 
# Obtain an ID Token
idtoken=`curl -i -s \
--request POST \
--header "Content-Type: application/x-www-form-urlencoded" \
--Cookie "iPlanetDirectoryPro=$tokenid" \
--data "redirect_uri=$REDIRECT_URI" \
--data "scope=$SCOPE" \
--data "response_type=id_token" \
--data "client_id=$OAUTH2CLIENT" \
--data "csrf=$tokenid" \
--data "decision=allow" \
--data "save_consent=on" \
--data "nonce=$NONCE" \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/oauth2/authorize?realm=$REALM" | awk -F'[=&]' '{print $4}'`
echo "Implicit ID Token is " $idtoken
