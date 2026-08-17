# Taka

Taka is a Docker image was designed for a local dev environment with security research and its updated weekly.
Taka includes basic development tools and utilities to perform simple tasks which has different base images, such as Alpine, Kali, and Arch, for different purposes.

## Usage

Choose your poison then Try it out!

```
docker run --rm -ti --name (basename $PWD) -v "$PWD":/code ghcr.io/0xf61/taka:alpine
```

```
docker run --rm -ti --name (basename $PWD) -v "$PWD":/code ghcr.io/0xf61/taka:arch
```

```
docker run --rm -ti --name (basename $PWD) -v "$PWD":/code ghcr.io/0xf61/taka:kali
```

```
docker run -d --hostname hostname \
--cap-add NET_ADMIN \
--device /dev/net/tun:/dev/net/tun \
ghcr.io/0xf61/taka:pwnbox
```
