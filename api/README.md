## api 

For any confidential computing platform for AI tasks you need confidential compute for that. So here we are trying to make a cloud connection as safe as possible.

## Provider

- Azure - https://techcommunity.microsoft.com/blog/azureconfidentialcomputingblog/general-availability-azure-confidential-vms-with-nvidia-h100-tensor-core-gpus/4242644?utm_source=chatgpt.com
- Google - https://docs.cloud.google.com/confidential-computing/confidential-vm/docs/create-a-confidential-vm-instance-with-gpu?utm_source=chatgpt.com&hl=de
- Phala - https://phala.com/gpu-tee

## How does it work?

- Do you provide Confidential VMs (SEV-SNP or Intel TDX) on the node that has the GPU?
- Can the H100 run in CC-On mode for customers?
- Do you support GPU attestation evidence retrieval from inside the VM, and a documented verification flow?
- Can I do key release only after attestation (KMS or your attestation service integration)?
- Is it bare metal or multi-tenant? If multi-tenant, what prevents host introspection?

## What to do now?

In order to proof the concept of having a secure connection i need to get an app / the compute at one of the above providers running and once i have this i want to verify that my connection is secure 

1. I can spin up a confidential GPU VM and independently verify its attestation report.

	•	Create CVM + H100
	•	Fetch attestation
	•	Verify claims
	•	Gate key release
	•	Load encrypted LLM
	•	Generate token