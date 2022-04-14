# sitecore-module-docker-asset-image-creator

This repository contains a script to handle the auto creation of a Docker Asset Image for a given Sitecore module

- Clone the repo to your working machine
- Add the Sitecore module package to Package folder under root
- Then invoke the script as shown in example below to convert it into scwdp (used for Azure PaaS) as well as extract the scwdp into a Module folder used for generating the docker image
  ```powershell
   .\Create-SitecoreModule-DockerAssetImage.ps1 -ModulePackageName "Sitecore.PowerShell.Extensions-6.3.zip" -Tag "sitecorepowershell/sitecore-powershell-extensions:6.3-1809" -GenerateCdContentDirectory
  ```
- The folder name is generated based on the ModulePackageName provided while invoking the script and appends the current datetime stamp in `ModulePackageName_yyyyMMdd_HHmmss` format
- Run the docker file under Module folder to generate the image. The script only extracts it for CM role. For other roles, you have to manually create role specific docker files
- Once the image is generated, push it to your container registry to share it with other devs in your team or devops for AKS deployment

![image](https://user-images.githubusercontent.com/3968213/129932632-67ee772f-63da-421e-a476-dfe08635ca69.png)

# Contributors

Robbert Hock - Twitter: @kayeeNL, GitHub: https://github.com/KayeeNL
Anton Tishchenko - Twitter: @ativn, GitHub: https://github.com/Antonytm
Christopher Huemmer - Twitter: @chrishmmr, GitHub: https://github.com/chris-hmmr
Venkata Phani Abburi - Twitter: @phani_abburi, GitHub: https://github.com/phaniav
Kamruz Jaman - Twitter: @jammykam, GitHub: https://github.com/konabos
