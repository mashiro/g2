# G2

Gyazo to tumblr

## Requirements

* tumblr blog and application
http://www.tumblr.com/oauth/apps

* bit.ly account and application (if you need to shorten the url)
https://bitly.com/a/oauth_apps

## Setup

```bash
git clone git@github.com/mashiro/g2.git
cd g2
bundle install
bower install

cp settings.yml.sample settings.yml
# and edit this.
```

## Run

```bash
bundle exec thin -C thin.yaml start
```

