# PENTEST & TOOLS
Tools and more...
  
## FINGERPRINT  

 - **pillage.sh**  
 Finding interesting files on a system thanks to a LFI previously found on the target.  
 [list of interesting files on Linux](http://pwnwiki.io/presence/linux/pillage.lst)  
 [list of interesting files on Windows](http://pwnwiki.io/#!presence/windows/blind.md)  
 *N.B: need to be migrated in python with multithreading*  

 - **haveibeenpwned.sh** - Takes input emails and checking their pwned status on [https://haveibeenpwned.com/](https://haveibeenpwned.com/).

 - **versionchecker.sh**  
 versionchecker.sh will hash some input files and compare them to hashes computed from the specific GIT releases. It helps to identify for example a CMS version if some CHANGELOG.txt files are missing.  
 *Example of command: ./versionchecker.sh -s ./input -g ~/Documents/repo/drupal/ -p "^[78]\.[0-9.]+$"*  
 
 - **dns/knocktone.py**
   - convert knockpy json output file for aquatone-scan
   - DNS resolve and look for unresolved aliases
   - pip install -r requirements.txt
 

## PRIVILEGE ESCALATION  
  
 - **LinEnum.sh** (forked: [https://github.com/phackt/LinEnum/blob/master/LinEnum.sh](https://github.com/phackt/LinEnum/blob/master/LinEnum.sh))  
 Famous privesc script for Linux enchanced according to my needs:
   - check for SELinux  
   - check for adm group's users  
   - display raw /etc/fstab  
   - add some recommendations  

 - **linux/lin_shell_bind_tcp.c** - /bin/sh TCP bind shell.
 - **linux/lin_reverse_tcp_shell.c** - /bin/sh TCP reverse shell.
 - **linux/uid_gid_root_shell.c** - setreuid/setregid root /bin/sh shell.

 - **windows/privesc.bat** - Custom privesc script for windows using accesschk.exe (needed to be uploaded in the same time, check [sysinternals](https://technet.microsoft.com/fr-fr/sysinternals/bb842062)).  

 - **windows/wmic_info.bat** - Relevant information thanks to the WMI command-line utility.
 - **windows/win_user_add.c** - Add Windows user to local group Administrators.

## EXPLOITS  
  
 - **shellshock_webshell.py** - Exploits a vuln cgi script (shellshock - GNU Bash through 4.3).
 - **egg_hunter.c** - A 18 bytes Egg-Hunter shellcode ([https://www.exploit-db.com/exploits/41909/](https://www.exploit-db.com/exploits/41909/))
 - **rce_phpmailer_exim.py** - Reverse shell linux exploit for PHPMailer < 5.2.20, SwiftMailer <= 5.4.5-DEV, zend-mail < 2.4.11 with Exim MTA  
 - **xss/keylogger.js** - Keylogger in javascript useful when XSS found or browser cache poisoning while MITM
 - **xss/formscapture.js** - Set a callback function on all forms submit event  
  
## NETWORK  
  
 - **killswitch.sh** - Forces traffic through VPN - no leakage if VPN shuts down.
 - **mitm/phishing.sh** - Launches an MITM attack and redirecting a specific domain to our phising web page.
  
 - **[mitm.sh](https://github.com/phackt/mitm)**  *(with [Mitmproxy](https://github.com/mitmproxy/mitmproxy)) - has it's own repo*  
 A custom proxy that aims at stripping all HTTPS web page links and keeping unsecure connection with the proxy: VICTIM <-- **HTTP** --> MITMPROXY <-- **HTTPS** --> WEBSITE.  
 It works for any websites with at least one insecure page (which reliably means HSTS is not used for the current domain).  
 You can control and do whatever you want with the trafic thanks to custom **Python scripts**.  
  
## WORDLISTS  
  
 - **dorks-lfi-rfi.txt** (dorks for LFI/RFI)  
  
## DEV  

 - **bruteforce/java/**
 - **bruteforce/javascript/** - Bruteforce algorithms with permutations and fixed position characters.  

## [VULNHUB](https://www.vulnhub.com/) MACHINES PWNED  
  
  - [Kioptrix 2014](https://www.vulnhub.com/entry/kioptrix-2014-5,62/) - Beginner/Intermediate
  - [Kioptrix #1](https://www.vulnhub.com/entry/kioptrix-level-1-1,22/) - Beginner/Intermediate
  - [Mr-Robot: 1](https://www.vulnhub.com/entry/mr-robot-1,151/) - Beginner/Intermediate
  - [HackLab: Vulnix](https://www.vulnhub.com/entry/hacklab-vulnix,48/) - Beginner/Intermediate
  - [Stapler: 1](https://www.vulnhub.com/entry/stapler-1,150/) - Beginner/Intermediate
  - [Pegasus: 1](https://www.vulnhub.com/entry/pegasus-1,109/) *(Good one to get into the Format String vulnerability)* - Intermediate
  - [SpyderSec](https://www.vulnhub.com/entry/spydersec-challenge,128/) - Intermediate
  - [Moria](http://www.abatchy.com/2017/03/moria-boot2root-vm.html) - Intermediate
  - [Sokar: 1](https://www.vulnhub.com/entry/sokar-1,113/) - Intermediate
  - [SmashTheTux: 1.0.1](https://www.vulnhub.com/entry/smashthetux-101,138/) *Good for Stack/Off-By-One/Integer/FM Overflow and so on* - Intermediate
  - [DC416: Basement](https://www.vulnhub.com/entry/dc416-2016,168/) *(VMs for DefCon Toronto's first offline CTF)* - Intermediate+
  - [Damn Vulnerable Web Application (DVWA): 1.0.7](https://www.vulnhub.com/entry/damn-vulnerable-web-application-dvwa-107,43/) - WebApp pentesting ([here](https://github.com/ethicalhack3r/DVWA) for v1.9)  

  
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
