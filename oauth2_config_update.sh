!/bin/sh
#set -vx
 
PROTOCOL="http"
HOST="openam.example.com"
PORT="18080"
DEPLOYMENT="openam"
USER="amadmin"
PASSWORD="cangetinam"
REALM="/"
 
# Obtain a user Token
tokenid=`curl -s --request POST \
--header "Accept-API-Version: resource=2.0, protocol=1.0" \
--header "X-OpenAM-Username: $USER" \
--header "X-OpenAM-Password: $PASSWORD" \
--header "Content-Type: application/json" \
--data "{}" \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/json/authenticate?realm=$REALM"| jq -r .tokenId`
echo "tokenid is " $tokenid
 
#Update OAuth2 Config, in this case the Access Token Lifetime
oauth2config=`curl -s -X PUT \
--header "iPlanetDirectoryPro: $tokenid" \
--header "Content-Type: application/json" \
--header "Accept-API-Version: resource=1.0, protocol=1.0" \
--header "Accept: application/json" \
--data '{"coreOAuth2Config":{"accessTokenLifetime":7300}}' \
"$PROTOCOL://$HOST:$PORT/$DEPLOYMENT/json/realm-config/services/oauth-oidc" | jq '.coreOAuth2Config.accessTokenLifetime'`
echo "New Access Token Lifetime is " $oauth2config
