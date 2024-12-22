#!/bin/bash

component=$1
environment=$2
#printing the above variable.
echo -e "component:${$component}, environment:${$environment}"
dnf install ansible -y 
ansible-pull -i localhost -U https://github.com/promptforai/expense-ansible-roles-tf.git main.yaml -e component=$component -e environment=$environment