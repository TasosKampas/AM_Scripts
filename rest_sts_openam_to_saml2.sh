#!/bin/bash
#set -x
  
protocol="http"
host="openam.example.com"
port="38080"
deployment="openam"
user="demo"
password="changeit"
client_id="myClientID"
client_password="password"
scope="profile"
sts="mytest"
 
# Obtain a user Token
tokenid=`curl -s -X POST \
--header "Accept-API-Version: resource=2.0, protocol=1.0" \
--header "X-OpenAM-Username: $user" \
--header "X-OpenAM-Password: $password" \
--header "Content-Type: application/json" \
"$protocol://$host:$port/$deployment/json/authenticate" | jq -r .tokenId`
echo "tokenid is " $tokenid
  
# Exchange the SSOToken for a SAML Assertion
saml_assertion=`curl -v -X POST \
--header "Content-Type: application/json" \
--header "Cache-Control: no-cache" \
--data "{\"input_token_state\":{\"token_type\":\"OPENAM\",\"session_id\":\"${tokenid}\"},\"output_token_state\":{\"token_type\":\"SAML2\",\"subject_confirmation\":\"BEARER\"}}" \
"$protocol://$host:$port/$deployment/rest-sts/$sts?_action=translate" 2>/dev/null | python -m json.tool | grep issued_token | cut -f6- -d" " | sed 's/^"\(.*\)"$/\1/'`
echo "The SAML Assertion is "
echo $saml_assertion
