# Changes I've made to this repo:

Essentially, just note how there is a new script I've added, "cdbcheck.bash". What it does is check a calibre library to see if there is an existing book in a claibre library before downloading it in FlexGet. It currently has a hard coded IP (lazy) and only checks by ebook title, so this needs a lot of work to get working in a different environment and should probably be reworked for public consumption. 





# docker-flexget

Docker image for running [flexget](http://flexget.com/)

Container features are

- Lightweight alpine linux
- Python 3
- Flexget with initial settings (default ```config.yml``` and webui password)
- pre-installed plug-ins (transmissionrpc, python-telegram-bot)

~~Note that a default password for webui is set to ```f1exgetp@ss```.~~

No default password anymore, secure webui using ```FG_WEBUI_PASSWD``` below.

## Usage

```
docker run -d \
    --name=<container name> \
    -p 3539:3539 \
    -v <path for data files>:/data \
    -v <path for config files>:/config \
    -e FG_WEBUI_PASSWD=<desired password> \
    -e FG_LOG_LEVEL=info \
    -e PUID=<UID for user> \
    -e PGID=<GID for user> \
    -e TZ=<timezone> \
    wiserain/flexget
```
