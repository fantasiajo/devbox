FROM debian:testing

ARG HTTPS_PROXY

# apt source init
RUN echo 'deb [trusted=true] http://deb.debian.org/debian testing main' > /etc/apt/sources.list

RUN apt update && apt install ca-certificates -y

COPY --chown=root:root sources.list /etc/apt/

# time init
RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# root password
ARG ROOT_PASSWD

RUN echo root:$ROOT_PASSWD | chpasswd

# user init
ARG USER

ARG USER_PASSWD

RUN useradd --create-home --user-group --shell /bin/bash $USER

RUN echo $USER:$USER_PASSWD | chpasswd

RUN adduser $USER sudo

# common apt package
RUN apt update

RUN apt install man zip ifstat apt-file net-tools \
    iftop netcat-openbsd tcpdump telnet node-ws bind9-dnsutils \
    whois iproute2 mtr nethogs iptables htop \
    build-essential vim sudo curl wget procps zsh git netwox \
    strace lsof traceroute iputils-ping netstat-nat python3 python3-pip -y

# go env
ARG GOLANG_VERSION=1.18.1

RUN wget https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz \
    && tar -C /usr/local -xzvf go$GOLANG_VERSION.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin

RUN go env -w GOPROXY=https://goproxy.cn,direct
RUN go env -w GOBIN=/usr/local/go/bin

RUN go install -v github.com/ramya-rao-a/go-outline@latest 
RUN go install -v github.com/cweill/gotests/gotests@latest 
RUN go install -v github.com/fatih/gomodifytags@latest 
RUN go install -v github.com/josharian/impl@latest 
RUN go install -v github.com/haya14busa/goplay/cmd/goplay@latest 
RUN go install -v github.com/go-delve/delve/cmd/dlv@latest 
RUN go install -v honnef.co/go/tools/cmd/staticcheck@latest 
RUN go install -v golang.org/x/tools/gopls@latest

# code server
RUN https_proxy=$HTTPS_PROXY sh -c 'curl -fsSL https://code-server.dev/install.sh | sh'

ENV EXTENSIONS_GALLERY '{"serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery","cacheUrl": "https://vscode.blob.core.windows.net/gallery/index","itemUrl": "https://marketplace.visualstudio.com/items"}'

# user init
USER $USER

WORKDIR /home/$USER

# zsh
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

RUN cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="ys"/' ~/.zshrc

# language
ENV LANG C.UTF-8

# code server passwd
ARG CODE_SERVER_PASSWD

ENV PASSWORD $CODE_SERVER_PASSWD

RUN code-server --install-extension ms-vscode.cpptools 
RUN code-server --install-extension usernamehw.errorlens 
RUN code-server --install-extension streetsidesoftware.code-spell-checker 
RUN code-server --install-extension eamodio.gitlens 
RUN code-server --install-extension golang.go 
RUN code-server --install-extension xyz.local-history 
RUN code-server --install-extension jebbs.plantuml 
RUN code-server --install-extension ms-python.python 
RUN code-server --install-extension adpyke.vscode-sql-formatter
RUN code-server --install-extension cweijan.vscode-mysql-client2

COPY --chown=$USER:$USER vscode.settings.json /home/$USER/.local/share/code-server/User/settings.json

# git
RUN git config --global user.name "fantasiajo"
RUN git config --global user.email "lizhen95m@outlook.com"
RUN git config --global pager.branch false

ENTRYPOINT ["code-server","--bind-addr","0.0.0.0:9999"]
