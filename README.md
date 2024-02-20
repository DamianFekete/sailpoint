## j-tools

Basic helper bash functions to process the SailPoint ccg.log directly on the VA machine.

The current alternative is to copy the ccg.log file everytime you want too check the last lines appended to it. The file can be huge, or you may not want to truncate the (production) file.

### Setup

The tool [jq](https://jqlang.github.io/jq/) is already installed on the VA (unfortunately a buggy version, probably an older version). `jq` is very powerful, but writing a jq pipeline manually everytime is time consuming.

1. Create necessary jq helper functions. 
```sh
mkdir -p /home/sailpoint/bin

cat<<EOL >> ~/.jq
def lpad(len; fill): fill * (len - length) + .;
def rpad(len; fill): . + fill * (len - length);
def timestamp_to_local_time: . | sub("\\\\.\\\\d{3}Z";"Z") | fromdate | strflocaltime("%H:%M:%S");
def timestamp_to_local_datetime: . | sub("\\\\.\\\\d{3}Z";"Z") | fromdate | strflocaltime("%Y-%m-%d %H:%M:%S");
EOL
```
2. Copy the [/j-tools/j-tools.sh](/j-tools/j-tools.sh) to the Virtual Appliance (e.g. to `/home/sailpoint/bin/j-tools.sh`), 

3. Load the bash functions after logging into the VA:
```sh
. ~/bin/j-tools
```

### **j-help** (prints usage):
```sh
$ j-help
Usage:
  cat ~/log/ccg.log | [j-last-minutes N] | [j-filter-...] | [j-log-...] | less

Usage Examples:
  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-types "ServiceNow" "SAP - Direct" | j-log-2 | less

  Show "AppTypes | Application names" to be used for filtering
  $ tail -10000 ~/log/ccg.log | j-apps-unique
  Filter by app type
  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-types "ServiceNow" "SAP - Direct"
  Filter by app names (one or more)
  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-names "ServiceNow - A [source]" "ServiceNow - B [source]"
  Filter by app type, but exclude some apps
  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-types "ServiceNow" "ServiceNow" | j-filter-by-app-names-exclude "ServiceNow - A"
  CCG messages not related to an app
  $ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-no-app-name
  Log with different formats
  ... | j-log-1 | less
  ... | j-log-2 | less
  ... | j-log-3 | less
  ... | j-log-detailed | less
  ... | jq | less

  $ tail -10000 ~/log/ccg.log | jq-log-2 | less
  $ tail -10000 ~/log/ccg.log | j-filter-... | jq-log-2 | less

```

### Examples

#### Common usage if you are doing something manually in the interface and want to see the logs for that action:

* Use `j-apps-unique` to check which sources are of interest for you
* Check the last ~1000 lines, filter for the last 3-5 minutes and pretty print the info using j-log-1 or j-log-2 (depending how wide your screen is)
```sh
tail -1000 ~/log/ccg.log | j-last-minutes 3 | j-filter-by-app-names "ServiceNow - XYZ [source]" | j-log-2
```



#### j-apps-unique
```
sailpoint@SVID01234 ~ $ tail -10000 ~/log/ccg.log | j-apps-unique
        |
Active Directory - Direct       |       AD Testing [source]
Active Directory - Direct       |       Active Directory Test  [source]
IdentityNow     |       DEV-IAM-SVID01234 [cluster-999]
SAP - Direct    |       SAP Test [source]
SAP - Direct    |       SAP_XXX_100 [source]
SAP - Direct    |       SAP_YYY_300 [source]
SAP - Direct    |       SAP_ZZZ_100 [source]
SCIM 2.0        |       SCIM 2 Test [source]
ServiceNow      |       ServiceNow - Cashier [source]
ServiceNow      |       ServiceNow - Pre Prod - Internal [source]
ServiceNow      |       ServiceNow - Pre prod - Other [source]
ServiceNow      |       ServiceNow - Supplier [source]
ServiceNow      |       ServiceNow [source]
Web Services    |
```

**Tip**: Append ` | less` if checking more than a couple of minutes of logs.

#### **j-log-1** (local time , level , operation , message , exception)
```sh
$ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-names "ServiceNow - Cashier [source]" | j-log-1

15:22:34        INFO    Create          Provisioning [Create] for account [12345] starting.
15:22:35        INFO    Create          Dumping Provisioning Plan details  : <?xml version='1.0' encoding='UTF-8'?>\n<!DOCTYPE ProvisioningPlan PUBLIC "sailpoint.dtd" "sailpoint.dtd">\n<ProvisioningPlan nativeIdentity="12345">\n  ....lan>\n
15:57:28        INFO    DoHealthCheck   Creating headers for Basic Authentication.
```

#### **j-log-2** (local date & time , level , operation , method , message , exception)
```sh
$ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-names "ServiceNow - Cashier [source]" | j-log-2

2024-02-20 15:22:34     INFO    Create          logProvisioningStart    Provisioning [Create] for account [12345] starting.
2024-02-20 15:22:35     INFO    Create          logMe                   Dumping Provisioning Plan details  : <?xml version='1.0' encoding='UTF-8'?>\n<!DOCTYPE ProvisioningPlan PUBLIC "sailpoint.dtd" "sailpoint.dtd">\n<ProvisioningPlan nativeIdentity="12345">\n  ....lan>\n
2024-02-20 15:57:28     INFO    DoHealthCheck   createHeaders           Creating headers for Basic Authentication.
```

#### **j-log-3** (UTC time , level , application, operation , method , message , exception)
```sh
$ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-names "ServiceNow - Cashier [source]" | j-log-3
2024-02-20T14:22:34.783Z        INFO    ServiceNow - Cashier    Create          logProvisioningStart    Provisioning [Create] for account [12345] starting.
2024-02-20T14:22:35.374Z        INFO    ServiceNow - Cashier    Create          logMe                   Dumping Provisioning Plan details  : <?xml version='1.0' encoding='UTF-8'?>\n<!DOCTYPE ProvisioningPlan PUBLIC "sailpoint.dtd" "sailpoint.dtd">\n<ProvisioningPlan nativeIdentity="12345">\n  ....lan>\n
2024-02-20T14:57:28.923Z        INFO    ServiceNow - Cashier    DoHealthCheck   createHeaders           Creating headers for Basic Authentication.
```

#### **j-log-detailed** (as j-log-3 but the fields are not truncated if too long, and not vertically aligned)
```sh
$ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-names "ServiceNow - Cashier [source]" | j-log-detailed

2024-02-20T14:22:34.783Z        INFO    ServiceNow - Cashier [source]   Create  logProvisioningStart    Provisioning [Create] for account [12345] starting.
2024-02-20T14:22:35.374Z        INFO    ServiceNow - Cashier [source]   Create  logMe   Dumping Provisioning Plan details  : <?xml version='1.0' encoding='UTF-8'?>\n<!DOCTYPE ProvisioningPlan PUBLIC "sailpoint.dtd" "sailpoint.dtd">\n<ProvisioningPlan nativeIdentity="12345">\n  ....lan>\n
2024-02-20T14:57:28.923Z        INFO    ServiceNow - Cashier [source]   DoHealthCheck   createHeaders   Creating headers for Basic Authentication.
```

#### **jq**
```sh
$ tail -10000 ~/log/ccg.log | j-last-minutes 15 | j-filter-by-app-names "ServiceNow - Cashier [source]" | jq | less

{
  "stack": "ccg",
  "pod": "stg02-eucentral1",
  "connector-logging": "150",
  "Operation": "DoHealthCheck",
  "clusterId": "123",
  "buildNumber": "948",
  "apiUsername": "d3b12f72-9f94-4801-8e52-9a4b600aa8cc",
  "orgType": "",
  "file": "ServiceNowConnector.java",
  "encryption": "1266",
  "messageType": "do-health-check",
  [...]
}
[...]
```

### #TODO:

#### Skip non-json lines
If jq encounters a line that is not a json, it will display a similar error message (and stop processing following lines!):  
`jq: parse error: Invalid numeric literal at line 9238, column 6`

A newer version of `jq` that can be used to ignore non-json lines (see [Update jq on the VA](https://developer.sailpoint.com/discuss/t/update-jq-on-the-va-r-read-raw-strings-not-json-texts/27939)) should be used. Using `fromjson?` could be used to skip offendling lines.
```
curl -o ~/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
alias jq=~/bin/jq
```

