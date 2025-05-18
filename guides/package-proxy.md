## on hosting computer run: 

```
PORT=8000
PKG_DIR=/var/cache/pacman/pkg
# print source address 
ip -br a | grep UP | grep  -E '([0-9]{1,3}\.){3}[0-9]{1,3}' -o
python -m http.server -d $PKG_DIR $PORT
```

## on client needing packages

```
DEST=/etc/pacman.d/test
PORT=8000;
SERVER_IP=192.168.1.86.; echo "CacheServer = http://$SERVER_IP:$PORT" | sudo tee -a $DEST
```
