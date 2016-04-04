# Solvecheck

A prototype I've been playing around with to test Chef cookbook dependency solving outside of Chef (i.e. without modifying the Chef server).

It closely matches what the current version of Chef does behind-the-scenes, so it provides an accurate simulation of what will happen when you upload/delete a cookbook, modify a role, or add an environmental constraint.


## Status

This is very much WIP.  There's stuff that's hard-coded, and the current public interface is only there for development.

The foundation is there, but most of the checks are not yet implemented and it needs a refactor + tests.

**It's not yet ready for public use.**  Expect breaking changes.


## Goals

This is the feature wishlist:

- Detect when a new cookbook version will cause the Chef depsolver to timeout.
- Warn when Chef's ability to solve a role is on the cusp of timing out.
- Warn when a role will not get the latest version of a cookbook in its runlist due to a dependency issue.
- Find which cookbooks are currently in-use.
- Find unused cookbook versions.
- Provide an environment in which you can test addition and removal of cookbook versions.
- View the effects of environmental pins.
- Detect unintended effects of the removal of a constraint.


## Installation

TODO: Write installation instructions.

## Usage

**This is not yet ready for public use.**

These instructions are mainly here as a reminder to me.

Write `config.json` file in gem root (see: `config-example.json`).  I'll probably make it pull this info from `knife.rb` eventually.

### Postgres SSH tunnel

Fetching the role list via HTTP API was ridiculously slow, so we do it via Postgres and decode the serialized objects.

    ssh -N -L 5432:localhost:5432 <chef_server>


## Debugging

Gecode:

    touch /tmp/DepSelectorDebugOn
    bundle exec exe/solvecheck
