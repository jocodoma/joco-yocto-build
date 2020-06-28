FROM crops/poky:latest
LABEL maintainer="jocodoma@gmail.com"
LABEL vendor="Jocodoma"
LABEL com.jocodoma.version="0.1-beta"
LABEL com.jocodoma.release-date="2020-06-27"
USER root
RUN  apt-get update && \
     apt-get install -y curl \
                        rsync \
                        python3-distutils \
                        nano && \
     apt-get autoremove -y
RUN  curl http://commondatastorage.googleapis.com/git-repo-downloads/repo  > /usr/local/bin/repo
RUN  chmod a+x /usr/local/bin/repo
RUN  git config --system user.email "jocodoma@gmail.com" && \
     git config --system user.name "Joseph Chen"
