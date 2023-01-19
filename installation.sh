#Install Nextflow
curl -s https://get.nextflow.io | bash
#or
#wget -qO- https://get.nextflow.io | bash
chmod +x nextflow

#Create GENOR directory
mkdir /home/user/GENOR
cd /home/user/GENOR

#Install JAVA (Nextflow needs v17/v18)
curl -s "https://get.sdkman.io" | bash
sdk install java

#Install seqtk
git clone https://github.com/lh3/seqtk.git;
cd seqtk; make
export PATH=$PATH:/home/pedropatraquim/GENOR/seqtk
