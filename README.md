# Escalade 
Escalade is a network tool to accelerate your international network speed.

## features
- rule based routing: directly connect Chinese sites, and connect to international sites via proxy server.
- find the fastest proxy server with just one click.

## quick start
### first time setup
- start the app, there will be a file open dialog;
- open the yaml config file in the dialog;
- click `ok` in the `enable system proxy` dialog;
- input the password of your user account and click `ok`;
- then a `server testing finished` notification should pop up, telling you he has found the best proxy server for you;
- done, enjoy the free Internet!

### routine usage, when the international website is getting slow
- click the `Server: xxx` or `auto select` menu;
- in at most 4 seconds, app will tell you the found fastest proxy server;
- refresh the website, see if it is better.

## terminology
- proxy server
    + when you can't open a website, you can't directly connect to the server of the website(we call it Server2 hereafter). but if there's another server(Server3) can connect directly to both you and Server2, then you can connect to the Server2 with the help of the Server3, namely You -> Server3 -> Server2. Then Server3 here is a proxy server.
- ping test and connectivity quality
    + to test if you can connect to a server and how is the speed, you send a small message to the server and record the timestamp(T1), then wait for the reply from the server with 2 seconds timeout, namely you record the timestamp(T2) when the first of the two events happens: you get the reply or 2 seconds elapsed. then the time it costs(Q=T2-T1) is what we used to measure the connectivity quality of the network, so Q is the smaller the better. and this sending/receiving process is called ping test. 
- routing rule
    + the one weakness of vpn is that when you open it, the Chinese websites is getting slow, but when you close it, the international websites is slow. what if we can connect to Chinese websites directly while connect tot international sites via proxy server? this is just what routing rule does. it tells the app how to connect to the server of the website, directly or via proxy.
- configuration
    + it contains proxy server infomation and routing rules.

## menus ui
- the ladder icon: white one means system proxy disabled, colorful one means enabled.
- network traffic: the realtime data flow traffic go through this app.
- connectivity quality: normally there are 2 values: baidu and google.
    + baidu: the time it takes to commuicate with baidu directly.
    + google: the time it takes to communicate with google via the current proxy server.
- `Server: xxx`: current using proxy server and the proxy server list in submenu 
    + auto select: test all proxy servers and choose the fastest one automatically.
    + proxy server list: click to switch to the proxy server mannually.
- `Config: xxx`: the current config and the the config list in submenu
    + open config folder
    + reload all configs
    + config list: click to switch to the config.
- `Advanced`: advanced settings
    + system proxy: set system proxy to use this app. 
    + start at login: start this app when you start and login on the mac.
    + show log: open the log in Console app.
    + copy export command: copy command to use the proxy in terminal.
    + check updates: check if there's an updated version available.
- `Help`: open the help web page.
- `Quit`: quit this app

## configuration file
```yaml
# This is port of the local socks5 proxy server , the http proxy server starts at port+1.
port: 9990
# Adapter is the remote proxy server you want to connect to
adapter:
     # id is used to distinguish adapter when defining rules.
     # There is a 'direct' adapter that connect directly to target host without proxy.
  # - id: adapter1
  #    # HTTP server is a http proxy server.
  #   type: HTTP
  #   host: http.proxy
  #   port: 3128
  #   auth: true
  #   username: proxy_username
  #   password: proxy_password
  # - id: adapter2
  #    # SHTTP server is a http proxy server on SSL.
  #   type: SHTTP
  #   host: http.proxy.connect.via.https
  #   port: 3128
  #   auth: true
  #   username: proxy_username
  #   password: proxy_password
  # - { id: "🇨🇳homecn1-", type: ss, host: homecn1.hxg.cc, port: 59671, method: rc4-md5, password: l6j0kU26cK }
  - { id: example, type: ss, host: ss.example.com, port: 23114, method: rc4-md5, password: password }
  # Speed adapter automatically connects to all specified adapters (with given delay)
  # and uses the fastest one that becomes ready.
  # - id: speed
  #   type: SPEED
  #   adapters:
  #     - id: proxy
  #       # Delay in milliseconds.
  #       delay: 1000
  #     - id: direct
  #       delay: 0
# Here defines how things should work.
# Rule will be matched one by one.
rule:
  # Forward requests based on whether the host matches the given regular expressions.
  - type: list
    file: ~/.SpechtLite/DirectDomains
    adapter: direct
  - type: list
    file: ~/.SpechtLite/ProxyDomains
    adapter: proxy
  # When the DNS lookup of the host fails.
  # - type: DNSFail
  #   adapter: speed
  # Forward requests based on geographical location.
  - type: country
    country: CN
    match: true
    adapter: direct
  # When the location is unknown. Usually this means this is resolved an Intranet IP.
  # - type: country
  #   country: --
  #   match: true
  #   adapter: speed
  # Match all other requests.
  - type: all
    adapter: proxy

```
