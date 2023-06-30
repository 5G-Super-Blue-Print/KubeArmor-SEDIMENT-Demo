# KubeArmor-SEDIMENT-Demo

Details of the demo could be [found here](https://wiki.lfnetworking.org/pages/viewpage.action?pageId=82905466).

Our objective is to demonstrate the 5G SBP Use Case - Remote Attestation Use Case 1- IoT Device Security and Authentication, where SEDIMENT RA Verifier and Relying Party are containerized and deployed with KubeArmor providing visibility and protection policies. Initially the result of attestation is used to control access to an example application.

![KubeArmor-SEDIMENT](https://github.com/5G-Super-Blue-Print/KubeArmor-SEDIMENT-Demo/assets/9133227/7bab302e-f3d0-4e49-b9a8-0914a83204c5)

## What is SEDIMENT?

SEDIMENT (SEcure DIstributed IoT ManagemENT) uses a combination of software root of trust, remote attestation, and resource-efficient cryptography, to build a system that scales across heterogeneous computing platforms. The aim is to provide secure remote attestation framework that can be leveraged for lightweight devices.

## What is KubeArmor? 

KubeArmor is a runtime security enforcement system that restricts the behavior (such as process execution, file access, and networking operations) of pods, containers, and nodes (VMs) at the system level. KubeArmor leverages Linux security modules (LSMs) such as AppArmor, SELinux, or BPF-LSM to enforce user-specified policies. KubeArmor generates rich alerts/telemetry events with container/pod/namespace identities by leveraging eBPF.

**Observability**

KubeArmor provides container-aware observability information about the operations happening from host to containers, between the containers and inside the containers.

Observability data contains information about :

1) Processes Spawned
2) File accessed by the processes
3) Network Connections made into or from the pods.

**Enforcement**

KubeArmor can be used to apply security postures at the kernel-level (using LSMs like AppArmor, BPF-LSM). It can protect both the host and workloads running on it by enforcing either some predefined security policies or automatically generated least permissive security policies (using Discovery Engine).

## KubeArmor on Sediment

### System Requirement

This guide assumes all the workloads will run on Ubuntu 22.04.
Firstly we need to deploy Sediment Containers, we have a pre-built docker container image for SEDIMENT and 
a shell convenience script `start.sh` to configure and initiate the containers.
Run each of the following commands in a separate terminal to initiate the containers.

        $ ./start.sh -c firewall
        $ ./start.sh -c verifier
        $ ./start.sh -c app_server
        $ ./start.sh -c prover         

Next we will run Sediment Containers & KubeArmor as a systemd process.

### Installation KubeArmor, kArmor and Discovery Engine

* **KubeArmor Installation:**

