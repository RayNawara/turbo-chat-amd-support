# README

https://medium.com/@m.mastrodonato/lets-write-a-free-chatgpt-clone-with-rails-8-part-1-85ee5668d8fb


Let’s write a free ChatGPT clone with Rails 8

I changed this to run using Stable diffusion webui with an AMD GPU? [2024]
https://www.youtube.com/watch?v=eO88i8o-BoY

This will get WebUI running in Win 11 with your AMD GPU.  To get it running in the rails app, turbo-chat, you need to start it with the additional command args, --api --listen

The only changes I needed to make were the IP address in .env (obviously) and change the create image service to handle the image array because they are returned from the API as Base64.

You will need to get your windows host address. Mine was like this: IMAGE_GENERATION_URL=http://172.31.0.1:7860/sdapi/v1/txt2img

Run

```
/mnt/c/Windows/System32/ipconfig.exe /all
```
in your WSL 2 Linux. Then look for (it should be at the bottom)

Ethernet adapter vEthernet (WSL (Hyper-V firewall)):

   Connection-specific DNS Suffix  . :
   Description . . . . . . . . . . . : Hyper-V Virtual Ethernet Adapter #2
   Physical Address. . . . . . . . . : 00-15-5D-A0-C9-61
   DHCP Enabled. . . . . . . . . . . : No
   Autoconfiguration Enabled . . . . : Yes
   Link-local IPv6 Address . . . . . : fe80::75d8:47df:1b21:b5ed%42(Preferred)
   IPv4 Address. . . . . . . . . . . : 172.31.0.1(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.240.0
   Default Gateway . . . . . . . . . :
   DHCPv6 IAID . . . . . . . . . . . : 704648541
   DHCPv6 Client DUID. . . . . . . . : 00-01-00-01-2A-80-FE-C6-D8-BB-C1-9A-B8-8A
   NetBIOS over Tcpip. . . . . . . . : Enabled

There's your IP address!
