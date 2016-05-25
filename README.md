
# Alces Flight Trigger

An HTTP service to allow the execution of arbitrary scripts with arbitrary command-line parameters.

## Development

Within standard Clusterware development VM:

- Get RVM: https://rvm.io/

- Get same version as Clusterware Ruby:

  ```
  rvm install ruby-2.2.3
  ```

- Install dependencies:

  - Rerun (install from `master` so get `--force-polling` option for running in Vagrant
    while developing on host):

    ```
    sudo yum install git
    gem install specific_install
    gem specific_install https://github.com/alexch/rerun.git
    ```

  - Bundler and gems:

    ```
    gem install bundler
    bundle install
    ```

- Run development server:

  ```
  rerun --force-polling ruby server.rb
  ```

- Tests can be run with:

  ```
  rvmsudo rake test
  ```
