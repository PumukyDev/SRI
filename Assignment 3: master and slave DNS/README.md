# DNS Server

## :gem: Description

In this exercise, we will create a virtual network using Vagrant that includes a master DNS server (Tierra) and a slave DNS server (Venus), both implemented with BIND. The primary goal of this project is to establish a redundant DNS infrastructure, ensuring that DNS queries are resolved reliably through the zone transfer mechanism from the master to the slave server.

> All the machines will be in the network **192.168.57.0/24**

**Network structure:**

|      Machine      | Fully Qualified Domain Name (FQDN) |     IP     |
|       :---:       |                :---:               |   :---:    |
|  Imaginary Linux  |        mercurio.sistema.test       |   .101     |
|      Debian1      |          venus.sistema.test        |   .102     |
|      Debian2      |         tierra.sistema.test        |   .103     |
| Imaginary Windows |          marte.sistema.test        |   .104     |

**Master Server (Tierra):**
Acts as the authoritative DNS server for the domain, holding the main zone files. Configured to propagate updates via zone transfers to the slave server and is the primary point for DNS query resolution.

**Slave Server (Venus):**
Works as a secondary DNS server, receiving data through zone transfers from the master server. It ensures DNS service continuity by responding to queries when the master server is unavailable.

**Mail Server (Marte):**
Handles mail delivery within the domain, configured as the primary MX (Mail Exchange) record in the DNS configuration. It manages mail flow and ensures proper email routing for system.test.

**Additional Server (Mercurio):**
This server is part of the network to simulate additional host resolution. It’s listed as an A record in the DNS setup and is used for testing and verifying DNS resolution across the network.

## :gear: DNS Configuration

The zone file definitions and BIND configurations are managed through files located in `/etc/bind/` for the main settings and in `/var/lib/bind/` for the zone data files.

Configuration Files:

- **named:** In this file, we configured the server to listen only on the IPv4 protocol by adding the `-4` parameter.

  ```
  # run resolvconf?
  RESOLVCONF=no

  # startup options for the server
  OPTIONS="-u bind -4"
  ```

> This file must be copied to **both** the master and slave machines.

- **named.conf.options:** This file is used to configure general options that affect the server. The following changes were made:
  - Set dnssec-validation to yes, enabling DNSSEC validation to ensure that DNS requests have not been tampered with during transmission.

  ```
  dnssec-validation yes;
  ```

  - Created ACL groups so that the servers allow recursive queries only from machines in the `127.0.0.0/8` and `192.168.57.0/24` networks.

  ```
    acl "localnet" {
      192.168.57.0/24; // Local network
  };

  acl "trusted" {
      127.0.0.0/8;     // Loopback network
      localnet;        // Local network
  };
  ```

  ```
  options{
    ...
    recursion yes;
    allow-recursion {
            trusted;      // Allow recursive queries only from trusted ACLs
    };
    ...
  }
  ```

  - Configured the server to forward queries it’s not authoritative for to the DNS server `208.67.222.222` (OpenDNS).

  ```
  forwarders {
                208.67.222.222;   // OpenDNS server
         };
  ```
  
  - Set the master and slave servers to listen on port 53:

  ```
  listen-on port 53 {
  192.168.57.103;     // Master - tierra
  192.168.57.102;     // Slave  - venus
  };
  ```

- **named.conf.local (master):** This file is configured for the master server to have direct and reverse authority over the zones.

  ```
  //
  // Do any local configuration here
  //

  // Consider adding the 1918 zones here, if they are not used in your
  // organization
  //include "/etc/bind/zones.rfc1918";

  zone "sistema.test" {
      type master;
      file "/var/lib/bind/sistema.test.dns";  //Direct zone file (name --> IP)
      allow-transfer { 192.168.57.102; };
  };

  zone "57.168.192.in-addr.arpa" {
      type master;
      file "/var/lib/bind/sistema.test.rev";  //Reverse zone file (IP --> name)
      allow-transfer { 192.168.57.102; };
  };
  ```

- **named.conf.local (slave):** This file is configured for the slave server.

  ```
  //
  // Do any local configuration here
  //

  // Consider adding the 1918 zones here, if they are not used in your
  // organization
  //include "/etc/bind/zones.rfc1918";

  zone "sistema.test" {
      type slave;
      file "/var/lib/bind/sistema.test.dns";  //Direct zone file (name --> IP)
      masters { 192.168.57.103; };
  };

  zone "57.168.192.in-addr.arpa" {
      type slave;
      file "/var/lib/bind/sistema.test.rev";  //Reverse zone file (IP --> name)
      masters { 192.168.57.103; };
  };
  ```


- **sistema.test.dns:** This is the forward zone file, containing IP addresses, aliases, and the mail server. 

>The negative response cache time is set to 2 hours.

  ```
  ;
  ; Zone configuration for sistema.test
  ;

  $TTL	86400
  $ORIGIN sistema.test.

  @	IN	SOA	tierra.sistema.test. root.sistema.test. (
              2024101902	; Serial
              604800		; Refresh
              86400		; Retry
              2419200		; Expire
              7200        ; Negative Cache TTL
  )

  ; Name servers
  @               IN      NS      tierra
  @               IN      NS      venus

  ; A records (IP addresses)
  mercurio        IN      A       192.168.57.101
  venus           IN      A       192.168.57.102
  tierra          IN      A       192.168.57.103
  marte           IN      A       192.168.57.104

  ; CNAME records (aliases)
  ns1             IN      CNAME   tierra
  ns2             IN      CNAME   venus
  mail            IN      CNAME   marte

  ; MX record (mail exchange)
  @               IN      MX      10 marte
  ```


- **sistema.test.rev:** This is the reverse zone file that maps IP addresses to hostnames. 

