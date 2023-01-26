FROM ubuntu:focal

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    # Restore man command
    && yes | unminimize 2>&1 

# Install basic build tools
RUN LANG="C.UTF-8" \
    && apt-get update \
    && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
        make \
        unzip \
        build-essential \
        libpq-dev \
        zip \
        jq \
        python-pip-whl \
        python3-pip \
        python3-dev \
        sqlite3 \
        libsqlite3-dev \
        curl \
        wget \
        gettext \
        libreadline-dev \
        debian-goodies \
        gnupg \
        gnupg2

RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb \
    && dpkg -i erlang-solutions_2.0_all.deb \
    && wget https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc \
    && apt-key add erlang_solutions.asc \
    && apt-get update \
    && apt-get install -y erlang-nox erlang-dev erlang-dialyzer inotify-tools \
    && wget https://github.com/elixir-lang/elixir/releases/download/v1.14.1/elixir-otp-25.zip \
    && unzip elixir-otp-25.zip -d /usr/local \
    && rm -f elixir-otp-25.zip erlang-solutions_2.0_all.deb erlang_solutions.asc

RUN apt-get update && apt-get autoremove -y && apt-get clean -y

ENV SHELL=/bin/bash \
    DOCKER_BUILDKIT=1

# Mount for docker-in-docker 
VOLUME [ "/var/lib/docker" ]

ENTRYPOINT [ "/usr/local/share/docker-init.sh", "/usr/local/share/ssh-init.sh"]
CMD [ "sleep", "infinity" ]
