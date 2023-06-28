# KubeArmor-SEDIMENT-Demo

Details of the demo could be [found here](https://wiki.lfnetworking.org/pages/viewpage.action?pageId=82905466).

Our objective is to demonstrate the 5G SBP Use Case - Remote Attestation Use Case 1- IoT Device Security and Authentication, where SEDIMENT RA Verifier and Relying Party are containerized and deployed with KubeArmor providing visibility and protection policies. Initially the result of attestation is used to control access to an example application.

![KubeArmor-SEDIMENT](https://github.com/5G-Super-Blue-Print/KubeArmor-SEDIMENT-Demo/assets/9133227/7bab302e-f3d0-4e49-b9a8-0914a83204c5)

## What is SEDIMENT?

SEDIMENT (SEcure DIstributed IoT ManagemENT) uses a combination of software root of trust, remote attestation, and resource-efficient cryptography, to build a system that scales across heterogeneous computing platforms. The aim is to provide secure remote attestation framework that can be leveraged for lightweight devices.

## What is KubeArmor? 

KubeArmor is a runtime security enforcement system that restricts the behavior (such as process execution, file access, and networking operations) of pods, containers, and nodes (VMs) at the system level. KubeArmor leverages Linux security modules (LSMs) such as AppArmor, SELinux, or BPF-LSM to enforce user-specified policies. KubeArmor generates rich alerts/telemetry events with container/pod/namespace identities by leveraging eBPF.

