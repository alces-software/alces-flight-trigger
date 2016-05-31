
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
