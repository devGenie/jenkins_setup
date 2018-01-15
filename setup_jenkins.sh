#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

function update_hosts(){
    echo "________________________________________________________________________________"
    echo "                              UPDATING HOSTS                                    "

    local_ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
    host_name=$(hostname)
    echo ${local_ip} ${host_name} | sudo tee --append /etc/hosts
    echo '${host_name} ${local_ip}'
    echo "________________________________________________________________________________"
}

function update_system(){
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install language-pack-en-base -y
    sudo dpkg-reconfigure locales
    export LC_ALL=en_US.UTF-8

}

function add_repository_keys(){
    #jenkins keys
    wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -

    #software commons
    sudo apt-get install software-properties-common

    #java keys
    sudo add-apt-repository ppa:webupd8team/java
    echo deb https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list

    #docker keys
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-cache policy docker-ce
}

function install_java(){
    sudo apt-get -y install oracle-java8-installer
}

function install_docker(){
    sudo apt-get install -y docker-ce
}

function install_jenkins(){
    sudo apt-get install jenkins -y
    sudo apt-get install git -y

}

function configure_nginx(){
    sudo apt-get install nginx -y
    sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default-backup
    sudo cp jenkins_nginx_config /etc/nginx/sites-available/default
    sudo ln -sfn /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default   
}

function restart_services(){
    sudo sudo service nginx restart
    sudo service jenkins start
    sudo service jenkins status
}

function download_cli(){
    wget http://localhost:8080/jenkins/jnlpJars/jenkins-cli.jar
}

function install_plugins(){
    java -jar jenkins-cli.jar -s  http://localhost:8080/jenkins install-plugin \ 
http://updates.jenkins-ci.org/latest/build-monitor-plugin.hpi  -restart
}

function main(){
    update_hosts
    add_repository_keys
    update_system
    install_java
    install_jenkins
    install_docker
    configure_nginx
    restart_services

    password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    echo "Jenkins server running successfully, use the passsword below to login as administrator"
    echo "username: admin, password:${password}"
}

main

