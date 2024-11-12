FROM quay.io/jupyterhub/jupyterhub

WORKDIR /srv/jupyterhub

RUN apt update
RUN apt-get -y install nano git
RUN python3 -m pip install jupyterhub notebook jupyterlab pandas psycopg2-binary matplotlib scikit-learn seaborn
RUN mkdir /src
RUN cd /src && git clone https://github.com/jupyterhub/nativeauthenticator.git
RUN cd /src/nativeauthenticator/ && pip3 install -e .
RUN mkdir -p /etc/jupyterhub && cd $_ && jupyterhub --generate-config

VOLUME /etc/jupyterhub/jupyterhub_config.py
VOLUME /home
VOLUME /srv/jupyterhub

CMD [ "jupyterhub", "-f", "/etc/jupyterhub/jupyterhub_config.py" ]
