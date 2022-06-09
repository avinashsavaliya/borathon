#!/bin/bash
cd /share/kubernetes-stig-baseline
echo "inspec exec . --chef-license accept -t ssh://vmware-system-user@$1 -i /share/$2 --sudo --reporter=cli json:/share/output.json --controls=V-242387 V-242391 V-242392 V-242393 \
    V-242394 V-242396 V-242397 V-242398 V-242399 \
    V-242400 V-242404 V-242406 V-242407 V-245541 \
    V-242420 V-242425 V-242434 V-242449 V-242450 \
    V-242451 V-242452 V-242453 V-242454 V-242455 \
    V-242456 V-242457 V-242466"
inspec exec . --chef-license accept -t ssh://vmware-system-user@$1 -i /share/$2 --sudo --reporter=cli json:/share/output.json --controls=V-242387 V-242391 V-242392 V-242393 \
    V-242394 V-242396 V-242397 V-242398 V-242399 \
    V-242400 V-242404 V-242406 V-242407 V-245541 \
    V-242420 V-242425 V-242434 V-242449 V-242450 \
    V-242451 V-242452 V-242453 V-242454 V-242455 \
    V-242456 V-242457 V-242466
