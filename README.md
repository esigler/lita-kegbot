# lita-kegbot

[![Build Status](https://img.shields.io/travis/esigler/lita-kegbot/master.svg)](https://travis-ci.org/esigler/lita-kegbot)
[![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://tldrlegal.com/license/mit-license)
[![RubyGems :: RMuh Gem Version](http://img.shields.io/gem/v/lita-kegbot.svg)](https://rubygems.org/gems/lita-kegbot)
[![Coveralls Coverage](https://img.shields.io/coveralls/esigler/lita-kegbot/master.svg)](https://coveralls.io/r/esigler/lita-kegbot)
[![Code Climate](https://img.shields.io/codeclimate/github/esigler/lita-kegbot.svg)](https://codeclimate.com/github/esigler/lita-kegbot)
[![Gemnasium](https://img.shields.io/gemnasium/esigler/lita-kegbot.svg)](https://gemnasium.com/esigler/lita-kegbot)

A Kegbot (https://kegbot.org) handler for checking what's on tap, how much is left, etc.

## Installation

Add lita-kegbot to your Lita instance's Gemfile:

``` ruby
gem "lita-kegbot"
```

## Configuration

Add the following variables to your Lita config file:

``` ruby
config.handlers.kegbot.api_key = '_your_key_here_'
config.handlers.kegbot.api_url = 'https://kegbot.example.com'
```

## Usage

### Drinks

```
kegbot drink list     - List last 5 drinks poured
kegbot drink list <N> - List last <N> drinks poured
```

### Taps

```
kegbot tap status      - Shows status of all taps
kegbot tap status <id> - Shows status of tap <id>
```

### Kegs

```
kegbot keg status      - Shows status of all kegs
kegbot keg status <id> - Shows status of keg <id>
```

## License

[MIT](http://opensource.org/licenses/MIT)
