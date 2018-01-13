#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

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
    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default-backup
    sudo cp jenkins_nginx_config /etc/nginx/sites-available/default
    sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    sudo nginx -t && sudo service nginx restart     
}

function restart_services(){
    sudo nginx -t && sudo service nginx restart
    sudo service jenkins start
    sudo service jenkins status
}

function main(){
    add_repository_keys
    update_system
    install_java
    install_jenkins
    install_docker
    configure_nginx
    restart_services
}

main

