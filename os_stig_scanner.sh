#!/bin/bash
cd /share/photon-3-stig-inspec-baseline
echo "inspec exec . --chef-license accept -t ssh://vmware-system-user@$1 -i /share/$2 --sudo --reporter=cli json:/share/output.json"
inspec exec . --chef-license accept -t ssh://vmware-system-user@$1 -i /share/$2 --sudo --reporter=cli json:/share/output.json 
