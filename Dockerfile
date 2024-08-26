ARG PACKER_VERSION=1.8.1
ARG PACKER_SHA256SUM=ae834c85509669c40b26033e5b2210d5594db3921103e38af1e3f537b58338a3

ARG OVFTOOL_VERSION=4.6.2-22220919
ARG OVFTOOL_INSTALLER=VMware-ovftool-${OVFTOOL_VERSION}-lin.x86_64.bundle
# checksum available at https://tap-stg.broadcom.com/tools/open-virtualization-format-ovf-tool/latest/
ARG OVFTOOL_MD5SUM=41048cf17f4d6931b21d61894cf015d6

FROM ubuntu:24.04 as dowloader
ARG PACKER_VERSION
ARG PACKER_SHA256SUM
ARG OVFTOOL_VERSION
ARG OVFTOOL_INSTALLER
ARG OVFTOOL_MD5SUM

WORKDIR /download

RUN apt-get update && apt-get install -y curl unzip jq

RUN curl -O "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" && \
    echo "${PACKER_SHA256SUM} packer_${PACKER_VERSION}_linux_amd64.zip" | sha256sum -c - && \
    mkdir packer && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip -d packer

RUN curl "$(curl -XPOST \
    -d "_SDK_AND_TOOL_DETAILS_INSTANCE_iwlk_fileName=${OVFTOOL_INSTALLER}" \
    -d '_SDK_AND_TOOL_DETAILS_INSTANCE_iwlk_fileType=Download' \
    -d '_SDK_AND_TOOL_DETAILS_INSTANCE_iwlk_artifactId=19195' \
    'https://tap-stg.broadcom.com/web/dp/tools/open-virtualization-format-ovf-tool/latest?p_p_id=SDK_AND_TOOL_DETAILS_INSTANCE_iwlk&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_resource_id=downloadArtifact&p_p_cacheability=cacheLevelPage#p_SDK_AND_TOOL_DETAILS_INSTANCE_iwlk;'  | jq -r '.data.downloadUrl')" -o ${OVFTOOL_INSTALLER} && \
    echo "${OVFTOOL_MD5SUM} ${OVFTOOL_INSTALLER}" | md5sum -c -


FROM ubuntu:24.04 as final
ARG OVFTOOL_INSTALLER

RUN apt-get update && \
    apt-get install -y ca-certificates mkisofs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=dowloader /download/packer /bin
COPY --from=dowloader /download/${OVFTOOL_INSTALLER} /tmp

RUN sh /tmp/${OVFTOOL_INSTALLER} -p /usr/local --console --eulas-agreed --required && \
    rm /tmp/${OVFTOOL_INSTALLER}

ENTRYPOINT ["/bin/packer"]
