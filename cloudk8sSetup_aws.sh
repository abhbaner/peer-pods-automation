#!/bin/bash
: <<'END_COMMENT'
Prerequisite 
set env vars for security key (to access cloud VMs) path and name 

VMSSHKEY, see below
'export VMSSHKEY=/path/to/ec2-ssh-key'

VMSSHKEY_NAME see below
'export VMSSHKEY_NAME='secuerity key name eg: testkey.pem'


This script does the below 
- Run Terraform automation
- Extract IP information from Terraform output
- Add host entries to all the nodes ( Ansible Master, k8s Master,  k8s worker)
- Add public ssh key of Ansible master in k8s nodes
- Install Ansible on the Ansible master node
- Execute playbooks to install k8s cluster (k8s-pkg.yml, k8s-master.yml,k8s-worker.yml)
  and install k8s networking
END_COMMENT

# Running Terraform Automation
echo "****** Initializing Terraform ******"
terraform init
echo "****** Running Terraform automation ******"
terraform apply --auto-approve
echo "****** Storing hosts information ******"
terraform output > output_cloud.txt
cat output_cloud.txt

### Extracting public and private IPs of all the 3VMs and assigning them to vars ###
ANSIBLE_PUBLIC="$(grep -E 'ansibleMaster_public_ips' output_cloud.txt)"
ANSIBLE_PRIVATE="$(grep -E 'ansibleMaster_private_ips' output_cloud.txt)"
K8SMASTER_PUBLIC="$(grep -E 'k8smaster_public_ip' output_cloud.txt)"
K8SMASTER_PRIVATE="$(grep -E 'k8smaster_private_ip' output_cloud.txt)"
K8SWORKER_PUBLIC="$(grep -E 'k8sworker_public_ips' output_cloud.txt)"
K8SMASTER_PRIVATE="$(grep -E 'k8smaster_private_ip' output_cloud.txt)"
getIP(){    #Gets the IP value  
    OIFS=$IFS
    IFS=$'=' #split string 
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
    x="${x//\"}" #remote quotation and remove the leading space
    ip="${x:1}"
    retval=$ip
    
}

getIP "$ANSIBLE_PUBLIC"
ansible_pub_ip=$retval
getIP "$ANSIBLE_PRIVATE"
ansible_priv_ip=$retval
getIP "$K8SMASTER_PUBLIC"
k8smaster_pub_ip=$retval
getIP "$K8SMASTER__PRIVATE"
k8smaster_priv_ip=$retval
getIP "$K8SWORKER_PUBLIC"
k8sworker_pub_ip=$retval
getIP "$K8SWORKER_PRIVATE"
k8sworker_priv_ip=$retval

#Adding entries to /etc/hosts of all nodes
USERNAME='ubuntu@'
HOSTENTRY1="echo $ansible_priv_ip ansible@example.com  ansible | sudo tee -a /etc/hosts"
HOSTENTRY2="echo $k8smaster_priv_ip k8smaster@example.com  k8smaster | sudo tee -a /etc/hosts"
HOSTENTRY3="echo $k8sworker_priv_ip ansible@example.com  k8sworker| sudo tee -a /etc/hosts"

for HOSTIP in $ansible_pub_ip $k8smaster_pub_ip $k8sworker_pub_ip ; do
    for CMD in $HOSTENTRY1 $HOSTENTRY2 $HOSTENTRY3 ; do
        echo "****** Adding host entries in $HOSTIP ******"
        ssh -o StrictHostKeyChecking=no -i $VMSSHKEY ${USERNAME}${HOSTIP} "${CMD}"
    done    
done

#generating ssh key on Ansible node and adding them to k8s node's authorized key
echo "****** Copying ec2 key from execution server to ansible node ******"
scp -i $VMSSHKEY_NAME $VMSSHKEY ${USERNAME}${ansible_pub_ip}:/tmp
echo "****** Generating SSH key on the Ansible master and copying it to k8s node ******"
ssh -o StrictHostKeyChecking=no -i $VMSSHKEY ${USERNAME}${ansible_pub_ip} << END
    echo -e "\n\n\n" | ssh-keygen -t rsa
    cd ~/.ssh
    cp /tmp/$VMSSHKEY_NAME .
    echo "scp to k8s master>>>>>>>>>>>>>>"
    scp -o StrictHostKeyChecking=no -i $VMSSHKEY_NAME id_rsa.pub ubuntu@k8smaster:/tmp
    echo "scp to k8s worker>>>>>>>>>>>>>>"
    scp -o StrictHostKeyChecking=no -i $VMSSHKEY_NAME id_rsa.pub ubuntu@k8sworker:/tmp
    pwd
END

echo "****** Appending authorizedkey file on k8s node with Ansible node's public key ******"
ssh -o StrictHostKeyChecking=no -i $VMSSHKEY ${USERNAME}${k8smaster_pub_ip} << END
    cd /tmp
    cat id_rsa.pub >> ~/.ssh/authorized_keys
END
echo "Ansible public key successfully added to k8s master"
 
ssh -o StrictHostKeyChecking=no -i $VMSSHKEY ${USERNAME}${k8sworker_pub_ip} << END
    cd /tmp
    cat id_rsa.pub >> ~/.ssh/authorized_keys
END
echo "Ansible public key successfully added to k8s worker"
