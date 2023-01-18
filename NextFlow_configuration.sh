#Install Nextflow
curl -s https://get.nextflow.io | bash
#or
#wget -qO- https://get.nextflow.io | bash
chmod +x nextflow

#Create GENOR directory
mkdir GENOR
cd GENOR

#Install JAVA (UPO Cluster has Java v. 1.8 but Nextflow needs 17/18)
curl -s "https://get.sdkman.io" | bash
sdk install java

#Install seqtk
git clone https://github.com/lh3/seqtk.git;
cd seqtk; make
export PATH=$PATH:/home/user/GENOR/seqtk
