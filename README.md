# PENTEST & TOOLS
Some tools and POCs in order to test several kind of techniques.
  
## MITM
  
 - **phishing/phishing.sh**  
 A custom script launching an MITM attack and redirecting a specific domain to our phising web page.
  
 - **[mitm.sh](https://github.com/phackt/mitm)**  *(with [Mitmproxy](https://github.com/mitmproxy/mitmproxy)) - has it's own repo*
 A custom proxy that aims at stripping all https web page links and keeping unsecure connection with the proxy (VICTIM <-- **HTTP** --> MITMPROXY).  
 It works for any websites with at least one insecure page (which reliably means HSTS is not used for the current domain).  
 You can control and do whatever you want with the trafic thanks to custom **Python scripts**.
  
## FINGERPRINT  

 - **lowhanging.sh**  
 A custom script used during the first steps of the OSCP Lab network's discovery.

 - **pillage.sh**  
 A simple script that aims at finding interesting files on a system thanks to a LFI previously found on the target.  
 [list of interesting files on Linux](http://pwnwiki.io/presence/linux/pillage.lst)  
 [list of interesting files on Windows](http://pwnwiki.io/#!presence/windows/blind.md)  
 *N.B: need to be migrated in python with multithreading*  

## PRIVILEGE ESCALATION  
  
 - **LinEnum.sh** (original one is here: [https://github.com/rebootuser/LinEnum](https://github.com/rebootuser/LinEnum))  
 A famous privesc script for Linux customized a little bit:
   - check for SELinux  
   - check for adm group's users  
   - display raw /etc/fstab  
   - add some recommendations  

 - **privesc.bat**  
 A custom privesc script for windows using accesschk.exe (needed to be uploaded in the same time, check [sysinternals](https://technet.microsoft.com/fr-fr/sysinternals/bb842062)).  

## NETWORK  
  
 - **killswitch.sh**  
 Forces traffic through VPN - no leakage if VPN shuts down.
  
## WORDLISTS  
  
 - **full-php-files.txt** (full PHP filenames) 
 - **dorks-lfi-rfi.txt** (dorks for LFI/RFI)  
 
## ALGORITHMS  

 - **bruteforce/java/**
 - **bruteforce/javascript/**    
 Bruteforce algorithms with permutations and fixed position characters.
  
<br />
## [VULNHUB](https://www.vulnhub.com/) MACHINES PWNED
  
  - [Kioptrix 2014](https://www.vulnhub.com/entry/kioptrix-2014-5,62/) - Beginner/Intermediate
  - [Kioptrix #1](https://www.vulnhub.com/entry/kioptrix-level-1-1,22/) - Beginner/Intermediate
  - [Mr-Robot: 1](https://www.vulnhub.com/entry/mr-robot-1,151/) - Beginner/Intermediate
  - [HackLab: Vulnix](https://www.vulnhub.com/entry/hacklab-vulnix,48/) - Beginner/Intermediate
  - [Stapler: 1](https://www.vulnhub.com/entry/stapler-1,150/) - Beginner/Intermediate
  - [Pegasus: 1](https://www.vulnhub.com/entry/pegasus-1,109/) *(Good one to get into the Format String vulnerability)* - Intermediate
  - [SpyderSec](https://www.vulnhub.com/entry/spydersec-challenge,128/) - Intermediate
  - [DC416: Basement](https://www.vulnhub.com/entry/dc416-2016,168/) *(VMs for DefCon Toronto's first offline CTF)* - *4/5 flags* - Intermediate+  
  - [SmashTheTux: 1.0.1](https://www.vulnhub.com/entry/smashthetux-101,138/) *Good for Stack/Off-By-One/Integer/FM Overflow and so on* - Intermediate
  - [Moria](http://www.abatchy.com/2017/03/moria-boot2root-vm.html)


<br />
## FAVORITE LINKS

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
[http://shell-storm.org/](http://shell-storm.org/)  
[http://www.xss-payloads.com/](http://www.xss-payloads.com/)
