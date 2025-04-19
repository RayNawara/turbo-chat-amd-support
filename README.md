# README

https://medium.com/@m.mastrodonato/lets-write-a-free-chatgpt-clone-with-rails-8-part-1-85ee5668d8fb


Let’s write a free ChatGPT clone with Rails 8

I changed this to run using Stable diffusion webui with an AMD GPU? [2024]
https://www.youtube.com/watch?v=eO88i8o-BoY

This will get WebUI running in Win 11 with your AMD GPU.  To get it running in the rails app, turbo-chat, you need to start it with the additional command args, --api --listen

The only changes I needed to make were the IP address in .env (obviously) and change the create image service to handle the image array because they are returned from the API as Base64.
