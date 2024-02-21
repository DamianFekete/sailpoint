j-help() {
    local jq_file="$HOME/.jq"
    
    # Check if jq file exists
    if [ ! -e "$jq_file" ]; then
        echo "Error: The file $jq_file does not exist. Please configure it with the required jq functions."
        return 1
    fi

    # Check if jq file contains required strings
    if ! grep -q -e 'lpad' -e 'rpad' -e 'timestamp_to_local_time' -e 'timestamp_to_local_datetime' "$jq_file"; then
        echo 'Error: The $jq_file file does not contain the required jq functions. Configuration is needed!'
        return 1
    fi

    echo 'Usage:'
    echo '  cat ~/log/ccg.log | [j-last-minutes N] | [j-filter-...] | [j-log-...] | less'
    echo 'Usage Examples:'
    echo '  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-types "ServiceNow" "SAP - Direct" | j-log-2 | less'
    echo ''
    echo '  Show "AppTypes | Application names" to be used for filtering'
    echo '  $ tail -10000 ~/log/ccg.log | j-apps-unique'
    echo '  Filter by app type'
    echo '  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-types "ServiceNow" "SAP - Direct"'
    echo '  Filter by app names (one or more)'
    echo '  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-names "ServiceNow - A [source]" "ServiceNow - B [source]"'
    echo '  Filter by app type, but exclude some apps'
    echo '  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-types "ServiceNow" | j-filter-by-app-names-exclude "ServiceNow - A"'
    echo '  CCG messages not related to an app'
    echo '  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-no-app-name'
    echo '  Log with different formats'
    echo '  ... | j-log-1 | less'
    echo '  ... | j-log-2 | less'
    echo '  ... | j-log-3 | less'
    echo '  ... | j-log-detailed | less'
    echo '  ... | jq | less'
    echo "  Ignore lines that don't begin with {"
    echo '  $ tail -10000 ~/log/ccg.log | j-json-only | ...'
    echo ''
    echo '  $ tail -10000 ~/log/ccg.log | jq-log-2 | less'
    echo '  $ tail -10000 ~/log/ccg.log | j-filter-... | jq-log-2 | less'
}

# Call the function
j-help

j-last-minutes() { grep ^{ | jq -rc "select((now - (.[\"@timestamp\"][0:19] + \"Z\" | fromdate)) <= ($1 * 60)) | ."; }
j-apps-unique() { grep ^{ | jq -r '[.AppType, "|", .Application] | @tsv' | sort | uniq; }

# j-filter-by-app-names "ServiceNow - Cashier [source]" "ServiceNow - Pre Prod - External [source]"
j-filter-by-app-names() { 
result=""
    for arg in "$@"; do
        result+="\"$arg\", "
    done
    result=${result%, }  # Remove the trailing comma and space
    jq -rc "select(.Application | IN ($result))"; 
}

# j-filter-by-app-names-exclude "ServiceNow - Cashier [source]" "ServiceNow - Pre Prod - External [source]"
j-filter-by-app-names-exclude() { 
result=""
    for arg in "$@"; do
        result+="\"$arg\", "
    done
    result=${result%, }  # Remove the trailing comma and space
    jq -rc "select(.Application | IN ($result) | not)"; 
}

j-filter-by-no-app-name() { 
result=""
    for arg in "$@"; do
        result+="\"$arg\", "
    done
    result=${result%, }  # Remove the trailing comma and space
    jq -rc "select(.Application == null)"; 
}

# j-filter-by-app-types "ServiceNow" "SAP - Direct"
j-filter-by-app-types() { 
result=""
    for arg in "$@"; do
        result+="\"$arg\", "
    done
    result=${result%, }  # Remove the trailing comma and space
    jq -rc "select(.AppType| IN ($result))"; 
}

j-log-1() {
    jq -r '[(."@timestamp" | timestamp_to_local_time), .level, (.Operation | rpad(15;" "))[0:15], .message, .exception.exception_message] | @tsv'
}

j-log-2() {
    jq -r '[(."@timestamp" | timestamp_to_local_datetime), .level, (.Operation | rpad(15;" "))[0:15], (.method | rpad(20;" "))[0:20], .message, .exception.exception_message] | @tsv'
}

j-log-3() {
    jq -r '[."@timestamp", .level, (.Application | select (. != null) | sub(" \\[source\\]"; "") | rpad(30;" "))[0:20], (.Operation | rpad(15;" "))[0:15], (.method | rpad(20;" "))[0:20], .message, .exception.exception_message] | @tsv'
}


j-log-detailed() {
    jq -r '[."@timestamp", .level, .Application, .Operation, .method, .message, .exception.exception_message] | @tsv'
}

j-json-only() {
    grep ^{
}
