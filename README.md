Redistributing Docker into Routing on The Host
===============================================
This demo shows one of several different approaches to running Docker.
This approach advertises host-routes for Docker containers which have been created on a docker-bridge without NAT enabled.
Using this technique you can provide your containers with real IP addresses which are externally reachable and routed through the Host. 

Cumulus Quagga is installed in a container along with the CRoHDAd daemon (Cumulus Routing On the Host Docker Advertisement Daemon). The CRoHDAd daemon listens to the docker-engine API and advertises new container IP addresses into the routed BGP fabric as they are created. When containers are destroyed, the daemon also removes the host-routes from the fabric.

Using this technique you can deploy containers from a single large 172.16.0.0/16 subnet owned by multiple docker bridges on different hosts and located in different racks throughout the DC.

### Software in Use:
*On Spines and Leafs:*
  * Cumulus v3.2.0

*On Servers:*
* Ubuntu 16.04
* Docker-CE v17.03
* cumulusnetworks/quagga:crohdad (container image)
* php:5.6-apache (container image)


Quickstart: Run the demo
------------------------
Before running this demo, install [VirtualBox](https://www.virtualbox.org/wiki/Download_Old_Builds) and [Vagrant](https://releases.hashicorp.com/vagrant/). The currently supported versions of VirtualBox and Vagrant can be found on the main [cldemo-vagrant](https://github.com/cumulusnetworks/cldemo-vagrant#prerequisites) documentation page under the "prequisites" section.

Once the prequisites have been installed, proceed with the steps below.

```
git clone https://github.com/cumulusnetworks/cldemo-vagrant
cd cldemo-vagrant

vagrant up oob-mgmt-server oob-mgmt-switch
vagrant up leaf01 leaf02 leaf03 leaf04 spine01 spine02 server01 server02 server03 server04

vagrant ssh oob-mgmt-server
sudo su - cumulus

git clone https://github.com/CumulusNetworks/cldemo-roh-dad.git
cd cldemo-roh-dad

ansible-playbook ./run-demo.yml
```
### Viewing the Results

#### Understanding Which Containers Are Where
After the demo has been deployed 20 containers will have been deployed.
* 4 "RoH" containers (1 per Server) -- This container runs the Cumulus Quagga instance.
* 4 "crohdad" containers (1 per Server) -- This container runs the CRoHDAd daemon and advertises new containers into kernel routing table 30
* 12 "workload" containers (4 per Server) -- This container runs our workloads at different unique IP Addresses.
  * Server01 -- 172.16.1.1, 172.16.2.1, 172.16.3.1
  * Server02 -- 172.16.1.2, 172.16.2.2, 172.16.3.2
  * Server03 -- 172.16.1.3, 172.16.2.3, 172.16.3.3
  * Server04 -- 172.16.1.4, 172.16.2.4, 172.16.3.4

#### Watch The CRoHDAd Daemon Advertising Routes
View the output of the CRoHDAd daemon as it is advertising /32 host-routes in the the new kernel routing table.
```
vagrant ssh oob-mgmt-server
sudo su - cumulus
ssh server01
sudo docker logs crohdad
ip route show table 30
ip route show table containers #They are two names for the same routing table.
sudo docker exec -it cumulus-roh /usr/bin/vtysh -c "show ip bgp"

cumulus@server01:~$ sudo docker logs crohdad
RUNNING CRoHDAd: /root/crohdad.py -l &

################################################
#                                              #
#     Cumulus Routing On the Host              #
#       Docker Advertisement Daemon            #
#             --cRoHDAd--                      #
#         originally written by Eric Pulvino   #
#                                              #
################################################

 STARTING UP.

    *Adding All Host Routes to Table 30*
      Run "ip route show table 30" to see routes.
    Flushing any pre-existing routes from table 30.


  Auto-Detecting existing containers and adding host routes...
  Listening for Container Activity...


[hit enter key to exit] or run 'docker stop <container>'
STARTED -- Container id: a1891dd5e347a6704bedd688c6e75a3aa642439c601d966aa31a69b0c2c9510c
    ADDING Host Route: 172.16.1.1/32 (from container: a1891dd5e347)
STARTED -- Container id: f1e7e0f949d535d8a5f0a790fba96c56618b02a0bca474d3eb9930b4089252c1
    ADDING Host Route: 172.16.2.1/32 (from container: f1e7e0f949d5)
STARTED -- Container id: 3dfc55907502140a4f0bcdbc912f3d6887e635344a64452b4eedef8236836d19
    ADDING Host Route: 172.16.3.1/32 (from container: 3dfc55907502)
cumulus@server01:~$ ip route show table 30
172.16.1.1 dev docker-neta  scope link 
172.16.2.1 dev docker-neta  scope link 
172.16.3.1 dev docker-neta  scope link 
cumulus@server01:~$ ip route show table containers
172.16.1.1 dev docker-neta  scope link 
172.16.2.1 dev docker-neta  scope link 
172.16.3.1 dev docker-neta  scope link 

cumulus@server01:~$ sudo docker exec -it cumulus-roh /usr/bin/vtysh -c "show ip bgp"
BGP table version is 22, local router ID is 10.0.0.31
Status codes: s suppressed, d damped, h history, * valid, > best, = multipath,
              i internal, r RIB-failure, S Stale, R Removed
Origin codes: i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric LocPrf Weight Path
*> 10.0.0.11/32     eth1            0             0 65011 i
*                   eth2                          0 65012 65020 65011 i
*  10.0.0.12/32     eth1                          0 65011 65020 65012 i
*>                  eth2            0             0 65012 i
*> 10.0.0.13/32     eth1                          0 65011 65020 65013 i
*                   eth2                          0 65012 65020 65013 i
*> 10.0.0.14/32     eth1                          0 65011 65020 65014 i
*                   eth2                          0 65012 65020 65014 i
*> 10.0.0.21/32     eth1                          0 65011 65020 i
*                   eth2                          0 65012 65020 i
*> 10.0.0.22/32     eth1                          0 65011 65020 i
*                   eth2                          0 65012 65020 i
*> 10.0.0.31/32     0.0.0.0                  0         32768 i
*> 10.0.0.32/32     eth1                          0 65011 65032 i
*                   eth2                          0 65012 65032 i
*> 10.0.0.33/32     eth1                          0 65011 65020 65013 65033 i
*                   eth2                          0 65012 65020 65013 65033 i
*> 10.0.0.34/32     eth1                          0 65011 65020 65013 65034 i
*                   eth2                          0 65012 65020 65013 65034 i
*> 172.16.1.1/32    0.0.0.0                  0         32768 ?
*> 172.16.1.2/32    eth1                          0 65011 65032 ?
*                   eth2                          0 65012 65032 ?
*> 172.16.1.3/32    eth1                          0 65011 65020 65013 65033 ?
*                   eth2                          0 65012 65020 65013 65033 ?
*> 172.16.1.4/32    eth1                          0 65011 65020 65013 65034 ?
*                   eth2                          0 65012 65020 65013 65034 ?
*> 172.16.2.1/32    0.0.0.0                  0         32768 ?
*> 172.16.2.2/32    eth1                          0 65011 65032 ?
*                   eth2                          0 65012 65032 ?
*> 172.16.2.3/32    eth1                          0 65011 65020 65013 65033 ?
*                   eth2                          0 65012 65020 65013 65033 ?
*> 172.16.2.4/32    eth1                          0 65011 65020 65013 65034 ?
*                   eth2                          0 65012 65020 65013 65034 ?
*> 172.16.3.1/32    0.0.0.0                  0         32768 ?
*> 172.16.3.2/32    eth1                          0 65011 65032 ?
*                   eth2                          0 65012 65032 ?
*  172.16.3.3/32    eth2                          0 65012 65020 65013 65033 ?
*>                  eth1                          0 65011 65020 65013 65033 ?
*> 172.16.3.4/32    eth1                          0 65011 65020 65013 65034 ?
*                   eth2                          0 65012 65020 65013 65034 ?

Displayed  22 out of 40 total prefixes

```

#### Test Application Reachability
Here we are using PHP/Apache webservers to represent our container workloads. To test that the applications are reachable across the fabric login to server01 and use the _curl_ command to view an application running on a container across the fabric.
```
vagrant ssh oob-mgmt-server
sudo su - cumulus
ssh server01
curl 172.16.1.4

cumulus@server01:~$ curl 172.16.1.4
<html>
<body>
<h1>HOST: server04 Container ID: 1e473deb7dc6 </h1>
<h1>
Container IPv4 address: 172.16.1.4/16
 </h1>
</body>
</html>
```

## Special Notes

### Privileged Mode Containers
The CRoHDAd container is deployed as a privileged container with access to the "host" network. This means that the applications running in the container have unfettered access to the interfaces and kernel just like a real baremetal application would. This can be dangerous if the container were to become comprimised as the container essentially has root access.

### Exposing the Docker Unix Socket
The docker CLI is essentially a client that communicates with the Dockerd daemon which runs in the background. That communication happens by default on Linux systems over a Unix Socket which behaves much like a webserver port. When running the CRoHDAd container it is necessary to share this Unix Socket file with the running container so that the docker CLI running inside the container can listen to the docker-engine API to learn about containers and networks as they are reated and destroyed.

### Manually Starting and Stopping the CRoHDAd Container
If you want to try running the CRoHDAd container in your own environment you can use the automation provided in this repository as a starting point or experiment manually with the container. Notice we're passing in the Quagga.conf file as well to configure the Quagga Routing Daemon upon container startup.

```
# Start the Container
docker run -itd --name=crohdad --privileged --net=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /etc/iproute2/rt_tables:/etc/iproute2/rt_tables \
    cumulusnetworks/crohdad:latest

# Stop the Container
docker rm -f crohdad
```

ASCII Demo Topology
-------------------
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

This demo is written using Ansible 2.2. Install Ansible on the management server
before you begin. Instructions for installing Ansible can be found here:
https://docs.ansible.com/ansible/intro_installation.html
