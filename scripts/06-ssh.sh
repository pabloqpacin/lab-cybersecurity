#!/usr/bin/env bash

#~~ #6: Securing Remote Access
# ~~# Page 13 - Chapter 1


client_config(){

    # Generate SSH keys if don't exist
    [ ! -f ~/.ssh/id_rsa ] && ssh-keygen
        # OK default location
        # DO passphrase to secure private key

    # Share pubkey to servers
    read -p "Enter your username on the server: " server_user
    read -p "Enter your the server IP address: " server_ip
    ssh-copy id $server_user@$server_ip
        # say yes

    # Connect to server
    ssh $server_user@$server_ip
        # enter passphrase to use them keys

    # unset server_user
    # unset server_ip
}

server_config(){

}


if true; then
    case $opt in
        foo) client_config ;;
        bar) server_config ;;
    esac
fi