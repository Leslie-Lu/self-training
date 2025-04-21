###############################################################################################
# PROJECT NAME      : Python\pgm\deepLearning\p001_transformer.py
# DESCRIPTION       : Understand the transformer model and its components
# DATE CREATED      : 2025-04-19
# PYTHON VERSION    : 3.12.8
# LIBRARIES         : torch
# AUTHOR            : Zhen Lu
################################################################################################
# DATE MODIFIED     : 2025-04-19
# REASON            : Updated description and date created
################################################################################################

# Prelims
# !pip install -r requirements.txt # run in jupyter notebook
import os
from os.path import exists
import torch
import torch.nn as nn
from torch.nn.functional import log_softmax, pad
import math
import copy
import time
from torch.optim.lr_scheduler import LambdaLR
import pandas as pd
import altair as alt
from torchtext.data.functional import to_map_style_dataset
from torch.utils.data import DataLoader
from torchtext.vocab import build_vocab_from_iterator
import torchtext.datasets as datasets
import spacy
import GPUtil
import warnings
from torch.utils.data.distributed import DistributedSampler
import torch.distributed as dist
import torch.multiprocessing as mp
from torch.nn.parallel import DistributedDataParallel as DDP

def main():
    print("CUDA is available:", torch.cuda.is_available())
    # print("CUDA device count:", torch.cuda.device_count())
    # print("CUDA current device:", torch.cuda.current_device())
    # print("CUDA device name:", torch.cuda.get_device_name(torch.cuda.current_device()))
    # print("CUDA device properties:", torch.cuda.get_device_properties(torch.cuda.current_device()))
    # print("CUDA memory allocated:", torch.cuda.memory_allocated())

if __name__ == "__main__":
    main()
