# remnawave_bot_basic_config
This repo contains basic configuration and commands to set up basic remnawave panel, subscription panel, nginx + 2 additional hosts related to a telegram bot that manages those

All you need is a supergroup with needed number of topics, 4 domain names (usually one main and 3 sub domain names), after just follow the instructions on your screen, all certificates (unless you run into ratelimits of lets encrypt) will be generated as well

Automatic releases are generated on every commit push. To download and extract the latest release:

```bash

RELEASE_URL=$(curl -s https://api.github.com/repos/j5j5-afk/remnawave_bot_basic_config/releases/latest | grep tarball_url | cut -d'"' -f4) && \
cd /opt && curl -L "$RELEASE_URL" -o remnawave_bot_basic_config.tar.gz

tar -xzf remnawave_bot_basic_config.tar.gz --wildcards "*templates*" --strip-components=1
```
