#!/bin/bash
 
PROTOCOL="http"
HOST="openam.example.com"
PORT="48080"
DEPLOYMENT="openam"
REALM="/"
USER="demo"
PASSWORD="changeit"
 
# Obtain a user Token
tokenid=`curl -s --request POST \
--header "Accept-API-Version: resource=2.0, protocol=1.0" \
--header "X-OpenAM-Username: $USER" \
--header "X-OpenAM-Password: $PASSWORD" \
--header "Content-Type: application/json" \
--data "{}" \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/json/authenticate?realm=$REALM"| python -m json.tool | grep tokenId |cut -f4 -d'"'`
echo "tokenid is " $tokenid
 
# Validate the session
validation=`curl -s -X POST \
--header "Content-Type: application/json" \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/json/sessions/$tokenid?_action=validate" | jq '.valid'`
echo "Sesions is valid:  " $validation
 
# Transform SSToken to OIDC token (here we use an STS intance called 'sts-oidc'
sts=`curl -s \
--request POST \
--header "Content-Type: application/json" \
--data " {\"input_token_state\":{\"token_type\":\"OPENAM\",\"session_id\":\"${tokenid}\"},\"output_token_state\":{\"token_type\":\"OPENIDCONNECT\",\"nonce\":\"12345678\",\"allow_access\":true}}" \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/rest-sts/sts-oidc?_action=translate" | jq '.issued_token'`
echo "The OIDC token is" $sts
