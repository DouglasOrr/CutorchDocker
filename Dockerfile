FROM debian:8.2

# APT dependencies
RUN apt-get update              \
    && apt-get install -qy      \
        cmake                   \
        gfortran                \
        git-core                \
        g++>=4:4.9              \
        libtie-persistent-perl  \
        libreadline-dev         \
        make                    \
        module-init-tools       \
        unzip                   \
        wget                    \
    && apt-get clean

# NVIDIA drivers & CUDA runtime
RUN cd /tmp &&                                                                                                                 \
    wget -nv http://us.download.nvidia.com/XFree86/Linux-x86_64/352.41/NVIDIA-Linux-x86_64-352.41.run -O driver.run &&         \
    sh driver.run -s --no-kernel-module &&                                                                                     \
    wget -nv http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run -O cuda.run &&  \
    sh cuda.run --toolkit --silent &&                                                                                          \
    rm *

# OpenBLAS
RUN git clone https://github.com/xianyi/OpenBLAS.git -b v0.2.14 /tmp/openblas && \
    cd /tmp/openblas &&                                                          \
    make NO_AFFINITY=1 USE_OPENMP=1 &&                                           \
    make install &&                                                              \
    cd /tmp && rm -r *

# Torch7
# Due to breaking changes between torch/nn & dp:
# We must use a version of torch/nn before: 9716078afcc5023e28f39ab0020e66ed4208abb4
# I.e. torch distro before: a412c09dab2d16ddd52e40becc19256a05fbaa0b
RUN git clone https://github.com/torch/distro.git /opt/torch && \
    cd /opt/torch &&                                            \
    git checkout 35909345ba0a65bb414939d51d8f9e8e3cd052a5 &&    \
    ./install.sh -b &&                                          \
    ls | grep -v "^install$" | xargs rm -r && rm -r .git

# Setup paths
ENV PATH=/usr/local/cuda/bin:/opt/torch/install/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:/opt/torch/install/lib:${LD_LIBRARY_PATH}

CMD ["th"]
