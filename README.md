# cutorch

Debian + CUDA + Torch (quite a lightweight installation of Torch). On:

 - [DockerHub](https://hub.docker.com/r/douglasorr/cutorch_7.5_352.41/)
 - [GitHub](https://github.com/DouglasOrr/CutorchDocker).

Take note of a few things:

The **host machine must have matching NVIDIA drivers** for this image (`352.41`).

As we don't use Torch's [ezinstall dependencies](https://github.com/torch/ezinstall/blob/master/install-deps), **Torch things might break** (e.g. in need of `apt` packages).

## Usage

    docker run -it --rm \
        --device /dev/nvidiactl --device /dev/nvidia-uvm --device /dev/nvidia0 \
        douglasorr/cutorch_7.5_352.41

## Building & publishing

Simple docker for setting up cutorch.

    docker build -t douglasorr/cutorch_7.5_352.41:<VERSION> .
    docker push douglasorr/cutorch_7.5_352.41:<VERSION>
    git push origin HEAD:refs/tags/v<VERSION>
