#!/bin/bash

#echo Your container args are: "$@"

for ARGUMENT in "$@"
do
    case "$ARGUMENT" in
       INVENTORY_PATH=*)
         INVENTORY_PATH="${ARGUMENT#*=}"
         ;;
       SERVERS=*)
         SERVERS="${ARGUMENT#*=}"
         ;;
       SSH_IDRSA=*)
         SSH_IDRSA="${ARGUMENT#*=}"
         ;;
       PLAYBOOK_PATH=*)
         PLAYBOOK_PATH="${ARGUMENT#*=}"
         ;;
       VARS_PATH=*)
         VARS_PATH="${ARGUMENT#*=}"
         ;;
       VAULT_PATH=*)
         VAULT_PATH="${ARGUMENT#*=}"
         ;;
       EXTRA_VARS=*)
         EXTRA_VARS="${ARGUMENT#*=}"
         ;;
       VAULT_FILE=*)
         VAULT_FILE="${ARGUMENT#*=}"
         ;;
       CERT=*)
         CERT="${ARGUMENT#*=}"
         ;;
       KEY=*)
         KEY="${ARGUMENT#*=}"
         ;;
       AMA_CERT=*)
         AMA_CERT="${ARGUMENT#*=}"
         ;;
       *)
    esac
done

# If there is no argument provided enter in shell
if [ $# -eq 0 ]; then
    /bin/sh
    exit 1
fi

if [ -v VAULT_FILE ]
then
echo ::::: Decrypt Vault file :::::
eval "ansible-vault decrypt --vault-password-file $VAULT_FILE $VAULT_PATH"
exit 0
fi


if [ -v CERT ]
then
#Decode and save certficate in /var/certs directory
echo
echo ::::: Decode jenkins_caap01t cerificate :::::
printf "$CERT" | base64 -d > /var/certs/jenkins_caap01t.pem
chmod 644 /var/certs/jenkins_caap01t.pem
fi

if [ -v KEY ]
then
#Decode and save key in /var/certs directory
echo
echo ::::: Decode jenkins_caap01t key :::::
printf "$KEY" | base64 -d > /var/certs/jenkins_caap01t_to_cyberark.key
chmod 644 /var/certs/jenkins_caap01t_to_cyberark.key
fi

if [ -v AMA_CERT ]
then
#Adding the Amadeus Root Certificate to cacert for client certificate validation
echo
echo ::::: Decode and append ROOT CERT for validation :::::
printf "$AMA_CERT" | base64 -d >> $(python -m certifi)
fi


if [ -v SSH_IDRSA ]
then
#Decode and save ID_RSA to jenkins home directory
echo
echo ::::: Decode id_rsa :::::
printf "$SSH_IDRSA" | base64 -d > /home/jenkins/.ssh/id_rsa
chmod 600 /home/jenkins/.ssh/id_rsa

echo
echo ::::: RUN SSH-AGENT :::::
eval $(ssh-agent)

#Load key + passphrase to ssh-agent
echo
echo ::::: ADD KEY + PASSPHRASE TO SSH-AGENT :::::
DISPLAY=1 SSH_ASKPASS="/home/jenkins/.ssh/passphrase.sh" ssh-add /home/jenkins/.ssh/id_rsa < /dev/null

# Add repository.secure.ifao.net to know_hosts in order to install roles from repo
mkdir ~/.ssh/
ssh-keyscan -p 7999 repository.secure.ifao.net >> ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
fi

EXECUTION_CMD=ansible-playbook

if [ -v INVENTORY_PATH ]; then
  EXECUTION_CMD="$EXECUTION_CMD $PLAYBOOK_PATH -i $INVENTORY_PATH"
elif [ -v SERVERS ]; then
  EXECUTION_CMD="$EXECUTION_CMD $PLAYBOOK_PATH -i $INVENTORY_PATH -l localhost,$SERVERS"
else
  EXECUTION_CMD="$EXECUTION_CMD $PLAYBOOK_PATH"
fi

#Playbook execution with docker_tag condition
if [ -v VAULT_PATH ]; then
      echo ::::: Playbook execution :::::
      eval "$EXECUTION_CMD -e @$VARS_PATH -e @$VAULT_PATH "
elif [ -v EXTRA_VARS ]; then
      echo ::::: Playbook execution :::::
      echo ::::: Execution with EXTRA_VARS :::::

      eval "$EXECUTION_CMD -e @$VARS_PATH -e \"$EXTRA_VARS\""
else
      echo ::::: Playbook execution :::::
      eval "$EXECUTION_CMD -e @$VARS_PATH"
fi
# script will terminate with the ansible playbooks error code
exit $?
