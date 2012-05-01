# NOTICE #

This repository is the old slyphon/zookeeper repository and is being kept because slyphon-zookeeper gems were cut off this fork (and unfortunately, used conflicting version numbers). 

All development will henceforth be carried out on the former twitter/zookeeper repository which is now named 'slyphon/zookeeper'

Confused yet?

the transfer went like this:

* `twitter/zookeeper` -> `slyphon/twitter-zookeeper`
* `slyphon/zookeeper` -> `slyphon/zookeeper-fork`
* `slyphon/twitter-zookeeper` -> `slyphon/zookeeper`


## zookeeper ##



An interface to the Zookeeper distributed configuration server.

For a higher-level interface with a slightly more convenient API and features
such as locks, have a look at [ZK](https://github.com/slyphon/zk) (also
available is [ZK-EventMachine](https://github.com/slyphon/zk-eventmachine) for
those who prefer async).

Unfortunately, since this is a fork of twitter/zookeeper, we don't have our own
Issues tracker. Issues should be filed under [ZK](https://github.com/slyphon/zk/issues).

## License

Copyright 2008 Phillip Pearson, and 2010 Twitter, Inc. Licensed under the
MIT License.  See the included LICENSE file.  Portions copyright 2008-2010
the Apache Software Foundation, licensed under the Apache 2 license, and
used with permission.

## Install

sudo gem install zookeeper

## Usage

Connect to a server:

	require 'rubygems'
	require 'zookeeper'
	z = Zookeeper.new("localhost:2181")
	z.get_children(:path => "/")

## Idioms

The following methods are initially supported:
* get
* set
* get\_children
* stat
* create
* delete
* get\_acl
* set\_acl

All support async callbacks.  get, get\_children and stat support both
watchers and callbacks.

Calls take a dictionary of parameters.  With the exception of set\_acl, the
only required parameter is :path.  Each call returns a dictionary with at
minimum two keys :req\_id and :rc.

