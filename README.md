# PenTest & Tools
Some tools and POCs in order to test several kind of techniques.
  
## Mitm
  
 - **phising**  
 A custom script launching an MITM attack and redirecting a specific domain to our phising web page.
  
 - **http_proxy**  
 A custom proxy that aims at stripping all https web page links and keeping unsecure connection with the proxy (VICTIM <-- **HTTP** --> MITMPROXY).  
 It works for any website with one insecure page (which reliably means HSTS is not used, or for specific subdomains).
  
## Fingerprint  

 - **lowhanging.sh**  
 A custom script used during the first steps of the OSCP Lab network's discovery.

  - **pillage.sh**  
 A simple script that aims at finding interesting files on a system thanks to a LFI previously found on the target.  
 [list of interesting files on Linux](http://pwnwiki.io/presence/linux/pillage.lst)
 [list of interesting files on Windows](http://pwnwiki.io/#!presence/windows/blind.md)
 *N.B: need to be migrated in python with multithreading"  

## Privesc  
  
 - **LinEnum.sh** (original one is here: [https://github.com/rebootuser/LinEnum](https://github.com/rebootuser/LinEnum))
 A famous privesc script for Linux customized a little bit:
  - check for SELinux  
  - check for adm group's users  
  - display raw /etc/fstab  
  - add some recommendations  

 - **privesc.bat**
 A custom privesc script for windows using accesschk.exe (needed to be uploaded in the same time, check [sysinternals](https://technet.microsoft.com/fr-fr/sysinternals/bb842062)).

## Network  

 - **killswitch.sh**  
 Forces traffic through VPN - no leakage if VPN shuts down.
  
## Algo  

 - **bruteforce**  
 Bruteforce algorithm with permutations and fixed position characters.
  
<br />
# [Vulnhub](https://www.vulnhub.com/) machines pwned
  
  - [Kioptrix 2014](https://www.vulnhub.com/entry/kioptrix-2014-5,62/)
  - [Kioptrix #1](https://www.vulnhub.com/entry/kioptrix-level-1-1,22/)
  - [Mr-Robot: 1](https://www.vulnhub.com/entry/mr-robot-1,151/)

<br />
# Favorite Links

[http://www.fuzzysecurity.com/tutorials/16.html](http://www.fuzzysecurity.com/tutorials/16.html)  
[https://github.com/pentestmonkey/windows-privesc-check](https://github.com/pentestmonkey/windows-privesc-check)  
[http://httpsecure.org/?works=windows-privilege-escalation-exploit](http://httpsecure.org/?works=windows-privilege-escalation-exploit)  
[http://pwnwiki.io/#!presence/windows/blind.md](http://pwnwiki.io/#!presence/windows/blind.md)  
[http://httpsecure.org/?works=windows-privilege-escalation-exploit](http://httpsecure.org/?works=windows-privilege-escalation-exploit)  
[https://github.com/rmusser01/Infosec_Reference/blob/master/Draft/Draft/Privilege%20Escalation%20%26%20Post-Exploitation.md](https://github.com/rmusser01/Infosec_Reference/blob/master/Draft/Draft/Privilege%20Escalation%20%26%20Post-Exploitation.md)  
[https://jivoi.github.io/2015/07/01/pentest-tips-and-tricks/](https://jivoi.github.io/2015/07/01/pentest-tips-and-tricks/)  
[https://dirtycow.ninja/](https://dirtycow.ninja/)  
[https://blog.g0tmi1k.com/2011/08/basic-linux-privilege-escalation/](https://blog.g0tmi1k.com/2011/08/basic-linux-privilege-escalation/)  
[https://github.com/PenturaLabs/Linux_Exploit_Suggester](https://github.com/PenturaLabs/Linux_Exploit_Suggester)  
[https://www.kernel-exploits.com/](https://www.kernel-exploits.com/)  
[https://www.youtube.com/watch?v=kMG8IsCohHA](https://www.youtube.com/watch?v=kMG8IsCohHA)  
[https://www.exploit-db.com/](https://www.exploit-db.com/)  
[http://www.securityfocus.com/](http://www.securityfocus.com/)  
[https://exploits.shodan.io/welcome](https://exploits.shodan.io/welcome)  
[https://packetstormsecurity.com/files/tags/exploit/](https://packetstormsecurity.com/files/tags/exploit/)