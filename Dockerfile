# ==================================================================
# module list
# ------------------------------------------------------------------
# darknet       latest (git)
# torch         latest (git)
# python        3.6    (apt)
# pytorch       latest (pip)
# tensorflow    latest (pip)
# jupyter       latest (pip)
# opencv        4.1.2  (git)
# keras         latest (pip)
# transfomers   latest (pip)
# fastai        latest (pip)
# ==================================================================
ARG NOTEBOOK_PASSWORD

FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04
ENV LANG C.UTF-8
ENV NOTEBOOK_PASSWORD=$NOTEBOOK_PASSWORD
RUN APT_INSTALL="apt-get install -y --no-install-recommends" && \
    PIP_INSTALL="python -m pip install --upgrade --no-cache-dir --retries 10 --timeout 60" && \
    GIT_CLONE="git clone --depth 10" && \

    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \

    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common \
        && \
    add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main" && \
    apt-get update && \

# ==================================================================
# tools
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        apt-utils \
        ca-certificates \
        wget \
        git \
        vim \
        libssl-dev \
        curl \
        unzip \
        unrar \
        && \

    $GIT_CLONE https://github.com/Kitware/CMake ~/cmake && \
    cd ~/cmake && \
    ./bootstrap && \
    make -j"$(nproc)" install && \

# ==================================================================
# darknet
# ------------------------------------------------------------------

    $GIT_CLONE https://github.com/pjreddie/darknet.git ~/darknet && \
    cd ~/darknet && \
    sed -i 's/GPU=0/GPU=1/g' ~/darknet/Makefile && \
    sed -i 's/CUDNN=0/CUDNN=1/g' ~/darknet/Makefile && \
    make -j"$(nproc)" && \
    cp ~/darknet/include/* /usr/local/include && \
    cp ~/darknet/*.a /usr/local/lib && \
    cp ~/darknet/*.so /usr/local/lib && \
    cp ~/darknet/darknet /usr/local/bin && \

# ==================================================================
# torch
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        sudo \
        && \

    $GIT_CLONE https://github.com/nagadomi/distro.git ~/torch --recursive && \
    cd ~/torch && \
    bash install-deps && \
    sed -i 's/${THIS_DIR}\/install/\/usr\/local/g' ./install.sh && \
    ./install.sh && \

# ==================================================================
# python
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        software-properties-common \
        && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        python3.7 \
        python3.7-dev \
        python3-distutils-extra \
        && \
    wget -O ~/get-pip.py \
        https://bootstrap.pypa.io/get-pip.py && \
    python3.7 ~/get-pip.py && \
    ln -s /usr/bin/python3.7 /usr/local/bin/python3 && \
    ln -s /usr/bin/python3.7 /usr/local/bin/python && \
    $PIP_INSTALL \
        setuptools \
        && \
    $PIP_INSTALL \
        numpy \
        scipy \
        pandas \
        cloudpickle \
        scikit-image>=0.14.2 \
        scikit-learn \
        matplotlib \
        Cython \
        tqdm \
        && \

# ==================================================================
# pytorch
# ------------------------------------------------------------------

    $PIP_INSTALL \
        future \
        numpy \
        protobuf \
        enum34 \
        pyyaml \
        typing \
        && \
    $PIP_INSTALL \
        --pre torch torchvision -f \
        https://download.pytorch.org/whl/nightly/cu101/torch_nightly.html \
        && \

# ==================================================================
# tensorflow
# ------------------------------------------------------------------

    $PIP_INSTALL \
        https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-2.2.0-cp37-cp37m-manylinux2010_x86_64.whl \
        && \

# ==================================================================
# keras
# ------------------------------------------------------------------

    $PIP_INSTALL \
        h5py \
        keras \
        && \

# ==================================================================
# boost
# ------------------------------------------------------------------

    wget -O ~/boost.tar.gz https://dl.bintray.com/boostorg/release/1.69.0/source/boost_1_69_0.tar.gz && \
    tar -zxf ~/boost.tar.gz -C ~ && \
    cd ~/boost_* && \
    ./bootstrap.sh --with-python=python3.7 && \
    ./b2 install -j"$(nproc)" --prefix=/usr/local && \

# ==================================================================
# jupyter
# ------------------------------------------------------------------

    $PIP_INSTALL \
        jupyter \
        jupyterlab \
        jupyter_http_over_ws>=0.0.7 \
        && \

# ==================================================================
# Computer Vision - opencv
# ------------------------------------------------------------------

    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        pkg-config \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libjasper-dev \
        libdc1394-22-dev \
        && \

    $GIT_CLONE --branch 4.1.2 https://github.com/opencv/opencv ~/opencv && \
    mkdir -p ~/opencv/build && cd ~/opencv/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D WITH_IPP=OFF \
          -D WITH_CUDA=OFF \
          -D WITH_OPENCL=OFF \
          -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_EXAMPLES=OFF \
          -D WITH_LIBV4L=ON \
          .. && \
    make -j"$(nproc)" install && \
    ln -s /usr/local/include/opencv4/opencv2 /usr/local/include/opencv2 && \

# ==================================================================
# NLP - transformers
# ------------------------------------------------------------------

    $PIP_INSTALL \
        transformers \
        spacy \
        ftfy==4.4.3 \
        nltk \
        && \

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------

    ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/* ~/*

# ==================================================================
# Set up notebook config
# ------------------------------------------------------------------
COPY jupyter_notebook_config.py /root/.jupyter/
COPY start_jupyer.py /root/

EXPOSE 6006 8888
WORKDIR "/root/dl"