FROM debian:latest

# Install base services: supervisor, sshd and some tools (vim, ps, ifconfig...)
RUN apt-get update
RUN apt-get install -y procps vim supervisor net-tools ssh wget unzip bzip2

# dpkg-dev is required to use the command dpkg-source
# to install manually the package libpam-google-athenticator
RUN apt-get update && \
apt-get install -y dpkg-dev debian-keyring libpam0g-dev && \
wget --quiet http://ftp.de.debian.org/debian/pool/main/g/google-authenticator/google-authenticator_20130529-2.dsc && \
wget --quiet http://ftp.de.debian.org/debian/pool/main/g/google-authenticator/google-authenticator_20130529.orig.tar.gz && \
wget --quiet http://ftp.de.debian.org/debian/pool/main/g/google-authenticator/google-authenticator_20130529-2.debian.tar.gz && \
dpkg-source -x google-authenticator_20130529-2.dsc && \
rm google-authenticator_2013* && \
cd google-authenticator-20130529 && \
make && \
cd libpam && \
make install && \
cd / && \
rm -R google-authenticator-20130529

# Update the PAM config
RUN echo "\
auth    required    pam_google_authenticator.so nullok" >> /etc/pam.d/sshd

# Update the SSHD config
RUN sed -i 's/^\(ChallengeResponseAuthentication\s\+\)no/\1yes/' /etc/ssh/sshd_config

# Configure SSH
RUN echo root:root | chpasswd
ADD supervisor_sshd.conf /etc/supervisor/conf.d/sshd.conf
RUN service ssh start
ADD root.profile /root/.profile
RUN chown root:root /root/.profile

# Generate token for google authenticator
RUN echo "NOW LOGIN AS root/root AND LAUNCH google-authenticator (Ex: google-authenticator -t -r 3 -R 30 -d -f -W)"


# FROM baseimage

# 
# Configure SSH
# RUN mkdir /root/.ssh
# ADD id_rsa_docker.pub /root/.ssh/authorized_keys
# RUN chown root:root /root/.ssh/authorized_keys
# ADD supervisor_sshd.conf /etc/supervisor/conf.d/sshd.conf
# RUN service ssh start
# ADD root.profile /root/.profile
# RUN chown root:root /root/.profile
# 
# On container run, launch supervisor
CMD ["/usr/bin/supervisord", "--nodaemon"]
