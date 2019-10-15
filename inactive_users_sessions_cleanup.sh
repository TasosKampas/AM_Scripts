#!/bin/bash
# set -x

# The url-encode function, it will be needed later when we encode the queryFilter
urlencode() {
    # urlencode <string>
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

# adjust them as required
openam_uri=http://openam.example.com:18080/openam
admin=amadmin
admin_password=cangetinam
realm_path=realms/root
realm=/


echo "------------------------------------------------------------------------------"
echo "ADMINISTRATOR AUTHENTICATION"
echo "------------------------------------------------------------------------------"
# Get an admin token
ipdp=$(curl -s --write-out %{http_code} --request POST \
--header "Accept-API-Version: resource=2.0, protocol=1.0" \
--header "X-OpenAM-Username: ${admin}" \
--header "X-OpenAM-Password: ${admin_password}" \
"${openam_uri}/json/authenticate")
# We added the HTTP code at the end of the response we are checking if this was successful first
# this extracts the last 3 characters of the string
response_code=${ipdp: -3}
if [ $response_code != 200 ]; then 
    echo "Failed to get an administrator cookie, check the admin credentials. Exiting"
else
    # we remove the last 3 character so then we have the JSON string. We extract the tokenId value without the double quotes.
    ipdp=$(echo ${ipdp%???} | python -m json.tool | grep tokenId | cut -f4 -d'"')
    echo "Successfully Logged in as ${admin}"
    #echo "Admnistrator Cookie value is" "${ipdp}"
    echo "------------------------------------------------------------------------------"
    echo "COUNT OF ACTIVE AND INACTIVE USERS IN THE REALM"
    echo "------------------------------------------------------------------------------"
    # Get all the users
    allusers=$(curl -s --request GET \
    --header "Content-Type: application/json" \
    --header "Accept-API-Version: resource=4.1, protocol=2.1" \
    --header "Cookie: iPlanetDirectoryPro=${ipdp}" \
    "${openam_uri}/json/${realm_path}/users?_queryFilter=true&_fields=id,inetUserStatus")
    # NOTE: YOU MUST HAVE THE inetUserStatus AS USER ATTRIBUTE, otherwise it will not work
    #echo ${allusers} | jq .
    # We are checking the resultCount of the response and we remove the double quotation
    number_of_users=$(echo ${allusers} | jq -r .resultCount | xargs)
    echo "The total number of users is:" ${number_of_users}
    #echo $number_of_users
    # We are sorting the inetUserStatus attribute and we counting how many time the 'Inactive' returns
    number_of_inactive=$(echo ${allusers} | jq .result[].inetUserStatus | grep -o '\<Inactive\>' | wc -l)
    #echo $number_of_inactive
    echo "The total number of Inactive users is:" ${number_of_inactive}
    # We are filtering via the id+Status (we can't sort by username because of https://bugster.forgerock.org/jira/browse/OPENAM-15464) 
    # The result is: "demo" [ "Active" ] "user.10" [ "Active" ] 
    # then with the first sed we add a comma after every ending bracket ']' - we will need this to add the result in an array
    # then with tr we remove all white spaces
    # with the second we remove the last comma
    # and finally with xargs we remove double quotation
    # The end result is demo[Active],user.10[Active]
    allusers=$(echo ${allusers} | jq '.result[]|._id,.inetUserStatus' | sed 's/]/],/g' | tr -d '\040\011\012\015' | sed 's/,$//g' | xargs)
    echo ${allusers5}
    # We are adding the previous string to an array using the comma as a separator
    IFS=',' read -r -a users_array <<< "$allusers"
    # we create another array (empty) for the inactive users
    declare -a inactive_users_array=()
    i=0 # this is the index number of the inactive users array
    echo "The inactive users are:"
    # we check all the entries of the users array and we check if they have the 'Inactive' in them
    for (( c=0; c<=$number_of_users; c++ ))
    do  
        if [[ ${users_array[$c]} =~ "Inactive" ]]; then 
                # we remove the "[Inactive]" from the entry "demo[Inactive]" and save the remained part into the ${inactive_users_array[$i]}
                inactive_users_array[$i]=$(echo ${users_array[$c]} | sed -e "s/Inactive//" |  sed 's/[][]//g')
                echo $(($i+1))"." ${inactive_users_array[$i]}
                i=$((i + 1))
        fi
    done
    echo "------------------------------------------------------------------------------"
    echo "REPORT OF THE ACTIVE SESSIONS AND TOKENS OF INACTIVE USERS"
    echo "------------------------------------------------------------------------------"
    total_sessions=0 # In the end we will print how many sessions we invalidated in total
    total_clients=0 # In the end we will print how many Clients' tokens we revoked in total
    for (( c=0; c<=$number_of_inactive -1; c++ ))
    do
        uid=${inactive_users_array[$c]}
        filter="username eq \"${uid}\" and realm eq \"$realm\""
        encoded_filter=$(urlencode "${filter}") # we use the urlencode function from the beginning of the script
        # Get the currently active sessions for the user
        current_sessions=$(curl -s --request GET \
        --header "Content-Type: application/json" \
        --header "Cookie: iPlanetDirectoryPro=${ipdp}" \
        "${openam_uri}/json/${realm_path}/sessions?_fields=sessionHandle&_queryFilter=${encoded_filter}")
        number_of_sessions=$(echo "${current_sessions}" | jq -r .resultCount | xargs)
        #echo "User "${uid}" has currently" "${number_of_sessions}" "active session(s)"
        #total_sessions=$((${total_sessions} + ${number_of_sessions}))
        # (another way to return the number of sessions)
        # echo ${current_sessions} | jq . | grep -o '\<sessionHandle\>' | wc -l

        if [ "${number_of_sessions}" != "0" ]; then 
            shandles=$(echo "${current_sessions}" | jq .result[].sessionHandle)
            # We replace the whitespaces with commas so we can use them in the next logoutByHandle request - there is no whitespace after the last entry
            shandles=$(echo ${shandles} | sed 's/ /,/g')
            echo "User "${uid}" has currently" "${number_of_sessions}" "active session(s)"
            total_sessions=$((${total_sessions} + ${number_of_sessions}))
            # Logout all AM sessions of the user
            sessions_logout=$(curl -s --request POST \
            --header "Content-Type: application/json" \
            --header "Accept-API-Version: protocol=2.1" \
            --header "iPlanetDirectoryPro: ${ipdp}" \
            --data "{\"sessionHandles\":[${shandles}]}" \
            "${openam_uri}/json/sessions?_action=logoutByHandle")
            # just checking if we invalidated the correct number of the sessions
            logout_result=$(echo "${sessions_logout}" | jq . | grep -o '\<true\>' | wc -l | xargs)
            if [ "${logout_result}" = "${number_of_sessions}" ]; then 
                echo "--> ${logout_result}" "session(s) of User "${uid}" invalidated successfully"
            else 
                echo "An error occured during invalidation of the sessions"
            fi
        else
            echo "No active AM sessions for user" "${uid}"
        fi
        
        # check the current tokens (this is actually checking the number of OAuth2 clients the user has access tokens)
        current_tokens=$(curl -s --request GET \
            --header "Content-Type: application/json" \
            --header "Accept-API-Version: protocol=2.1,resource=1.1" \
            --header "Cookie: iPlanetDirectoryPro=${ipdp}" \
            "${openam_uri}/json/${realm_path}/users/${uid}/oauth2/applications?_queryFilter=true&_fields=_id")
        #echo ${current_tokens}
        number_of_clients=$(echo "${current_tokens}" | jq -r .resultCount | xargs)
        
        if  [ "${number_of_clients}" != "0" ]; then 
            echo "The number of OAuth2 clients with active tokens for the user ${uid} is:" "${number_of_clients}"
            total_clients=$((${total_clients} + ${number_of_clients}))
            oauth2_clients=$(echo ${current_tokens} | jq .result[]._id)
            # We print the active OAuth2 clients and we will save them in an array
            oauth2_clients=$(echo ${oauth2_clients} | sed 's/ /,/g' | xargs)
            echo "The OAuth2 clients are:" "${oauth2_clients}"
            IFS=',' read -r -a oauth2_array <<< "$oauth2_clients"
            # Now we will revoke the active tokens for these Clients
            for (( z=0; z<=$number_of_clients -1; z++ ))
            do
                revoke_client=$(curl -s --write-out %{http_code} -X DELETE \
                --header "Content-Type: application/json" \
                --header "Accept-API-Version: protocol=2.1,resource=1.1" \
                --header "Cookie: iPlanetDirectoryPro=${ipdp}" \
                "${openam_uri}/json/${realm_path}/users/${uid}/oauth2/applications/${oauth2_array[$z]}")
                # The response from the HTTP DELETE doesn't include any message that the operation was successful, so I will check based on the HTTP code
                response_code=${revoke_client: -3}
                if [ $response_code != 200 ]; then 
                    echo "Failed to revoke the Client's tokens"
                else
                    echo "--> Successfully revoked the active OAuth2/OIDC tokens from the OAuth2 Client:" "${oauth2_array[$z]}"
                fi
            done
        else
            echo "No active OAuth2/OIDC tokens for user" "${uid}"
        fi
    done
    echo "------------------------------------------------------------------------------"
    echo "SUMMARY"
    echo "------------------------------------------------------------------------------"
    if  [ $total_sessions = 0 ]; then 
        echo "There wasn't any active session to invalidate, everything is fine"
    else
        echo "Invalidated" ${total_sessions} "sessions from total" ${number_of_inactive} "inactive users"
    fi
    if  [ $total_clients = 0 ]; then 
        echo "There wasn't any active tokens to revoke, everything is fine"
    else
        echo "Revoked active OAuth2/OIDC tokens from" ${total_clients} "OAuth2 Clients from total" ${number_of_inactive} "inactive users"
    fi
    echo "------------------------------------------------------------------------------"
    echo "END OF SCRIPT"
fi
