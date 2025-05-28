FROM registry.access.redhat.com/ubi9/ubi-minimal

ENV OC_VERSION="4.18"

RUN microdnf update -y && \
    microdnf install -y \
    tar \
    gzip && \
    microdnf clean all && \
    rm -rf /var/cache/yum

RUN curl -LO "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable-${OC_VERSION}/openshift-client-linux-amd64-rhel9.tar.gz" && \
    tar -xzf openshift-client-linux-amd64-rhel9.tar.gz -C /tmp && \
    mv /tmp/oc "/usr/local/bin/oc" && \
    mv /tmp/kubectl "/usr/local/bin/kubectl" && \
    rm openshift-client-linux-amd64-rhel9.tar.gz

CMD ["/usr/bin/bash"]
