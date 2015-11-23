gopath-util
===========

GOPATH utility

## Description

`GOPATH` version of [ghq-util](https://github.com/knakayama/ghq-util). Currently `mk` and `rm` commands are only supported.

## Requirements

1. [go](https://golang.org/)
1. [peco](https://github.com/peco/peco)

## Install

```zsh
antibody bundle knakayama/gopath-util
```

## Usage

```bash
Usage: gou [-h] COMMAND [<args>]

gou utility

Commands:

  rm    Remove repo(s) on GOPATH with peco style selecting
  mk    Create repo on GOPATH

Run 'gou COMMAND -h' for more information on a command.
```

## License

MIT

## Author

[knakayama](https://github.com/knakayama)
