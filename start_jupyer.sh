#!/bin/bash -e

# Enable http_over_ws
jupyter serverextension enable --py jupyter_http_over_ws

# Run jupyer notebook
jupyter notebook --NotebookApp.allow_origin='https://colab.research.google.com' --port=8081
