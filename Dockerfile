FROM python:3.13.1-slim-bullseye
RUN apt-get update && apt-get install -y zsh gcc python3-dev git
SHELL ["/bin/zsh", "-c", "-o", "pipefail"]

RUN if ! getent passwd app; then groupadd -g 1000 app \
	&& useradd -u 1000 -g 1000 -d /home/app -m -s /bin/zsh app; fi \
	&& echo app:app | chpasswd \
	&& echo 'app ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
	&& mkdir -p /etc/sudoers.d \
	&& echo 'app ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/app \
	&& chmod 0440 /etc/sudoers.d/app \
	&& apt-get autoremove \
	&& apt-get clean -y \
	&& rm -rf /var/lib/apt/lists/* 

USER app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PATH='/home/app/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'
RUN pip3 install --user --upgrade pip \
	&& pip3 install poetry \
	&& git config --global user.email "akmiles@icloud.com" && git config --global user.name "Andy Miles"
WORKDIR /home/app/app
COPY ./pyproject.toml .
RUN /home/app/.local/bin/poetry install
CMD ["/bin/zsh"]
