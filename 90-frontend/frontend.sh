#!/bin/bash

component=$1
environment=$2

echo -e "component=$component and environment=$environment"
dnf install ansible -y 
ansible-pull -i localhost, -U https://github.com/promptforai/expense-ansible-roles-tf.git main.yaml -e component=$component -e environment=$environment