>The negative response cache time is also set to 2 hours.

  ```
  ;
  ; Reverse zone configuration for 57.168.192.in-addr.arpa
  ;

  $TTL	86400
  $ORIGIN 57.168.192.in-addr.arpa.

  @	IN	SOA	tierra.sistema.test. root.sistema.test. (
              2024101902	; Serial
              604800		; Refresh
              86400		; Retry
              2419200		; Expire
              7200        ; Negative Cache TTL
  )

  ; Name servers
  @               IN      NS      tierra.sistema.test.
  @               IN      NS      venus.sistema.test.

  ; PTR records (reverse lookups)
  101     IN      PTR     mercurio.sistema.test.
  102     IN      PTR     venus.sistema.test.
  103     IN      PTR     tierra.sistema.test.
  104     IN      PTR     marte.sistema.test.
  ```

## :gear: Vagrant Configuration

In the Vagrant configuration file (Vagrantfile), we'll add the following lines to avoid potential issues and reduce the startup time for the virtual machines:

  ```
  config.vm.box_check_update = false
  config.vbguest.auto_update = false
  config.ssh.insert_key = false
  ```

We will install Debian Bookworm (64-bit) on all machines and include provisioning steps to configure BIND using the configuration files we wrote earlier:

  ```
  config.vm.box = "debian/bookworm64"
  config.vm.provision "shell", inline: <<-SHELL
      apt-get update -y
      apt-get upgrade -y
      apt-get install -y bind9 bind9utils bind9-doc
      cp -v /vagrant/dns_conf/named /etc/default/
      cp -v /vagrant/dns_conf/named.conf.options /etc/bind/
    SHELL
  ```

**Master Server:**

To define the master server, we’ll use the following configuration:

  ```
  config.vm.define "master" do |m|
      m.vm.hostname = "tierra"
      m.vm.network "private_network", ip: "192.168.57.103"
      m.vm.provision "shell", inline: <<-SHELL
        cp -v /vagrant/dns_conf/master/named.conf.local /etc/bind/
        cp -v /vagrant/dns_conf/master/sistema.test.dns /var/lib/bind/
        cp -v /vagrant/dns_conf/master/sistema.test.rev /var/lib/bind/
        chown bind:bind /var/lib/bind/*
        systemctl restart named
      SHELL
  end
  ```

This sets up the master DNS server with the necessary files (named.conf.local, sistema.test.dns, and sistema.test.rev), assigns the correct permissions, and restarts the named service.

> [!WARNING]
> Files inside `/var/lib/bind/ have to belong to bind group to work properly.

**Slave Server:**

For the slave server configuration, we'll use the following setup:

  ```
  config.vm.define "slave" do |s|
      s.vm.hostname = "venus"
      s.vm.network "private_network", ip: "192.168.57.102"
      s.vm.provision "shell", inline: <<-SHELL
        cp -v /vagrant/dns_conf/slave/named.conf.local /etc/bind/
        systemctl restart named
      SHELL
  end
  ```

This ensures that the slave server (venus) is properly configured with its respective named.conf.local file and that the named service is restarted.

## :wrench: Checks

Verify that the master server can resolve type A records
<div align="center">
    <img src="images/checks/direct_dns_master" alt="direct_dns_master"/>
</div>

Verify that the slave server can resolve type A records
<div align="center">
    <img src="images/checks/direct_dns_slave" alt="direct_dns_slave"/>
</div>

Verify that the master server can reverse resolve its IP addresses
<div align="center">
    <img src="images/checks/reverse_dns_master" alt="reverse_dns_master"/>
</div>

Verify that the slave server can reverse resolve its IP addresses
<div align="center">
    <img src="images/checks/reverse_dns_slave" alt="reverse_dns_slave"/>
</div>

Verify that the master server can resolve the aliases ns1.sistema.test and ns2 sistema.test
<div align="center">
    <img src="images/checks/alias_dns_master" alt="alias_dns_master"/>
</div>

Verify that the slave server can resolve the aliases ns1.sistema.test and ns2 sistema.test
<div align="center">
    <img src="images/checks/alias_dns_slave" alt="alias_dns_slave"/>
</div>

Check that the master server shows tierra.sistema.test and venus.sistema.test on the NS servers of sistema.test
<div align="center">
    <img src="images/checks/NS_dns_master" alt="NS_dns_master"/>
</div>

Check that the slave server shows tierra.sistema.test and venus.sistema.test on the NS servers of sistema.test
<div align="center">
    <img src="images/checks/NS_dns_slave" alt="NS_dns_slave"/>
</div>

Check that the master server shows the marte server as the MX server of sistema.test.
<div align="center">
    <img src="images/checks/MX_dns_master" alt="MX_dns_master"/>
</div>

Check that the slave server shows the marte server as the MX server of sistema.test.
<div align="center">
    <img src="images/checks/MX_dns_slave" alt="MX_dns_slave"/>
</div>

Check that the zone transfer has been carried out between the master and slave DNS servers from the logs on the master machine
<div align="center">
    <img src="images/checks/log_AXFR_dns_master" alt="log_AXFR_dns_master"/>
</div>

Verify that the zone transfer between the master and slave DNS servers has been performed with dig on the slave machine
<div align="center">
    <img src="images/checks/AXFR_dns_slave" alt="AXFR_dns_slave"/>
</div>

Running test.sh to the master machine
<div align="center">
    <img src="images/checks/test_dns_master" alt="test_dns_master"/>
</div>

Running test.sh to the slave machine
<div align="center">
    <img src="images/checks/test_dns_slave" alt="test_dns_slave"/>
</div>



## :wrench: Setup 


To start the virtual machine, simply navigate to the project directory and run the following command:
    
    vagrant up