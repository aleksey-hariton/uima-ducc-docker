FROM java

# Install make & gcc for ducc_ling and ssh server for multi node DUCC
RUN apt-get update && apt-get install -y make gcc net-tools openssh-server


# UIMA DUCC preparation
# Installation of UIMA DUCC implemented in run.sh script
# because for some reasons Docker doesnt allow unprivileged user to 
# do any changes with files had 600 permissions during image creation
# For example ./admin/ and ./resources.private/ not accesable by ducc user
RUN useradd -m ducc -s /bin/bash
RUN mkdir /home/ducc/.ssh/
COPY ./id_rsa* /home/ducc/.ssh/
COPY ./uima-ducc-1.1.0-bin.tar.gz /home/ducc/
COPY ./run.sh /home/ducc/apache-uima-ducc/

# VOLUME ./results/:/mnt

USER root
CMD /home/ducc/apache-uima-ducc/run.sh
