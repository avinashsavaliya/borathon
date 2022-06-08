cd alltkc
wget https://github.com/avinashsavaliya/borathon/blob/main/k8_stig_v1.yaml -O k8_stig_v1.yaml
kclist=$(ls | grep kubeconfig | head -n 2)
sshkeylist=$(ls | grep ssh | head -n 2)
for i in $kclist
do
echo $i
kubectl --kubeconfig $i delete ns k8-stig || true
kubectl --kubeconfig $i create ns k8-stig || true
kubectl --kubeconfig $i -n k8-stig apply -f k8-stig.yaml || true
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
kubectl --kubeconfig $i cp $sshfile $podname:/share/ || true
#retrive controlplane and worker node ip
ips=$(kubectl --kubeconfig $i get nodes -o json | jq '.items[].status.addresses[] | select(.type=="InternalIP") | .address'|| true)
op=($ips) || true
cpip=${op[0]} || true
workerip=${op[1]} || true
echo $cpip
echo $workerip
cpresult=${kc/kubeconfig/"cp.text"}
workerresult=${kc/kubeconfig/"worker.text"}
# run script on pod for cp node
kubectl --kubeconfig $i exec $podname -i -t  -- /share/stig_scanner.sh $cpip $sshfile > alltkc/$cpresult
done
sleep 30
