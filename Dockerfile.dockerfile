FROM centos:centos7
LABEL Jesus Sanchez <sanchezajesus@gmail.com>
LABEL docker build -t isdaimonos/centos-jenkins-full:latest -f Dockerfile.dockerfile .
LABEL docker run --restart on-failure --name jenkins-full -d -p 8080:8080 -v /var/lib/docker/Volumes/jenkins-full:/var/jenkins_home isdaimonos/centos-jenkins-full:latest 

ARG user=jenkins
ARG group=jenkins
ARG uid=2000
ARG gid=2000
ARG http_port=8080
ARG agent_port=50000
ARG ansible_version=2.4.2.0
ARG jenkins_version=2.89.4
ARG gradle_version=4.3
ARG maven_version=3.3.9

ENV DEFAULT_MAVEN_DIR="/opt/maven" \
    MAVEN_VERSION="${maven_version}" \
    DEFAULT_GRADLE_DIR="/opt/gradle" \
    GRADLE_VERSION="${gradle_version}" \
    JENKINS_SLAVE_AGENT_PORT="${agent_port}" \
    JENKINS_VERSION="${jenkins_version}" \
    JENKINS_UC="https://updates.jenkins.io" \
    JENKINS_UC_EXPERIMENTAL="https://updates.jenkins.io/experimental" \
    ANSIBLE_VERSION="${ansible_version}" \
    JENKINS_HOME="/var/jenkins_home" \
    JAVA_HOME="/usr/java/jdk1.8.0_144"
     
ENV COPY_REFERENCE_FILE_LOG="${JENKINS_HOME}/copy_reference_file.log" \
    PATH="$PATH:$JAVA_HOME/bin"

# Install prepare infrastructure
RUN yum -y install epel-release \
    && yum install -y wget curl unzip python git bash python2-pip \
       less openssl openssh-client p7zip py-lxml py-pip rsync sshpass sudo \
       subversion vim zip bash ttf-dejavu coreutils openssh-client  \
       build-dependencies python-dev libffi-dev openssl-dev build-base \
       && wget https://mirror.its.sfu.ca/mirror/CentOS-Third-Party/NSG/common/x86_64/jdk-8u144-linux-x64.rpm && rpm -ivh jdk-8u144-linux-x64.rpm \
       && pip install --upgrade pip cffi \
       && pip install ansible==$ANSIBLE_VERSION \
       && wget http://www-eu.apache.org/dist/maven/maven-3/"$MAVEN_VERSION"/binaries/apache-maven-"$MAVEN_VERSION"-bin.tar.gz -P /tmp \
       && wget https://services.gradle.org/distributions/gradle-"$GRADLE_VERSION"-bin.zip -P /tmp \
       && mkdir -p "$DEFAULT_MAVEN_DIR" "$DEFAULT_GRADLE_DIR" "$JENKINS_HOME" "/usr/share/jenkins/ref/"  \
       && tar -xvzf /tmp/apache-maven-"$MAVEN_VERSION"-bin.tar.gz -C "$DEFAULT_MAVEN_DIR" \
       && unzip /tmp/gradle-"$GRADLE_VERSION"-bin.zip -d "$DEFAULT_GRADLE_DIR" \
       && ln -s "$DEFAULT_MAVEN_DIR/apache-maven-$MAVEN_VERSION/bin/mvn" /usr/bin/mvn \
       && ln -s "$DEFAULT_GRADLE_DIR/gradle-$GRADLE_VERSION/bin/gradle" /usr/bin/gradle \
       && mkdir -p /etc/ansible \
       && echo 'localhost' > /etc/ansible/hosts \
       && groupadd -g ${gid} ${group} \
       && adduser -d "${JENKINS_HOME}" -u ${uid} -g ${group} -s /bin/bash ${user} \
       && wget https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war  -P /usr/share/jenkins/ \
       && mkdir -p ${JENKINS_HOME}/tmp \
       && mv /usr/share/jenkins/jenkins-war-${JENKINS_VERSION}.war /usr/share/jenkins/jenkins.war \
       && chown -Rv ${user}:${user} /opt $JENKINS_HOME /usr/share/jenkins /etc/ansible \
       && rm -rf /tmp/* jdk-8u144-linux-x64.rpm

USER ${user}
WORKDIR ${JENKINS_HOME}
COPY ["jenkins-support","jenkins.sh", "/usr/local/bin/"]
ENTRYPOINT ["bash", "/usr/local/bin/jenkins.sh"]