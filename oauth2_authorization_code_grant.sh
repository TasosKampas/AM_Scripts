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
 
# Obtain a user Token
tokenid=`curl -s --request POST \
 --header "Accept-API-Version: resource=2.0, protocol=1.0" \
 --header "X-OpenAM-Username: $USER" \
 --header "X-OpenAM-Password: $PASSWORD" \
 --header "Content-Type: application/json" \
 --data "{}" "$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/json/authenticate?realm=$REALM" | jq -r .tokenId`
echo "tokenid is " $tokenid
 
 
# Obtain an Authorization Code
code=`curl -i -s \
--request POST \
--header "Content-Type: application/x-www-form-urlencoded" \
--Cookie "iPlanetDirectoryPro=$tokenid" \
--data "redirect_uri=$REDIRECT_URI" \
--data "scope=$SCOPE" \
--data "response_type=code" \
--data "client_id=$OAUTH2CLIENT" \
--data "csrf=$tokenid" \
--data "decision=allow" \
--data "save_consent=on" \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/oauth2/authorize?realm=$REALM" | grep "code=" | cut -d '=' -f2 | cut -d '&' -f1`
echo "code is " $code
 
#Obtain an Access Token
accesstoken=`curl -s -k \
--user "$OAUTH2CLIENT:$OAUTH2PASSWORD" \
--header "Content-Type: application/x-www-form-urlencoded" \
--request POST \
--data "redirect_uri=$REDIRECT_URI" \
--data "code=$code" \
--data "grant_type=authorization_code" \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/oauth2/access_token?realm=$REALM" | python -m json.tool | grep access_token | cut -f4 -d'"'`
echo "access token is " $accesstoken
