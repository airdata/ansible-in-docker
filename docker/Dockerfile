FROM alpine:latest

# define default values - are overwritten by the --build-arg UID="$UID" --build-arg UID="$GID" parameters
ARG UID=1002
ARG GID=1003

#Prevent key error during playbook execution
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

USER root
WORKDIR /root/

RUN apk --no-cache add \
        sudo \
        python3 \
        bash \
        py3-pip \
        openssl \
        ca-certificates \
        sshpass \
        openssh-client \
        rsync \
        libxml2-utils \
        yamllint \
        git && \
        apk --no-cache add --virtual build-dependencies \
        python3-dev \
        libffi-dev \
        musl-dev \
        gcc \
        cargo \
        openssl-dev \
        build-base && \
    pip3 install --upgrade pip wheel && \
    pip3 install --upgrade cryptography cffi && \
    pip3 install certifi && \
    pip3 install requests && \
    pip3 install ansible && \
    apk del build-dependencies && \
    rm -rf /var/cache/apk/* && \
    rm -rf /root/.cache/pip && \
    rm -rf /root/.cargo

RUN addgroup --gid ${GID} jenkins && \
    addgroup docker && \
    adduser -G jenkins jenkins --disabled-password -u ${UID} && \
    addgroup jenkins wheel && \
    addgroup jenkins docker && \
    mkdir -p /home/jenkins/ansible-execution/ && \
    mkdir -p /home/jenkins/ansible-playbook/ && \
    mkdir -p /var/jenkins_home/workspace/ && \
    mkdir -p /var/certs/ && \
    chown -R jenkins:jenkins /home/jenkins/ && \
    chown -R jenkins:jenkins /var/jenkins_home/workspace && \
    chmod -R g+rw /home/jenkins/

ADD passphrase.sh /home/jenkins/.ssh/passphrase.sh
ADD entrypoint.sh /home/jenkins/ansible-execution/

RUN rmdir /usr/local/bin && \
    ln -s /usr/bin/ /usr/local/bin && \
    chmod a+x /home/jenkins/ansible-execution/entrypoint.sh && \
    chmod +x /home/jenkins/.ssh/passphrase.sh && \
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /home/jenkins/
#ENTRYPOINT ["bash","/home/jenkins/ansible-execution/entrypoint.sh"]