cd alltkc
wget https://github.com/avinashsavaliya/borathon/blob/main/k8-stig.yaml -O k8-stig.yaml
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
ssh="ssh"
sshfile=${kc/kubeconfig/"$ssh"}
#retrieve pod name
a=$(kubectl --kubeconfig $i -n k8-stig get pods -o=custom-columns="DATA:.metadata.name" || true)
b=($a) || true
podname=${b[1]} || true
# copy ssh file from host to pod
kubectl --kubeconfig $i cp $sshfile $podname:/share/
# run script on pod
kubectl --kubeconfig $i exec $podname -i -t  -- /share/test.sh 10.244.12.242 $sshfile > alltkc/check.text

done
sleep 30
