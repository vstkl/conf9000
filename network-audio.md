** stolen with ♥ from  https://gist.github.com/savegame/58ae5966c58a71fda5d3800b335eb2f5 **

We have **Server** machine, this computer with Headphones, and we have **Client** computer, this is remote PC with music =) 
On **Server** we should first open port for listening connections from **Client** :
```
# on ubuntu 
sudo ufw allow from <Client_IP> to any port 4656 proto tcp
# on fedora ( with firewalld ) 
sudo firewall-ctl --add-port 4656/tcp
```
   *note: port 4656 just for sample. you can use any port you want*    
than on **Server**, from current user add listening for connections 
```
pactl load-module module-native-protocol-tcp port=4656 listen=<Server_IP>
```
###### *Note: set real IP for listening, not *`localhost`* or *`127.0.0.1`*, its should be IP avaliable from* **Client**   
then on **Client** add sink to remote **Server**
```
pactl load-module module-tunnel-sink server=tcp:<Server_IP>:4656
```
than, you should chose right output on **Client**, in KDE it looks like 
![изображение](https://user-images.githubusercontent.com/16311332/165910358-0c9b904a-8427-4de4-874c-c8d13de10631.png)  
you can use **pavucontrol** for this too

Update from comments :   
maybe add anonynous authorisation helps (thanks to [@raldone01](https://gist.github.com/raldone01))
``` 
pactl load-module module-native-protocol-tcp port=4656 listen=0.0.0.0 auth-anonymous=true
```
