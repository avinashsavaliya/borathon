#!/bin/bash
cd alltkc
wget https://raw.githubusercontent.com/avinashsavaliya/borathon/main/k8_stig_v1.yaml -O k8_stig_v1.yaml
# kclist=$(ls | grep kubeconfig | head -n 2)
# sshkeylist=$(ls | grep ssh | head -n 2)
kclist=("tkg216-antrea-35ns5-c5-kubeconfig")
sshkeylist=("tkg216-antrea-35ns5-c5-ssh")
for i in $kclist
do
echo $i
kubectl --kubeconfig $i delete ns k8-stig || true
kubectl --kubeconfig $i create ns k8-stig || true
kubectl --kubeconfig $i -n k8-stig apply -f k8_stig_v1.yaml || true
done
sleep 30
for i in $kclist
do
kc=$i
sshfile=${kc/kubeconfig/"ssh"}
#retrieve pod name
a=$(kubectl --kubeconfig $i -n k8-stig get pods -o=custom-columns="DATA:.metadata.name" || true)
b=($a) || true
podname=${b[1]} || true
# copy ssh file from host to pod
echo "kubectl --kubeconfig $i -n k8-stig cp $sshfile $podname:/share/ || true"
kubectl --kubeconfig $i -n k8-stig cp $sshfile $podname:/share/ || true
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
cpresult=${kc/kubeconfig/"cp.text"}
workerresult=${kc/kubeconfig/"worker.text"}
# run script on pod for cp node scan
echo "kubectl --kubeconfig $i exec $podname -n k8-stig -i -- /share/stig_scanner.sh $cpip $sshfile > $cpresult"
kubectl --kubeconfig $i exec $podname -n k8-stig -i -- /share/stig_scanner.sh $cpip $sshfile > $cpresult || true
sleep 10
# run script on pod for worker node scan
echo "kubectl --kubeconfig $i exec $podname -n k8-stig -i -- /share/stig_scanner.sh $workerip $sshfile > $workerresult" 
kubectl --kubeconfig $i exec $podname -n k8-stig -i -- /share/stig_scanner_worker.sh $workerip $sshfile > $workerresult || true
sleep 10
done
