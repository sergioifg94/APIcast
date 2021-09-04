FROM quay.io/3scale/s2i-openresty-centos7:master

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain stable --profile minimal -y
RUN source $HOME/.cargo/env \
 && ln -s .profile .bashrc \
 && rustc --version \
 && cargo install cargo-c
