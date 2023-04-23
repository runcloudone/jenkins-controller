ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_TAG}

COPY --chown=jenkins:jenkins /files/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

COPY --chown=jenkins:jenkins files/jenkins.yaml /usr/share/jenkins/ref/jenkins.yaml

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false \
    -Dhudson.slaves.NodeProvisioner.initialDelay=0 \
    -Dhudson.slaves.NodeProvisioner.MARGIN=50 \
    -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85

EXPOSE 8080
EXPOSE 50000
