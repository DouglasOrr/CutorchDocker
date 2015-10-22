# cutorch

Debian + CUDA + Torch (quite a lightweight installation of Torch). On:

 - [DockerHub](https://hub.docker.com/r/douglasorr/cutorch_7.0_346.96/)
 - [GitHub](https://github.com/DouglasOrr/CutorchDocker).

Take note of a few things:

The **host machine must have matching NVIDIA drivers** for this image (`346.96`).

As we don't use Torch's [ezinstall dependencies](https://github.com/torch/ezinstall/blob/master/install-deps), **Torch things might break** (e.g. in need of `apt` packages).

## Usage

    docker run -it --rm \
        --device /dev/nvidiactl --device /dev/nvidia-uvm --device /dev/nvidia0 \
        douglasorr/cutorch_7.0_346.96

## Building & publishing

Simple docker for setting up cutorch.

    docker build -t douglasorr/cutorch_7.0_346.96:<VERSION> .
    docker push douglasorr/cutorch_7.0_346.96:<VERSION>
    git push origin HEAD:refs/tags/nvidia_346.96_<VERSION>


## Building an AMI able to run this image

Here is what you can do:

    # Start from Ubuntu 14.04 [ami-f0b11187]

    # Add an init script for allowing ubuntu to own /mnt
    echo "#! /bin/sh"                  | sudo tee /etc/init.d/mnt_ubuntu
    echo "### BEGIN INIT INFO"         | sudo tee -a /etc/init.d/mnt_ubuntu
    echo "# Provides: mnt_ubuntu"      | sudo tee -a /etc/init.d/mnt_ubuntu
    echo "# Required-Start: mountall"  | sudo tee -a /etc/init.d/mnt_ubuntu
    echo "# Required-Stop:"            | sudo tee -a /etc/init.d/mnt_ubuntu
    echo "# Default-Start: 2 3 4 5"    | sudo tee -a /etc/init.d/mnt_ubuntu
    echo "# Default-Stop:"             | sudo tee -a /etc/init.d/mnt_ubuntu
    echo "### END INIT INFO"           | sudo tee -a /etc/init.d/mnt_ubuntu
    echo "chown -R ubuntu:ubuntu /mnt" | sudo tee -a /etc/init.d/mnt_ubuntu
    sudo chmod +x /etc/init.d/mnt_ubuntu
    sudo update-rc.d mnt_ubuntu defaults
    sudo chown -R ubuntu:ubuntu /mnt

    # Install docker
    # This keyserver can be kindof unreliable
    sudo apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | sudo tee /etc/apt/sources.list.d/docker.list
    sudo apt-get update
    sudo apt-get install -y docker-engine
    sudo gpasswd -a ${USER} docker
    # Configure docker to store things in /mnt (/dev/xvdb)
    echo 'DOCKER_OPTS="-g /mnt/docker"'    | sudo tee /etc/default/docker
    echo 'export TMPDIR="/mnt/docker-tmp"' | sudo tee -a /etc/default/docker
    sudo service docker restart

    # Install NVIDIA drivers (based on http://tleyden.github.io/blog/2014/10/25/cuda-6-dot-5-on-aws-gpu-instance-running-ubuntu-14-dot-04/)
    # 1. dependencies & kernel dependencies
    sudo apt-get update
    sudo apt-get install -y g++ make linux-image-extra-virtual linux-source linux-headers-generic
    # when prompted about /boot/grub/menu.lst, select "use package maintainers version"

    # 2. kill Nouveau (http://askubuntu.com/questions/451221/ubuntu-14-04-install-nvidia-driver)
    echo "blacklist nouveau"                   | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
    echo "blacklist blacklist lbm-nouveau"     | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
    echo "blacklist options nouveau modeset=0" | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
    echo "blacklist alias nouveau off"         | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
    echo "blacklist alias lbm-nouveau off"     | sudo tee -a /etc/modprobe.d/blacklist-nouveau.conf
    echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf
    sudo update-initramfs -u
    sudo reboot now

    # 3. install driver & temporarily use toolkit to build a sample (which is needed to create /dev/nvidia-uvm)
    mkdir /mnt/tmp
    cd /mnt/tmp
    wget -nv http://us.download.nvidia.com/XFree86/Linux-x86_64/346.96/NVIDIA-Linux-x86_64-346.96.run -O driver.run
    sudo sh driver.run -s
    wget -nv http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/cuda_7.0.28_linux.run -O cuda.run
    sh cuda.run --toolkit --silent --toolkitpath=/mnt/cuda
    cd /mnt/cuda/samples/1_Utilities/deviceQuery && make && sudo cp deviceQuery /usr/local/bin/cuda-device-query

    # 4. add an init script to force creation of /dev/nvidia-uvm (by running any simple CUDA program)
    echo "#! /bin/sh"                       | sudo tee /etc/init.d/force_nvidia_uvm
    echo "### BEGIN INIT INFO"              | sudo tee -a /etc/init.d/force_nvidia_uvm
    echo "# Provides: force_nvidia_uvm"     | sudo tee -a /etc/init.d/force_nvidia_uvm
    echo "# Required-Start: $local_fs"      | sudo tee -a /etc/init.d/force_nvidia_uvm
    echo "# Required-Stop:"                 | sudo tee -a /etc/init.d/force_nvidia_uvm
    echo "# Default-Start: 2 3 4 5"         | sudo tee -a /etc/init.d/force_nvidia_uvm
    echo "# Default-Stop:"                  | sudo tee -a /etc/init.d/force_nvidia_uvm
    echo "### END INIT INFO"                | sudo tee -a /etc/init.d/force_nvidia_uvm
    echo "/usr/local/bin/cuda-device-query" | sudo tee -a /etc/init.d/force_nvidia_uvm
    sudo chmod +x /etc/init.d/force_nvidia_uvm
    sudo update-rc.d force_nvidia_uvm defaults

    # 5. reboot & everything should be groovy
    sudo reboot now

    # Tried but broken on AWS GPUs
    # http://us.download.nvidia.com/XFree86/Linux-x86_64/352.41/NVIDIA-Linux-x86_64-352.41.run # broken
    # http://us.download.nvidia.com/XFree86/Linux-x86_64/352.55/NVIDIA-Linux-x86_64-352.55.run # broken
