#!/bin/bash
cd alltkc
wget https://raw.githubusercontent.com/avinashsavaliya/borathon/main/k8_stig_v1.yaml -O k8_stig_v1.yaml
wget https://raw.githubusercontent.com/shylpasharma/borathon/master/stig_scorer.py -O stig_scorer.py
kclist=$(ls | grep kubeconfig)
sshkeylist=$(ls | grep ssh)
# kclist=("tkg216-antrea-35ns5-c5-kubeconfig")
# sshkeylist=("tkg216-antrea-35ns5-c5-ssh")
for i in $kclist
do
echo $i
kubectl --kubeconfig $i delete ns k8-stig || true
kubectl --kubeconfig $i create ns k8-stig || true
kubectl --kubeconfig $i -n k8-stig apply -f k8_stig_v1.yaml || true
done
sleep 60
echo "tkcname,score" > k8sstigscore.csv
chmod 777 k8sstigscore.csv
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
cp_report=${kc/kubeconfig/"-control-node.json"}
worker_report=${kc/kubeconfig/"-worker-node.json"}
# run script on pod for cp node scan
echo "kubectl --kubeconfig $i exec $podname -n k8-stig -i -- /share/stig_scanner.sh $cpip $sshfile $cp_report > $cpresult"
kubectl --kubeconfig $i exec $podname -n k8-stig -i -- /share/stig_scanner.sh $cpip $sshfile $cp_report > $cpresult || true
sleep 10
# run script on pod for worker node scan
echo "kubectl --kubeconfig $i exec $podname -n k8-stig -i -- /share/stig_scanner.sh $workerip $sshfile $worker_report > $workerresult" 
kubectl --kubeconfig $i exec $podname -n k8-stig -i -- /share/stig_scanner_worker.sh $workerip $sshfile $worker_report > $workerresult || true
sleep 10
# copy control node report file from pod to host
echo "kubectl --kubeconfig $i -n k8-stig cp $podname:/share/$cp_report /root/alltkc/ || true"
kubectl --kubeconfig $i -n k8-stig cp $podname:/share/$cp_report /root/alltkc/ || true
# copy worker node report file from pod to host
echo "kubectl --kubeconfig $i -n k8-stig cp $podname:/share/$worker_report /root/alltkc/ || true"
kubectl --kubeconfig $i -n k8-stig cp $podname:/share/$worker_report /root/alltkc/ || true
python3 stig_scorer.py $cpresult $workerresult "k8sstigscore.csv"
done

