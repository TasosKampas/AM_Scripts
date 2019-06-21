#!/bin/bash
 
#adjust as per your deployment
protocol="http"
host="openam.example.com"
port="38080"
deployment="openam"
realm="/"
admin="amadmin"
pass="cangetinam"
user="demo"
password="changeit"
 
#Obtain a user/admin token (amadmin)
tokenid1=`curl -s \
--request POST \
--header "Accept-API-Version: resource=2.0, protocol=1.0" \
--header "X-OpenAM-Username: $admin" \
--header "X-OpenAM-Password: $pass" \
--header "Content-Type: application/json" \
--data "{}" \
"$protocol://$host:$port/$deployment/json/authenticate?realm=$realm"| python -m json.tool | grep tokenId |cut -f4 -d'"'`
echo "Amadmin tokenid is " $tokenid1
 
 
#Obtain a user token (demo)
tokenid2=`curl -s \
--request POST \
--header "Accept-API-Version: resource=2.0, protocol=1.0" \
--header "X-OpenAM-Username: $user" \
--header "X-OpenAM-Password: $password" \
--header "Content-Type: application/json" \
--data "{}" \
"$protocol://$host:$port/$deployment/json/authenticate?realm=$realm"| python -m json.tool | grep tokenId |cut -f4 -d'"'`
echo $user "tokenid is " $tokenid2
 
 
#Obtain User's Session Info
SessionInfo=`curl -s \
--request POST \
--header "Accept-API-Version: resource=3.1, protocol=1.0" \
--header "Content-Type: application/json" \
--header "iplanetDirectoryPro: $tokenid1" \
"$protocol://$host:$port/$deployment/json/realms/root/sessions/?_action=getSessionInfo&tokenId=$tokenid2"| jq .`
echo "Session Info is " $SessionInfo
 
#Refresh User's session
RefreshSession=`curl -s \
--request POST \
--header "Accept-API-Version: resource=3.1, protocol=1.0" \
--header "Content-Type: application/json" \
--header "iplanetDirectoryPro: $tokenid1" \
--data "{\"tokenId\":\"${tokenid2}\"}" \
"$protocol://$host:$port/$deployment/json/realms/root/sessions/?_action=refresh"| jq .`
echo "Refresh session Info is " $RefreshSession
