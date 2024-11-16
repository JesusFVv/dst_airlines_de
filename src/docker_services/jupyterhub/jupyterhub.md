# JupyterHub

[source](https://hatarilabs.com/ih-en/how-to-set-a-multiuser-jupyterlab-server-with-jupyterhub-in-windows-with-docker)

```bash
# Launch the jupyterhub container
docker run -it --name jupyterhub_man -p 8005:8000 \
-v /var/jupyterlab/data:/home:rw \
--network dst_network quay.io/jupyterhub/jupyterhub bash
# Update apt
apt update && apt-get install nano git  # No need to install python because is already available in the image
# apt-get install npm nodejs python3 python3-pip git nano
# Install jupyterlab and notebook
python3 -m pip install jupyterhub notebook jupyterlab
# Install nodejs packages
npm install -g configurable-http-proxy  # no need for this image because is available
# Install native autenthicator
cd /home && git clone https://github.com/jupyterhub/nativeauthenticator.git
cd /home/nativeauthenticator/ && pip3 install -e .
# Create configuration file
mkdir -p /etc/jupyterhub && cd $_ && jupyterhub --generate-config
# Update the configuration file with the lines below
# After config is updated, start jupyterhub with a configuration file
jupyterhub -f /etc/jupyterhub/jupyterhub_config.py
# Connect first time with admin: Sing-Up with a new password
# Login with admin
# go to http://localhost:8005/hub/authorize to authorize new users
# Open other url and Sing-up as new random users, admin has to authorize
```
```python
# Add to /etc/jupyterhub/jupyterhub_config.py
import pwd, subprocess
c.JupyterHub.authenticator_class = 'nativeauthenticator.NativeAuthenticator'
c.Authenticator.admin_users = {'admin'}
def pre_spawn_hook(spawner):
    username = spawner.user.name
    try:
        pwd.getpwnam(username)
    except KeyError:
        subprocess.check_call(['useradd', '-ms', '/bin/bash', username])
c.Spawner.pre_spawn_hook = pre_spawn_hook
c.Spawner.default_url = '/lab'
c.Authenticator.allow_all = True
c.JupyterHub.base_url = '/jupyterlab/'
```



## Nginx reverse proxy

The configuration needed to use nginx as reverse proxy is described below. [source](https://stackoverflow.com/questions/69099015/blocking-cross-origin-api-with-jupyter-lab)

```conf
# top-level http config for websocket headers
# If Upgrade is defined, Connection = upgrade
# If Upgrade is empty, Connection = close
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
server {
    ...

    location /jupyterlab/ {
            proxy_pass http://jupyterhub:8000;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Host localhost;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

            # websocket headers
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $connection_upgrade;
            proxy_set_header X-Scheme $scheme;
            proxy_buffering off;
    }

    ...    
}
```


## Create new users

- New user connects to hub:  http://localhost:8000/jupyterlab
- Sing-Up and introduces name and password
- Whith admin go to url: http://localhost:8000/jupyterlab/hub/authorize and authorize new user
- New user can login


## Users declared
- admin / admin
- dst_ml / 123
- dst_analyst / 456

