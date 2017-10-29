# docker-modsecurity

ModSecurity lite Debian based Docker image. It built as NGINX static module.

You can attach your sites configs using volume, mounted to `/etc/nginx/conf.d`.

To change ModSecurity config you need to mount volume to `/etc/modsecurity`.

[Image on DockerHub](https://hub.docker.com/r/andre487/modsecurity/)
