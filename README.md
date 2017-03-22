Quagga in Docker
================
This shows off how to deploy a container running quagga on a host to avoid having
to install the quagga package manually.



Quickstart: Run the demo
------------------------
Before running this demo, install [VirtualBox](https://www.virtualbox.org/wiki/Download_Old_Builds) and [Vagrant](https://releases.hashicorp.com/vagrant/). The currently supported versions of VirtualBox and Vagrant can be found on the [cldemo-vagrant](https://github.com/cumulusnetworks/cldemo-vagrant).

```
git clone https://github.com/cumulusnetworks/cldemo-vagrant
cd cldemo-vagrant

vagrant up oob-mgmt-server oob-mgmt-switch
vagrant up leaf01 leaf02 leaf03 leaf04 spine01 spine02 server01 server02 server03 server04

vagrant ssh oob-mgmt-server
sudo su - cumulus
sudo apt-get install software-properties-common -qy
sudo apt-add-repository ppa:ansible/ansible -y
sudo apt-get update -y
sudo apt-get install ansible python-pip -qy
sudo pip install ansible --upgrade

git clone https://github.com/cumulusnetworks/cldemo-roh-docker
cd cldemo-roh-docker
git checkout crohdad

ansible-playbook ./run-demo.yml
```

Before you start
----------------
This demo requires you set up a topology as per the diagram below:

                     +--------------+  +--------------+
                     | spine01      |  | spine02      |
                     |              |  |              |
                     +--------------+  +--------------+
                    swp1-4 ||||                |||| swp1-4
             +---------------------------------+|||
             |             ||||+----------------+|+----------------+
             |             |||+---------------------------------+  |
          +----------------+|+----------------+  |              |  |
    swp51 |  | swp52  swp51 |  | swp52  swp51 |  | swp52  swp51 |  | swp52
    +--------------+  +--------------+  +--------------+  +--------------+
    | leaf01       |  | leaf02       |  | leaf03       |  | leaf04       |
    |              |  |              |  |              |  |              |
    +--------------+  +--------------+  +--------------+  +--------------+
      swp1 |  swp2 \ / swp1 | swp2       swp1 |   swp2 \ / swp1 | swp2
           |        X       |                 |         X       |
      eth1 |  eth2 / \ eth1 | eth2       eth1 |   eth2 / \ eth1 | eth2
    +--------------+  +--------------+  +--------------+  +--------------+
    | server01     |  | server02     |  | server03     |  | server04     |
    |              |  |              |  |              |  |              |
    +--------------+  +--------------+  +--------------+  +--------------+

This topology is also described in the `topology.dot` and `topology.json` files.
Additionally, an out of band management server that can SSH into the leafs and
spines via the specified hostnames is required. Setting up this topology is
outside the scope of this document.

This demo is written using Ansible 2.0. Install Ansible on the management server
before you begin. Instructions for installing Ansible can be found here:
https://docs.ansible.com/ansible/intro_installation.html

Running the Demo
----------------
On the management server, download the demo and cd into the top directory.
Run the command: `ansible-playbook run-demo.yml`.

After running one demo, you will need to log into the servers and delete the
Docker containers before you can create another one. You can do this with the
command `docker ps -a | docker rm`.

### docker-privileged
Installs Quagga on a privileged Docker container with access to the host
machine's networking stack. In this demo, we set up OSPF-numbered on both
hosts (via Docker) and the leaves, making it possible for one host to ping the
other.

This demo showcases how easy it is to configure Quagga without having to install
the package natively. Since the Cumulus version of Quagga is often ahead of the
official release, it can be packaged into a Docker container without needing to
change the package sources of the host or compile it from source on a non-debian
machine.
