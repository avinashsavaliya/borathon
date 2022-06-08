cd alltkc
wget https://github.com/avinashsavaliya/borathon/blob/main/k8-stig.yaml -O k8-stig.yaml
kclist=$(ls | grep kubeconfig | head -n 5)

for i in $kclist
do
echo $i
kubectl --kubeconfig $i delete ns k8-stig || true
kubectl --kubeconfig $i create ns k8-stig || true
kubectl --kubeconfig $i -n k8-stig apply -f k8-stig.yaml || true
done
sleep 30