1. Download the [latest release](https://github.com/kubearmor/KubeArmor/releases) of KubeArmor  

```
wget hhttps://github.com/kubearmor/KubeArmor/releases/download/v0.10.2/kubearmor_0.10.2_linux-amd64.deb
```

2. Install KubeArmor 

```
sudo apt install ./kubearmor_0.10.2_linux-amd64.deb
```

> Note that the above automatically installs `bpfcc-tools` with our package, but your distribution might have an older version of BCC. In case of errors, consider installing `bcc` from [source](https://github.com/iovisor/bcc/blob/master/INSTALL.md#source).

3. Start KubeArmor

```
sudo systemctl start kubearmor
```

4. To check KubeArmor running status

```
sudo journalctl -u kubearmor -f
```

* **kArmor Installation:**

> **Note** kArmor should already be installed by the above KubeArmor installation. Check installation using `karmor version`.  

If kArmor is not installed run:    

```
curl -sfL http://get.kubearmor.io/ | sudo sh -s -- -b /usr/local/bin
```

* **Discovery Engine Installation:**

1. Download the [latest release](https://github.com/accuknox/discovery-engine/releases) of Discovery Engine  

```
wget https://github.com/accuknox/discovery-engine/releases/download/v0.8.1/knoxAutoPolicy_0.8.1_linux-amd64.deb
```

2. Install Discovery Engine 

```
sudo apt install ./knoxAutoPolicy_0.8.1_linux-amd64.deb
```

3. Start Discovery Engine  

```
sudo systemctl daemon-reload  
sudo systemctl start knoxAutoPolicy
```
If you have previously installed discovery-engine, it's adviced to restart the service `sudo systemctl restart knoxAutoPolicy`

4. To check Discovery Engine running status

```
sudo journalctl -u knoxAutoPolicy -f
```
* **KubeTLS Installation:**
??

* **Policy Enforecement:**

- To see alerts on policy violation, run on seprate terminal:

```
karmor logs --gRPC=:32767
```

- Now, let’s apply a sample policy: *block-secrets-access.yaml* using:

```
karmor vm policy add block-secrets-access.yaml
```

<details>
<summary>block-secrets-access.yaml</summary>

```yaml
apiVersion: security.kubearmor.com/v1
kind: KubeArmorPolicy
metadata:
  name: block-certificates-access
spec:
  severity: 10
  message: "a critical file was accessed"
  tags:
  - WARNING
  selector:
    matchLabels:
      kubearmor.io/container.name: sediment_firewall
  process:
    matchPaths:
      - path: /usr/sbin/update-ca-certificates
  file:
    matchDirectories:
    - dir: /usr/share/ca-certificates/
      recursive: true
    - dir: /etc/ssl/
      recursive: true
  action:
    Block
```
</details>

Here notice the field `kubearmor.io/container.name: sediment_firewall` sediment_firewall is the container name to which we want to apply the policy.

<details>
<summary>karmor log</summary>

```yaml
HostName: ip-172-31-0-78
NamespaceName: container_namespace
PodName: sediment_firewall
ContainerName: sediment_firewall
ContainerID: fdce222f5fc47175b539384e866f7594df8984bb7e6b4f0bb0195b8028c43e5b
Type: MatchedPolicy
PolicyName: sediment-demo-trusted-cert-mod
Severity: 1
Message: Credentials modification denied
Source: /usr/bin/touch a.pem
Resource: /etc/ssl/a.pem
Operation: File
Action: Block
Data: syscall=SYS_OPENAT fd=-100 flags=O_WRONLY|O_CREAT|O_NOCTTY|O_NONBLOCK
Enforcer: BPFLSM
Result: Permission denied
ATags: [MITRE MITRE_T1552_unsecured_credentials FGT1555 5G]
HostPID: 12408
HostPPID: 12241
PID: 456
PPID: 425
ParentProcessName: /usr/bin/bash
ProcessName: /usr/bin/touch
Tags: MITRE,MITRE_T1552_unsecured_credentials,FGT1555,5G
```
<details>
<summary>Available filters</summary>

```
--logFilter <system|policy|all> - Filter to receive general system logs (system) or alerts on policy violation (policy) or both (all).
--logType <ContainerLog|HostLog> - Source of logs - ContainerLog: logs from containers or HostLog: logs from the host
--operation <Process|File|Network> - Type of logs based on process, file or network
--container - Specify container name to view container specific logs
```
</details>
</details>

This will create an apparmor profile at `/etc/apparmor.d/` with the name `kubearmor_<containername>` (kubearmor_sediment_firewall here) and will load the profile to apparmor.
 
#### Apply the apparmor profile to the desired container
To run a container with KubeArmor enforcement using the apparmor profile kubearmor_sediment_firewall, pass `--security-opt apparmor=kubearmor_sediment_firewall` with the `docker run` command or if using docker-compose add:`security_opts: apparmor=kubearmor_sediment_firewall` under the container name in the docker-compose.yaml.

* **KubeTLS Installation:**


### Observability

To get Observability data, run:

```
karmor summary --gRPC ":9089"
```

This will provide full observability for hosts as well as containers.

* To get Observabilty for spcific container, use `--conatiner` flag and provide container name.
* To get Observabilty for spcific type such as process, file or network, use `--type` flag.

<details>
<summary>karmor summary --gRPC=:9089 --container sediment_firewall --agg</summary>

```
  Pod Name        sediment_firewall    
  Namespace Name  container_namespace  
  Cluster Name                         
  Container Name  sediment_firewall    
  Labels                               

File Data
+-------------------------------+---------------------------------------------------------------------------------------------------+-------+------------------------------+--------+
|          SRC PROCESS          |                                       DESTINATION FILE PATH                                       | COUNT |      LAST UPDATED TIME       | STATUS |
+-------------------------------+---------------------------------------------------------------------------------------------------+-------+------------------------------+--------+
| /bin/sh                       | /etc/ld.so.cache                                                                                  | 1     | Fri Jun 30 12:10:45 UTC 2023 | Allow  |
| /bin/sh                       | /usr/lib/x86_64-linux-gnu/                                                                        | 1     | Fri Jun 30 12:10:45 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /                                                                                                 | 2     | Fri Jun 30 12:10:27 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /dev/                                                                                             | 157   | Fri Jun 30 12:13:46 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /etc/group                                                                                        | 1     | Fri Jun 30 12:10:27 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /etc/ld.so.cache                                                                                  | 1     | Fri Jun 30 12:10:27 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /home/sediment/configs/boards/+                                                                   | 1     | Fri Jun 30 12:10:27 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /home/sediment/data                                                                               | 1     | Fri Jun 30 12:10:45 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /home/sediment/data/                                                                              | 7     | Fri Jun 30 12:10:45 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /proc/8605/mountinfo                                                                              | 1     | Fri Jun 30 12:10:26 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /pts/0                                                                                            | 1     | Fri Jun 30 12:10:27 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /pts/ptmx                                                                                         | 1     | Fri Jun 30 12:10:27 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /sys/kernel/mm/transparent_hugepage/hpage_pmd_size                                                | 1     | Fri Jun 30 12:10:26 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /usr/lib/x86_64-linux-gnu/                                                                        | 12    | Fri Jun 30 12:10:27 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /var/lib/docker/overlay2/e745fee3d3fb80506a11f87c21719d7824bae6998e292bcd72b78d154ce091fc/merged  | 1     | Fri Jun 30 12:10:27 UTC 2023 | Allow  |
| /home/sediment/build/firewall | /var/lib/docker/overlay2/e745fee3d3fb80506a11f87c21719d7824bae6998e292bcd72b78d154ce091fc/merged/ | 17    | Fri Jun 30 12:10:26 UTC 2023 | Allow  |
+-------------------------------+---------------------------------------------------------------------------------------------------+-------+------------------------------+--------+


Ingress connections
+----------+-------------------------------+---------------+------+-----------+--------+-------+------------------------------+
| PROTOCOL |            COMMAND            |  POD/SVC/IP   | PORT | NAMESPACE | LABELS | COUNT |      LAST UPDATED TIME       |
+----------+-------------------------------+---------------+------+-----------+--------+-------+------------------------------+
| TCP      | /home/sediment/build/firewall | 192.168.2.200 | 8000 |           |        | 38    | Fri Jun 30 12:13:46 UTC 2023 |
| TCP      | /home/sediment/build/firewall | 192.168.2.101 | 8000 |           |        | 1     | Fri Jun 30 12:10:45 UTC 2023 |
+----------+-------------------------------+---------------+------+-----------+--------+-------+------------------------------+


Egress connections
+----------+-------------------------------+---------------+------+-----------+--------+-------+------------------------------+
| PROTOCOL |            COMMAND            |  POD/SVC/IP   | PORT | NAMESPACE | LABELS | COUNT |      LAST UPDATED TIME       |
+----------+-------------------------------+---------------+------+-----------+--------+-------+------------------------------+
| TCP      | /home/sediment/build/firewall | 192.168.2.101 | 8100 |           |        | 1     | Fri Jun 30 12:10:45 UTC 2023 |
| TCP      | /home/sediment/build/firewall | 192.168.2.102 | 8001 |           |        | 36    | Fri Jun 30 12:13:46 UTC 2023 |
+----------+-------------------------------+---------------+------+-----------+--------+-------+------------------------------+


Bind Points
+------------+-------------------------------+-----------+--------------+-------+------------------------------+
|  PROTOCOL  |            COMMAND            | BIND PORT | BIND ADDRESS | COUNT |      LAST UPDATED TIME       |
+------------+-------------------------------+-----------+--------------+-------+------------------------------+
| AF_INET    | /home/sediment/build/firewall | 8000      | 0.0.0.0      | 1     | Fri Jun 30 12:10:26 UTC 2023 |
| AF_NETLINK | /home/sediment/build/firewall |           |              | 2     | Fri Jun 30 12:10:26 UTC 2023 |
+------------+-------------------------------+-----------+--------------+-------+------------------------------+
```

<details>
<summary>Available filters</summary>

```
--agg                Aggregate destination files/folder path
--container string   Container name
--gRPC string        gRPC server information
-l, --labels string      Labels
-n, --namespace string   Namespace
-o, --output string      Export Summary Data in JSON (karmor summary -o json)
-p, --pod string         PodName
-t, --type string        Summary filter type : process|file|network  (default "process,file,network")
```
</details>

</details>


### KubeTLS
??

### Recommend Policies

KubeAmror provides a set of hardening policies that are based on industry-leading compliance and attack frameworks such as CIS, MITRE, NIST-800-53, and STIGs. These policies are designed to help you secure your workloads in a way that is compliant with these frameworks and recommended best practices.

We can get these harden policies using container image.
```
karmor recommend -i sediment:demo
```
This will generate harden policies in `out/sediment:demo` folder.

<details>
<summary>karmor recommend -i sediment:demo</summary>

```
INFO[0000] Found outdated version of policy-templates    Current Version=v0.2.3
INFO[0000] Downloading latest version [v0.2.1]          
INFO[0000] policy-templates updated                      Updated Version=v0.2.1
INFO[0000] pulling image                                 image="sediment:demo"
WARN[0001] Failed to pull image. Dumping generic policies. 
INFO[0001] No runtime policy generated for //sediment:demo 
created policy out/sediment-demo/maint-tools-access.yaml ...
created policy out/sediment-demo/trusted-cert-mod.yaml ...
created policy out/sediment-demo/system-owner-discovery.yaml ...
created policy out/sediment-demo/write-under-bin-dir.yaml ...
created policy out/sediment-demo/write-under-dev-dir.yaml ...
created policy out/sediment-demo/cronjob-cfg.yaml ...
created policy out/sediment-demo/pkg-mngr-exec.yaml ...
created policy out/sediment-demo/k8s-client-tool-exec.yaml ...
created policy out/sediment-demo/remote-file-copy.yaml ...
created policy out/sediment-demo/write-in-shm-dir.yaml ...
created policy out/sediment-demo/write-etc-dir.yaml ...
created policy out/sediment-demo/shell-history-mod.yaml ...
created policy out/sediment-demo/file-integrity-monitoring.yaml ...
output report in out/report.txt ...
  Container               | sediment:demo      
  OS                      | linux              
  Arch                    |                    
  Distro                  |                    
  Output Directory        | out/sediment-demo  
  policy-template version | v0.1.9             
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
|             POLICY             |           SHORT DESC           | SEVERITY | ACTION |                       TAGS                        |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| maint-tools-access.yaml        | Restrict access to maintenance | 1        | Audit  | PCI_DSS                                           |
|                                | tools (apk, mii-tool, ...)     |          |        | MITRE                                             |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| trusted-cert-mod.yaml          | Restrict access to trusted     | 1        | Block  | MITRE                                             |
|                                | certificated bundles in the OS |          |        | MITRE_T1552_unsecured_credentials                 |
|                                | image                          |          |        |                                                   |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| system-owner-discovery.yaml    | System Information Discovery   | 3        | Block  | MITRE                                             |
|                                | - block system owner discovery |          |        | MITRE_T1082_system_information_discovery          |
|                                | commands                       |          |        |                                                   |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| write-under-bin-dir.yaml       | System and Information         | 5        | Block  | NIST NIST_800-53_AU-2                             |
|                                | Integrity - System Monitoring  |          |        | NIST_800-53_SI-4 MITRE                            |
|                                | make directory under /bin/     |          |        | MITRE_T1036_masquerading                          |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| write-under-dev-dir.yaml       | System and Information         | 5        | Audit  | NIST NIST_800-53_AU-2                             |
|                                | Integrity - System Monitoring  |          |        | NIST_800-53_SI-4 MITRE                            |
|                                | make files under /dev/         |          |        | MITRE_T1036_masquerading                          |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| cronjob-cfg.yaml               | System and Information         | 5        | Audit  | NIST SI-4                                         |
|                                | Integrity - System Monitoring  |          |        | NIST_800-53_SI-4                                  |
|                                | Detect access to cronjob files |          |        | CIS CIS_Linux                                     |
|                                |                                |          |        | CIS_5.1_Configure_Cron                            |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| pkg-mngr-exec.yaml             | System and Information         | 5        | Block  | NIST                                              |
|                                | Integrity - Least              |          |        | NIST_800-53_CM-7(4)                               |
|                                | Functionality deny execution   |          |        | SI-4 process                                      |
|                                | of package manager process in  |          |        | NIST_800-53_SI-4                                  |
|                                | container                      |          |        |                                                   |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| k8s-client-tool-exec.yaml      | Adversaries may abuse a        | 5        | Block  | MITRE_T1609_container_administration_command      |
|                                | container administration       |          |        | MITRE_TA0002_execution                            |
|                                | service to execute commands    |          |        | MITRE_T1610_deploy_container                      |
|                                | within a container.            |          |        | MITRE NIST_800-53 NIST_800-53_AU-2                |
|                                |                                |          |        | NIST_800-53_SI-4 NIST                             |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| remote-file-copy.yaml          | The adversary is trying to     | 5        | Block  | MITRE                                             |
|                                | steal data.                    |          |        | MITRE_TA0008_lateral_movement                     |
|                                |                                |          |        | MITRE_TA0010_exfiltration                         |
|                                |                                |          |        | MITRE_TA0006_credential_access                    |
|                                |                                |          |        | MITRE_T1552_unsecured_credentials                 |
|                                |                                |          |        | NIST_800-53_SI-4(18) NIST                         |
|                                |                                |          |        | NIST_800-53 NIST_800-53_SC-4                      |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| write-in-shm-dir.yaml          | The adversary is trying to     | 5        | Block  | MITRE_execution                                   |
|                                | write under shm folder         |          |        | MITRE                                             |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| write-etc-dir.yaml             | The adversary is trying to     | 5        | Block  | NIST_800-53_SI-7 NIST                             |
|                                | avoid being detected.          |          |        | NIST_800-53_SI-4 NIST_800-53                      |
|                                |                                |          |        | MITRE_T1562.001_disable_or_modify_tools           |
|                                |                                |          |        | MITRE_T1036.005_match_legitimate_name_or_location |
|                                |                                |          |        | MITRE_TA0003_persistence                          |
|                                |                                |          |        | MITRE MITRE_T1036_masquerading                    |
|                                |                                |          |        | MITRE_TA0005_defense_evasion                      |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| shell-history-mod.yaml         | Adversaries may delete or      | 5        | Block  | NIST NIST_800-53 NIST_800-53_CM-5                 |
|                                | modify artifacts generated     |          |        | NIST_800-53_AU-6(8)                               |
|                                | within systems to remove       |          |        | MITRE_T1070_indicator_removal_on_host             |
|                                | evidence.                      |          |        | MITRE MITRE_T1036_masquerading                    |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+
| file-integrity-monitoring.yaml | File Integrity Monitoring      | 1        | Block  | NIST NIST_800-53_AU-2                             |
|                                |                                |          |        | NIST_800-53_SI-4 MITRE                            |
|                                |                                |          |        | MITRE_T1036_masquerading                          |
|                                |                                |          |        | MITRE_T1565_data_manipulation                     |
+--------------------------------+--------------------------------+----------+--------+---------------------------------------------------+

```
</details>
Some of the harden policies generated are:

1) Restrict access to trusted cert bundles in the OS, prevents unauthorized updates to root certs
2) Restrict access to maintenance tools such as apk, mii-tool

These generated harden policies can be directly applied for enforcement. To apply one such generated harden policy `maint-tools-access.yaml`

<details>
<summary>maint-tools-access.yaml</summary>

```
apiVersion: security.kubearmor.com/v1
kind: KubeArmorPolicy
metadata:
  name: sediment-demo-maint-tools-access
spec:
  action: Audit
  message: restricted maintenance tool access attempt detected
  process:
    matchDirectories:
    - dir: /sbin/
      recursive: true
  selector:
    matchLabels:
      kubearmor.io/container.name: sediment
  severity: 1
  tags:
  - PCI_DSS
  - MITRE

```
</details>

```
karmor vm policy add maint-tools-access.yaml
```
> **Note**: label `kubearmor.io/container.name` value is image name, therfore update the value for label to the container name before applying policy.


### Auto discover least permissive security policy

`karmor discover` tool can be used to automatically generate security policies. The output of the command can be redirected to a yaml file
```
karmor discover --gRPC=:9089 --format yaml --labels "kubearmor.io/container.name=sediment_verifier" > discovered_policy.yaml
```
This yaml file can be applied to KubeArmor to provide least permissive security posture for the sediment_firewall-service container.  

<details>
<summary>discovered_policy.yaml</summary>

```
apiVersion: security.kubearmor.com/v1
kind: KubeArmorPolicy
metadata:
  name: autopol-system-165939104
  namespace: container_namespace
spec:
  action: Allow
  file:
    matchDirectories:
    - dir: /
      recursive: true
    - dir: /lib/x86_64-linux-gnu/
      recursive: true
    matchPaths:
    - path: /home/sediment/build/verifier
      readOnly: true
  process:
    matchPaths:
    - path: /home/sediment/build/verifier
  selector:
    matchLabels:
      kubearmor.io/container.name: sediment_verifier
  severity: 1

```
</details>

To apply security policy `discovered_policy.yaml`  

```
karmor vm policy add discovered_policy.yaml
```
> **Note**: Host security policies are identified by `kind: KubeArmorHostPolicy` and Container security policies have `kind: KubeArmorPolicy`. 

