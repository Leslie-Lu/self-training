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

import torch

def main():
    print("CUDA is available:", torch.cuda.is_available())
    print("CUDA device count:", torch.cuda.device_count())
    print("CUDA current device:", torch.cuda.current_device())
    print("CUDA device name:", torch.cuda.get_device_name(torch.cuda.current_device()))
    print("CUDA device properties:", torch.cuda.get_device_properties(torch.cuda.current_device()))
    print("CUDA memory allocated:", torch.cuda.memory_allocated())

if __name__ == "__main__":
    main()
