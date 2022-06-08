#!/bin/bash
cd /share/kubernetes-stig-baseline
echo "inspec exec . -t ssh://vmware-system-user@$1 -i /share/$2 --sudo --reporter=cli json:/share/output.json"
inspec exec -t ssh://vmware-system-user@$1 -i /share/$2 --sudo --reporter=cli json:/share/output.json 
