#!/bin/bash
cd /share/kubernetes-stig-baseline
echo "inspec exec . --chef-license accept -t ssh://vmware-system-user@$1 -i /share/$2 --sudo --reporter=cli json:/share/$3"
inspec exec . --chef-license accept -t ssh://vmware-system-user@$1 -i /share/$2 --sudo --reporter=cli json:/share/$3
