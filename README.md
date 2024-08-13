# AKS Private Platform
Deployment of AKS with API Server Integration leveraging Private Endpoints

## Reference Architecture ##
<img src="https://github.com/sn0rlaxlife/aks-private-platform/blob/main/ref.png"> 

## How to use this repository ##
Clone the repository
```shell
git clone https://github.com/sn0rlaxlife/aks-private-platform.git
```
Create a SSH Key for the Linux Machine for access prior you can run this if you don't have one.
```shell
ssh-keygen -t rsa -b 4096 -C "<your-email>@<email>.com"
```
After this command runs you will be prompted to enter a file in which to save the key if you want to use default as annotated in the code its located here (/home/<username>/.ssh/id_rsa)

After this you can enter a passphrase for added security (recommended) or leave it empty this will be saved ~/.ssh/id_rsa.pub

Change to our directory that will be required, ideally since this uses SSH keys you'll need to generate one prior
```shell
cd aks-private-platform
```

After you are in the directory if you don't have the preview enabled the following shell script is in the repository to assist you.
```shell
chmod +x ./preview.sh
./preview.sh
```
You will also need 'Microsoft.ContainerService' registered
```shell
chmod +x ./container.sh
./container.sh
```

Let this command run until it reflects registered back as output then you can use the repository further.

To run this ideally you'll have your terraform resources scanned prior to moving into production to ensure this meets your benchmarks, you can use Github Actions to push to Azure as well with running scans open-source such as tfsec is ran in the actions tab.
```shell
terraform init
```
Then once this runs we initialized our repository, you can now also run the planning phase to ensure we have everything properly set and catch any errors.
```shell
terraform plan -o aks.out
```

If this doesn't show any errors run the following
```shell
terraform apply
```

