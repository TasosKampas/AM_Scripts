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
SCOPE="profile"
 
#Obtain an Access Token
accesstoken=`curl -s -k \
--request POST \
--user "$OAUTH2CLIENT:$OAUTH2PASSWORD" \
--header "Content-Type: application/x-www-form-urlencoded" \
--data "grant_type=client_credentials" \
--data "scope=$SCOPE" \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/oauth2/access_token?realm=$REALM" | python -m json.tool | grep access_token | cut -f4 -d'"'`
echo "Client Credentials Access Token is " $accesstoken
