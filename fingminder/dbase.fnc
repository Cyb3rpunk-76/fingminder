#!/bin/bash
OS_SERVERNAME="Raspberry pi 3"                     # Name to reference the server that running fingminder shells set
OS_USER=pi
OS_ADMINEMAIL=darney.lampert@gmail.com             # put here the admin email that will be receive notifications, video files
DB_HOST=10.10.10.17
DB_USER=pi                                         # Here put DB user ( DB Server can be MySQL or DBMaria )
DB_PASSWD=$(cat /home/$OS_USER/.bin/.pw/pass.key)  # here, same how, put the password to DB_USER
DB_NAMEBASE=ecg54                                  # Database name for network monitor tables
