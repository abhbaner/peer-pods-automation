#!/bin/bash
echo "Initializing Terraform"
terraform init
echo "Running Terraform automation"
terraform apply --auto-approve
echo "Storing hosts information"
terraform output > output_cloud.txt
cat output_cloud.txt
### Extracting public and private IPs of all the 3VMs and assigning them to vars ###
ANSIBLE_PUBLIC="$(grep -E 'ansibleMaster_public_ips' output_cloud.txt)"
ANSIBLE_PRIVATE="$(grep -E 'ansibleMaster_private_ips' output_cloud.txt)"
K8SMASTER_PUBLIC="$(grep -E 'k8smaster_public_ip' output_cloud.txt)"
K8SMASTER_PRIVATE="$(grep -E 'k8smaster_private_ip' output_cloud.txt)"
K8SWORKER_PUBLIC="$(grep -E 'k8sworker_public_ips' output_cloud.txt)"
K8SMASTER_PRIVATE="$(grep -E 'k8smaster_private_ip' output_cloud.txt)"
splitfunc(){
    OIFS=$IFS
    IFS=$'='
    echo $1
    CTR=0
    for x in $1
    do
        if [ $CTR == 1 ]  
        then
            echo "Returning $x"   
        fi
        CTR=$((CTR+1))
    done  
    retval=$x  
}

splitfunc "$ANSIBLE_PUBLIC"
ansible_pub_ip=$retval
splitfunc "$ANSIBLE_PRIVATE"
ansible_priv_ip=$retval
splitfunc "$K8SMASTER_PUBLIC"
k8smaster_pub_ip=$retval
splitfunc "$K8SMASTER__PRIVATE"
k8smaster_priv_ip=$retval
splitfunc "$K8SWORKER_PUBLIC"
k8sworker_pub_ip=$retval
splitfunc "$K8SWORKER_PRIVATE"
k8sworker_priv_ip=$retval

echo $ansible_pub_ip
echo $ansible_priv_ip
echo $k8smaster_pub_ip
echo $k8smaster_priv_ip
echo $k8sworker_pub_ip
echo $k8sworker_priv_ip


