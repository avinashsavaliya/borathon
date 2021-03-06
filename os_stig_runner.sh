#!/bin/bash
cd alltkc
wget https://raw.githubusercontent.com/avinashsavaliya/borathon/main/os_stig_scan_v1.yaml -O os_stig_scan_v1.yaml
wget https://raw.githubusercontent.com/shylpasharma/borathon/master/stig_scorer.py -O stig_scorer.py
kclist=$(ls | grep kubeconfig)
sshkeylist=$(ls | grep ssh)
# kclist=("tkg216-antrea-35ns5-c5-kubeconfig")
# sshkeylist=("tkg216-antrea-35ns5-c5-ssh")
for i in $kclist
do
echo $i
kubectl --kubeconfig $i delete ns os-stig || true
kubectl --kubeconfig $i create ns os-stig || true
kubectl --kubeconfig $i -n os-stig apply -f os_stig_scan_v1.yaml || true
done
sleep 60
echo "tkcname,score" > osstigscore.csv
chmod 777 osstigscore.csv
for i in $kclist
do
kc=$i
sshfile=${kc/kubeconfig/"ssh"}
#retrieve pod name
a=$(kubectl --kubeconfig $i -n os-stig get pods -o=custom-columns="DATA:.metadata.name" || true)
b=($a) || true
podname=${b[1]} || true
# copy ssh file from host to pod
echo "kubectl --kubeconfig $i -n os-stig cp $sshfile $podname:/share/ || true"
kubectl --kubeconfig $i -n os-stig cp $sshfile $podname:/share/ || true
#retrieve controlplane and worker node ip
ips=$(kubectl --kubeconfig $i get nodes -o json | jq '.items[].status.addresses[] | select(.type=="InternalIP") | .address'|| true)
op=($ips) || true
cpip=${op[0]} || true
workerip=${op[1]} || true
#reemove first and last double quotes
cpip=`sed -e 's/^"//' -e 's/"$//' <<<"$cpip"`
workerip=`sed -e 's/^"//' -e 's/"$//' <<<"$workerip"`
echo $cpip
echo $workerip
cpresult=${kc/kubeconfig/"cp-os.text"}
workerresult=${kc/kubeconfig/"worker-os.text"}
cp_report=${kc/kubeconfig/"control-node-os-stig.json"}
worker_report=${kc/kubeconfig/"worker-node-os-stig.json"}
# run script on pod for cp node scan
echo "kubectl --kubeconfig $i exec $podname -n os-stig -i -- /share/os_stig_scanner.sh $cpip $sshfile $cp_report > $cpresult"
kubectl --kubeconfig $i exec $podname -n os-stig -i -- /share/os_stig_scanner.sh $cpip $sshfile $cp_report > $cpresult || true
sleep 10
# run script on pod for worker node scan
echo "kubectl --kubeconfig $i exec $podname -n os-stig -i -- /share/os_stig_scanner.sh $workerip $sshfile $worker_report > $workerresult" 
kubectl --kubeconfig $i exec $podname -n os-stig -i -- /share/os_stig_scanner.sh $workerip $sshfile $worker_report > $workerresult || true
sleep 10
# copy control node report file from pod to host
echo "kubectl --kubeconfig $i -n os-stig cp $podname:/share/$cp_report $worker_report|| true"
kubectl --kubeconfig $i -n os-stig cp $podname:/share/$cp_report $cp_report  || true
# copy worker node report file from pod to host
echo "kubectl --kubeconfig $i -n os-stig cp $podname:/share/$worker_report $worker_report || true"
kubectl --kubeconfig $i -n os-stig cp $podname:/share/$worker_report $worker_report  || true
python3 stig_scorer.py $cpresult $workerresult "osstigscore.csv"
done
