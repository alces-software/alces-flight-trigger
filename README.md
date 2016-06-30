
# Alces Flight Trigger

An HTTP service to allow the execution of arbitrary scripts with arbitrary command-line parameters.

## Development

This project is intended to be developed within a standard Clusterware VM.

- Make sure the project is synced in to the Clusterware VM, at a location such as `/media/host/alces-flight-trigger`.

- Install the project for development:

  ```bash
  sudo bin/development-install
  ```

  This will symlink the project to the correct standard location, `/opt/clusterware/opt/alces-flight-trigger`

- The development server can then be run using:

  ```bash
  sudo bin/develop
  ```

- The tests can be run while the development server is running with:

  ```bash
  sudo bin/test
  ```

- Manual requests with the same test data can also be made:

  ```bash
  sudo yum install epel-release
  sudo yum install httpie
  cat tests/test_data/standard.json | http localhost:25278/trigger/printer --auth username:password
  ```

## Production usage

Alces Flight Trigger is intended to be used within an Alces [Clusterware](https://github.com/alces-software/clusterware) environment, and it is available as [Clusterware Serviceware](https://github.com/alces-software/clusterware-services). An example of typical usage is as follows:

```bash
# This is not required, but if this is done before enabling the
# `alces-flight-trigger` service it will hook into this and be available as
# part of the node's central HTTP service.
alces service install alces-flight-www
alces service enable alces-flight-www

alces service install alces-flight-trigger
alces service enable alces-flight-trigger

# You should install a more secure username and password to be used when
# authenticating requests to the trigger service.
echo 'username:secure_password' > "$cw_ROOT/var/lib/triggers/.credentials"

# Install some trigger scripts.
mkdir -p "$cw_ROOT/var/lib/triggers/{trigger_repo_1,trigger_repo_2}"
cp /a/trigger/script/named/useful_stuff "$cw_ROOT/var/lib/triggers/trigger_repo_1/"
cp /another/trigger/script/named/useful_stuff "$cw_ROOT/var/lib/triggers/trigger_repo_2/"

# Requests to `$address/trigger/useful_stuff`, in the appropriate format and
# using the installed credentials, should now return the results of running both
# of these scripts.
```
