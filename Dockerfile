ARG VER=1.4.2
FROM particle/device-os:${VER}

FROM particle/buildpack-particle-firmware:${VER}

ENV FIRMWARE_DIR=/src
ENV PROJECTS_DIR=/src/conan

RUN apt update
RUN apt install -y python3-pip libssl-dev nano
RUN pip3 install conan

COPY --from=0 / ${FIRMWARE_DIR}
COPY common/printconf.mk ${FIRMWARE_DIR}/build
COPY common/printconf.sh /usr/local/bin
COPY common/package.sh   /usr/local/bin

COPY conanfile.py ${PROJECTS_DIR}/conanfile.py
COPY common    ${PROJECTS_DIR}/common
COPY cmake    ${PROJECTS_DIR}/cmake
COPY *.profile ${PROJECTS_DIR}


COPY common/settings.yml /tmp
RUN conan config install /tmp

WORKDIR /tmp
ENTRYPOINT ["package.sh"]
