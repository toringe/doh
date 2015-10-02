<img src="https://raw.githubusercontent.com/toringe/doh/master/img/doh-logo.png" width="200px" />
# DigitalOcean Harbormaster

Automate Tugboat processes to start and stop droplets. This makes it very easy to minimize the amount of idle time for your droplets. [Tugboat][tugboat] is an awesome tool for interacting with DigitalOcean's API, and can easily be installed on your system with `gem install tugboat`.

## Prerequisites
* You need to run `tugboat authorize` before running `doh`. It's important to define your defaults as `doh` will use these instead of asking you every time. If you what to change your Tugboat configuration, simply edit the `~/.tugboat` file.

* You will also need to add your SSH keys to you DigitalOcean account (see [here][sshkeys] for more info). Add keys for all the host you want to run *doh* from.

## Usage
Simply run `doh start <name>` to create or restore a droplet with the specified name. When the process completes it will automatically start a SSH session (as root if the droplet is new, or as your default user if the droplet has been restored).

Do you stuff inside the droplet (at least make sure you create the default user you have defined in your tugboat configuration). 
When you want to take a break (probably more than just getting a new cup of coffee...or?), you simply run `doh stop <name>`. This will halt your running droplet, create a snapshot and finally destroy the droplet. The creation of the snapshot may take a bit of time, but the entire stop-process is automated, so you don't have to wait after you initiate the stop.

Then, when it's time to resume your work, hit `doh start <name>` again, and you're back in your SSH session.

[tugboat]: https://github.com/pearkes/tugboat
[sshkeys]: https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets  
