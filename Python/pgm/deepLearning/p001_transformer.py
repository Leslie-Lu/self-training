###############################################################################################
# PROJECT NAME      : Python\pgm\deepLearning\p001_transformer.py
# DESCRIPTION       : Understand the transformer model and its components
# DATE CREATED      : 2025-04-19
# PYTHON VERSION    : 3.11.12
# LIBRARIES         : torch
# INSPIRED BY       : https://nlp.seas.harvard.edu/annotated-transformer/#prelims
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
import spacy
import GPUtil
import warnings
from torch.utils.data.distributed import DistributedSampler
import torch.distributed as dist
import torch.multiprocessing as mp
from torch.nn.parallel import DistributedDataParallel as DDP
from torchtext.datasets import multi30k, Multi30k


class DummyOptimizer(torch.optim.Optimizer):
    """
    Dummy optimizer for the sake of example.
    """

    def __init__(self):
        self.param_groups= [{'lr': 0}]
        None

    def step(self):
        None
        
    def zero_grad(self, set_to_none=False):
        None

class DummyScheduler:
    """
    Dummy scheduler for the sake of example.
    """

    def __init__(self, optimizer):
        self.optimizer= optimizer

    def step(self):
        None

# Part 1: Model Architecture
class EncoderDecoder(nn.Module):
    """
    A standard Encoder-Decoder architecture. Base for this and many other models.
    """

    def __init__(self, encoder, decoder, src_embed, tgt_embed, generator):
        """
        :encoder, processing input into memory
        :decoder, output based on encoder and current prediction
        :src_embed, embedding input
        :tget_embed: embedding output
        :generator: FC layer for output
        """
        super().__init__()
        self.encoder= encoder # transform loaded module into properties of class
        self.decoder= decoder
        self.src_embed= src_embed
        self.tgt_embed= tgt_embed
        self.generator= generator
    
    def forward(self, src, tgt, src_mask, tgt_mask):
        """
        Take in and process masked src and target sequences.
        """
        return self.decode(self.encode(src, src_mask), src_mask, tgt, tgt_mask)
    
    def encode(self, src, src_mask):
        return self.encoder(self.src_embed(src), src_mask)
    
    def decode(self, memory, src_mask, tgt, tgt_mask):
        return self.decoder(self.tgt_embed(tgt), memory, src_mask, tgt_mask)
    
class Generator(nn.Module):
    """
    Define standard linear + softmax generation step.
    """

    def __init__(self, d_model, vocab):
        super().__init__()
        self.proj= nn.Linear(d_model, vocab)

    def forward(self, x):
        return log_softmax(self.proj(x), dim=-1)

# Encoder and Decoder Stacks
# Encoder
def clones(module, N):
    "Produce N identical layers."
    return nn.ModuleList([copy.deepcopy(module) for _ in range(N)])

class Encoder(nn.Module):
    "Core encoder is a stack of N layers."

    def __init__(self, layer, N):
        super().__init__()
        self.layers= clones(layer, N)
        self.norm= LayerNorm(layer.size)
    
    def forward(self, x, mask):
        "Pass the input (and mask) through each layer in turn."
        for layer in self.layers:
            x= layer(x, mask)
        return self.norm(x)

# Employ a resudual connection around each of the two sub-layers, followed by layer normalization
class LayerNorm(nn.Module):
    "Construc a layernorm module."

    def __init__(self, features, eps=1e-6):
        super().__init__()
        self.a_2= nn.Parameter(torch.ones(features))
        self.b_2= nn.Parameter(torch.zeros(features))
        self.eps= eps

    def forward(self, x):
        mean= x.mean(-1, keepdim=True)
        std= x.std(-1, keepdim=True)
        return self.a_2 * (x - mean) / (std + self.eps) + self.b_2

# Apply dropout to the output of each sublayer, before it is added to the sub-layer input and normalized
# To faciliate these residual connections, all sublayers in the model, as well as the embedding layers, produce outputs of dimension d_model=512
class SublayerConnection(nn.Module):
    """
    A residual connection followed by a layer norm.
    Note for code simplicity the norm is first as opposed to last.
    """

    def __init__(self, size, dropout):
        super().__init__()
        self.norm= LayerNorm(size)
        self.dropout= nn.Dropout(dropout)

    def forward(self, x, sublayer):
        "Apply residual connection to any sublayer with the same size."
        return x + self.dropout(sublayer(self.norm(x)))

# Each layer has two sublayers.
# The first is a multi-head self-attention mechanism,
# and the second is a simple, position-wise fully connected feed-forward network.
class EncoderLayer(nn.Module):
    "Encoder is made up of self-attn and feed forward."

    def __init__(self, size, self_attn, feed_forward, dropout):
        super().__init__()
        self.self_attn= self_attn
        self.feed_forward= feed_forward
        self.sublayer= clones(SublayerConnection(size, dropout), 2)
        self.size= size

    def forward(self, x, mask):
        x= self.sublayer[0](x, lambda x: self.self_attn(x, x, x, mask))
        return self.sublayer[1](x, self.feed_forward)

# Decoder
# The decoder is also composed of a stack of N=6 identical layers.
class Decoder(nn.Module):
    "Generic N layer decoder with masking."
    
    def __init__(self, layer, N):
        super().__init__()
        self.layers= clones(layer, N)
        self.norm= LayerNorm(layer.size)

    def forward(self, x, memory, src_mask, tgt_mask):
        for layer in self.layers:
            x= layer(x, memory, src_mask, tgt_mask)
        return self.norm(x)

# In addition to the two sublayers in each encoder layer,
# the decoder insers a third sublayer, which performs multi-head attenyion over the output of the encoder stack.
class DecoderLayer(nn.Module):
    "Decoder is made of self-attn, src-attn, and feed forward"

    def __init__(self, size, self_attn, src_attn, feed_forward, dropout):
        super().__init__()
        self.size= size
        self.self_attn= self_attn
        self.src_attn= src_attn
        self.feed_forward= feed_forward
        self.sublayer= clones(SublayerConnection(size, dropout), 3)

    def forward(self, x, memory, src_mask, tgt_mask):
        m= memory
        x= self.sublayer[0](x, lambda x: self.self_attn(x, x, x, tgt_mask))
        x= self.sublayer[1](x, lambda x: self.src_attn(x, m, m, src_mask))
        return self.sublayer[2](x, self.feed_forward)

# Modify the self-attn in the decoder stack to prevent positions from attending to subsequent positions.
# This masking, combined with fact that the output embeddings are offset by one position,
# ensures that the predictions for position i can depend only on the known outputs at positions less than i.
def subsequent_mask(size):
    "Mask out subsequent positions."
    attn_shape= (1, size, size)
    subsequent_mask= torch.triu(torch.ones(attn_shape, dtype=torch.bool), diagonal= 1)
    return ~subsequent_mask

# Below the attention mask shows the position each tgt word (row) is allowed to look at (column).
# Words are blocked for attending to future words during training.
def example_mask():
    LS_data= pd.concat(
        [
            pd.DataFrame(
                [
                    {
                        'Subsequent Mask': subsequent_mask(20)[0][x, y].item(),
                        'Masking': x
                    }
                    for y in range(20)
                    for x in range(20)
                ]
            )
        ]
    )

    return(
        alt.Chart(LS_data)
        .mark_rect()
        .properties(height=250, width= 250)
        .encode(
            alt.X('Window:O'),
            alt.Y('Masking:O'),
            alt.Color('Subsequent Mask:Q', scale= alt.Scale(scheme='viridis'))
        )
        .interactive()
    )

# chart = example_mask()
# chart.save('/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001_mask_chart.html')

# Attention
# An attention function can be described as mapping a query and a set of key-value pairs to an output,
# where the query, keys, values, and output are all vectors.
# The output is computed as a weighted sum of the values, where the weight assigned to each value is computed by a compatibility function of the query with the corresponding key.

# We called our particular attention "Scaled Dot-Product Attention".
# The input consists of queries and keys of dimension dk, and values of dimension dv.
# We compute the dot products of the query with all keys, divide each by sqrt(dk), and apply a softmax function to obtain the weights on the values.

# In practice, we compute the attention function on a set of queries simultaneously,
# packed together into a matrix Q of dimension (n_q, dk).
# The keys K and values V are also packed together into matrices of dimension (n_k, dk) and (n_v, dv) respectively.
# We compute the matrix of outputs as:
# Attention(Q, K, V) = softmax(QK^T / sqrt(dk))V

def attention(query, key, value, mask=None, dropout=None):
    "Compute 'Scaled Dot Product Attention'"
    d_k= query.size(-1) # size of the last dimension
    scores= torch.matmul(query, key.transpose(-2, -1)) / math.sqrt(d_k) # scaled dot-product attention
    if mask is not None:
        scores= scores.masked_fill(mask == 0, -1e9) # fill the masked positions with a large negative number
    p_attn= torch.softmax(scores, dim=-1) # apply softmax to get attention weights
    if dropout is not None:
        p_attn= dropout(p_attn)
    return torch.matmul(p_attn, value), p_attn

# Employ h=8 parallel attention layers, or heads.
# For each of these we use dk=dv=dmodel/h=64.
# Due to the reduced dimension of each head, the total computational cost is similar to that of single-head attention with full dimensionality.
class MultiHeaderAttention(nn.Module):
    def __init__(self, h, d_model, dropout=0.1):
        "Take in model size and number of heads."
        super().__init__()
        assert d_model % h == 0
        # Assume d_v always equals d_k
        self.d_k= d_model // h
        self.h= h
        self.linears= clones(nn.Linear(d_model, d_model), 4)
        self.attn= None
        self.dropout= nn.Dropout(p=dropout)

    def forward(self, query, key, value, mask=None):
        if mask is not None:
            # Same mask applied to all h heads.
            mask= mask.unsqueeze(1)
        nbatches= query.size(0)

        # 1) Do all the linear projections in batch from d_model => h x d_k
        query, key, value= [
            lin(x).view(nbatches, -1, self.h, self.d_k).transpose(1,2)
            for lin, x in zip(self.linears, (query, key, value))
        ]

        # 2) Apply attention on all the prokjected vectors in batch.
        x, self.attn= attention(
            query, key, value, mask= mask, dropout= self.dropout
        )

        # 3) Concat using a view and apply a final linear.
        x= (
            x.transpose(1,2)
            .contiguous()
            .view(nbatches, -1, self.h * self.d_k)
        )
        del query
        del key
        del value
        return self.linears[-1](x)

# Applications of Attention
# The Transformer uses multi-head attention in three different ways:
# 1) In "encoder-decoder attention" layers, the queries come from the previous decoder layer,
# and the meomory keys and values come from the output of the encoder.
# This allows every position in the decoder to attend over all positions in the input sequence.
# This mimics the typical encoder-decoder attention mechanisms in sequence-to-sequence models.
# 2) The encoder contains self-attention layers.
# In a self-attention layer all of keys, values and queries come from the same place.
# Each position in the encoder can attend to all positions in the previous layer of the encoder.
# 3) Similarly, self-attention layers in the decoder allow each position in the decoder to attend to all positions in the decoder up to and including that position.
# We need to prevent leftward information flow in the decoder to preserve the auto-regression property.
# We implement this inside of scaled dot-product attention by masking out all values in the input of the softmax which correspond to illegal connections.

# Position-wise Feed-Forward Networks
# In addition to attention sublayers, each of the layers in our encoder and decoder contains a fully connected feed-forward network,
# which is applied to each position separately and identically.
# This consists of two linear transofrmations with a ReLU activation in bettween.
# FFN(x)= max(0, xW1+b1)W2+b2
# While the linear transformations are the same across different positions, they use diffetent parameters from layer to layer.
# Another way of describing this is as two convolutions with kernel size 1.
# The dimensionality of input and output is d_model=512, and the inner-layer has dimensionalitu d_ff=2048.
class PositionWiseFeedForward(nn.Module):
    "Implement FFM equation."

    def __init__(self, d_model, d_ff, dropout=0.1):
        super().__init__()
        self.w_1= nn.Linear(d_model, d_ff)
        self.w_2= nn.Linear(d_ff, d_model)
        self.dropout= nn.Dropout(p=dropout)

    def forward(self, x):
        return  self.w_2(self.dropout(self.w_1(x).relu()))

# Embeddings and softmax
# Similarly to other sequence transduction models, we use learned embedings to convert the input tokens and output tokens to vectors of dimenstion d_model.
# We also use the usual learned liner transformation and softmax function to convert the decoder output to predicted next=token probabilities.
# We share the same weight matrix between the two embedding layers and the pre-softmax linear transformation.
class Embeddings(nn.Module):
    def __init__(self, d_model, vocab):
        super().__init__()
        self.lut= nn.Embedding(vocab, d_model)
        self.d_model= d_model

    def forward(self, x):
        return self.lut(x) * math.sqrt(self.d_model)
    
# Positional Encoding
# Since out model contains no recurrence and no convolution, in order for the model to make use of the order of the sequence,
# we must inject some information about the relative or absolute position of the tokens in the sequence.
# To this end, we add positional encodings to the input embeddings at the bottoms of the encoder and decoder stacks.
# The positional encodings have the same dimension d_model as the embeddings, so that the two can be summed.
# We use sine and cosine functions of different frequencies:
# PE(pos, 2i)=sin(pos/1000^(2i/d_model))
# PE(pos, 2i+1)=cos(pos/1000^(2i/d_model))
# where pos is the position and i is the dimension.
# That is, each dimension of the positional encoding corresponds to a sinusoid.
# The wavelengths from a geometric progression from 2pi to 1000*2pi.
# We chose this function because we hypothesized it would allow the model to easily learn to attend by relative positions,
# since for any fixed offset k, PE_pos+k can be represented as a linear function of PE_pos.
class PositionalEncoding(nn.Module):
    "Implement the PE function."

    def __init__(self, d_model, dropout, max_len=5000):
        super().__init__()
        self.dropout= nn.Dropout(p=dropout)

        # Compute the positional endcodings once in log sapce.
        pe= torch.zeros(max_len, d_model)
        position= torch.arange(0, max_len).unsqueeze(1)
        div_term= torch.exp(
            torch.arange(0, d_model, 2) * -(math.log(1000.0)/d_model)
        )
        pe[:,0::2]= torch.sin(position * div_term)
        pe[:,1::2]= torch.cos(position * div_term)
        pe= pe.unsqueeze(0)
        self.register_buffer('pe', pe)

    def forward(self, x):
        x= x+ self.pe[:,:x.size(1)].requires_grad_(False)
        return self.dropout(x)

# Below the positional encoding will add in a sine wave based on position.
# The frequency and offset if the wave is different for each dimension.
def exmaple_positional():
    pe= PositionalEncoding(20,0)
    y= pe.forward(torch.zeros(1,100,20))
    
    data= pd.concat(
        [
            pd.DataFrame(
                {
                    'embedding': y[0, :, dim].tolist(),
                    'dimension': dim,
                    'position': list(range(100))
                }
                for dim in [4,5,6,7]
            )
        ]
    )

    return(
        alt.Chart(data)
        .mark_line()
        .properties(width=800)
        .encode(x='position', y='embedding', color='dimension:N')
        .interactive()
    )

# chart = exmaple_positional()
# chart.save('/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001_exmaple_positional_encoding.html')

# Full model
def make_model(
    src_vocab, tgt_vocab, N=6, d_model=512, d_ff=2048, h=8, dropout=0.1
):
    "Helper: Construct a model from hyperparameters."
    c= copy.deepcopy
    attn= MultiHeaderAttention(h, d_model)
    ff= PositionWiseFeedForward(d_model, d_ff, dropout)
    position= PositionalEncoding(d_model, dropout)
    model= EncoderDecoder(
        Encoder(EncoderLayer(d_model, c(attn), c(ff), dropout), N),
        Decoder(DecoderLayer(d_model, c(attn), c(attn), c(ff), dropout), N),
        nn.Sequential(Embeddings(d_model, src_vocab), c(position)),
        nn.Sequential(Embeddings(d_model, tgt_vocab), c(position)),
        Generator(d_model, tgt_vocab)
    )

    # Initiailize parameters with Glorot / fan_avg.
    for p in model.parameters():
        if p.dim() > 1:
            nn.init.xavier_uniform_(p)
    
    return model

# Inference:
# Here we make a forward step to generate a prediction of the model.
# We try to use our transformer to memorize the input.
def inference_test():
    test_model= make_model(11, 11, 2) # [0, vocab_size-1]
    test_model.eval()
    src= torch.LongTensor([[1,2,3,4,5,6,7,8,9,10]]) # batch_size=1, seq_len=10
    src_mask= torch.ones(1,1,10) # (batch_size, 1, seq_len)

    memory= test_model.encode(src, src_mask)
    ys= torch.zeros(1,1).type_as(src)
    for i in range(9):
        # subsequent_mask ensures that the predictions for position i can depend only on the known outputs at positions less than i.
        out= test_model.decode(
            memory, src_mask, ys, subsequent_mask(ys.size(1)).type_as(src.data)
        ) # (batch_size, tgt_seq_len, d_model)
        prob= test_model.generator(out[:,-1]) # out[:,-1] shape: (batch_size, d_model); prob shape: (batch_size, vocab)
        _, next_word= torch.max(prob, dim=1)
        next_word= next_word[0].item()
        ys= torch.cat(
            [ys, torch.empty(1,1).type_as(src.data).fill_(next_word)], dim=1
        )

    print(f'Example Untrained Model Prediction: {ys}')

def run_tests():
    for _ in range(10):
        inference_test()

# run_tests()

# Part 2: Model Training
# First we define a batch object that holds the src and target sentences for training, as well as constructing the masks.
# Batches and masking
class Batch:
    """
    Object for holding a batch of data with mask during training.
    """
    
    def __init__(self, src, tgt=None, pad=2):
        """
        : pad: padding token, default=2, 0 and 1 are reserved for <bos> and <eos>
        """
        self.src= src # shape of (batch_size, src_seq_len)
        self.src_mask= (src != pad).unsqueeze(-2) # masking paddings, resulting in shape of (batch_size, 1, src_seq_len)
        if tgt is not None:
            self.tgt= tgt[:, :-1] # teacher forcing
            self.tgt_y= tgt[:, 1:]
            # self.tgt could correspond to tgt_y, like:
            # input:  [<bos>, w1, w2, w3, w4]
            # output: [w1, w2, w3, w4, <eos>]
            self.tgt_mask= self.make_std_mask(self.tgt, pad)
            self.ntokens= (self.tgt_y != pad).sum()
        
    @staticmethod
    # This function is static because it does not depend on the instance of the class.
    def make_std_mask(tgt, pad):
        "Create a mask to hide padding and future words."
        tgt_mask= (tgt != pad).unsqueeze(-2) # (batch_size, 1, tgt_seq_len)
        tgt_mask= tgt_mask & subsequent_mask(tgt.size(-1)).type_as(tgt_mask.data) # applying subsequent mask
        return tgt_mask

# Now we create a generic training and scoring function to keep track of loss.
# We pass in a generic loss compute function that also handles parameter updates.
# Training loop
class TrainState:
    """Track number of steps, examples, and tokens processed."""
    step: int = 0 # Steps in the current epoch
    accum_steps: int = 0 # Number of gradient accumulation steps
    samples: int = 0 # Number of samples processed
    tokens: int = 0 # Number of tokens processed

def run_epoch(
    data_iterator, model, loss_compute, 
    optimizer, scheduler, mode= 'train',
    accum_iter=1, train_state= TrainState()
):
    """Train a single epoch"""
    start= time.time()
    total_tokens= 0
    total_loss= 0
    tokens= 0
    n_accum= 0
    for i, batch in enumerate(data_iterator):
        # batch.src: (batch_size, src_seq_len)
        # batch.tgt: (batch_size, tgt_seq_len-1)
        # batch.tgt_y: (batch_size, tgt_seq_len-1)
        # batch.src_mask: (batch_size, 1, src_seq_len)
        # batch.tgt_mask: (batch_size, 1, tgt_seq_len-1)
        src= batch.src
        tgt= batch.tgt
        src_mask= batch.src_mask
        tgt_mask= batch.tgt_mask
        tgt_y= batch.tgt_y
        ntokens= batch.ntokens

        out= model.forward(src, tgt, src_mask, tgt_mask) # out shape: (batch_size, tgt_seq_len-1, d_model)
        loss, loss_node= loss_compute(out, tgt_y, ntokens)

        if mode == 'train' or mode == 'train+log':
            loss_node.backward()
            train_state.step += 1
            train_state.samples += src.shape[0]
            train_state.tokens += ntokens

            if i % accum_iter == 0:
                optimizer.step()
                optimizer.zero_grad(set_to_none=True)
                n_accum += 1
                train_state.accum_steps += 1
            
            scheduler.step() # changing lr
        
        total_loss += loss
        total_tokens += ntokens
        tokens += ntokens

        if i % 40 == 1 and (mode == 'train' or mode == 'train+log'):
            lr= optimizer.param_groups[0]['lr']
            elapsed= time.time() -start
            print(
                (
                    'Epoch Step: %6d | Accumulation Step: %3d | Loss: %6.2f '
                    + '| Tokens / Sec: %7.1f | Learning Rate: %6.1e'
                )
                % (i, n_accum, loss / ntokens, tokens / elapsed, lr)
            )
            start= time.time()
            tokens= 0
        
        del loss
        del loss_node
        
    return total_loss / total_tokens, train_state

# Training data and batching
# We trained on the standard WMT 2014 English-German dataset consisting of about 4.5 million sentence pairs.
# Sentences were encoded using byte-pair encoding, which has a shared source-target vocabulary of about 37000 tokens.
# For English-French, we used the significantly larger WMT 2014 English-French dataset consisting of about 36 million sentences and split tokens into a 32000 word-piece vocabulary.
# Sentence pairs were batched together by approximate sequence length.
# Each training batch contained a set of sentence pairs containing approximately 25000 source tokens and 25000 target tokens.

# Optimizer
# We used the Adam optimizer with beta1=0.9, beta2=0.98 and eps=1e-9.
# We varied the learning rate over the course of training, according to the formula:
# lrate= d_model^-0.5 * min(step_num^-0.5, step_num * warmup_steps^-1.5)
# This corresponds to a linear increase in the learning rate for the first warmup_steps training steps,
# followed by a decay proportional to the inverse square root of the step number.
# We set warmup_steps=4000.
def rate(step, model_size, factor, warmup):
    """
    We have to default the step to 1 for LambdaLR function to avoid zero rasing to negative power.
    """
    if step == 0:
        step = 1
    return factor * (model_size ** -0.5) * min(step ** -0.5, step * warmup ** -1.5)

def example_learning_schedule():
    opts= [
        [512, 1, 4000],
        [512, 1, 8000],
        [256, 1, 4000]
    ]

    dummy_model= torch.nn.Linear(1, 1)
    learning_rates= []

    # We have 3 example learning rates to plot.
    for idx, example in enumerate(opts):
        # run 20000 epoch for each example
        optimizer= torch.optim.Adam(
            dummy_model.parameters(), lr= 1, betas=(0.9, 0.98), eps=1e-9
        )
        lr_scheduler= LambdaLR(
            optimizer= optimizer,
            lr_lambda= lambda step: rate(step, *example)
        )
        tmp= []
        # take 20K dummy training steps, save the learning rate at each step
        for step in range(20000):
            tmp.append(optimizer.param_groups[0]['lr'])
            optimizer.step()
            lr_scheduler.step()
        learning_rates.append(tmp)
    
    learning_rates= torch.tensor(learning_rates)
    # plot the learning rates
    # Enable altair to handle more than 5000 rows
    alt.data_transformers.disable_max_rows()

    opts_data= pd.concat(
        [
            pd.DataFrame(
                {
                    'step': list(range(20000)),
                    'learning_rate': learning_rates[idx].tolist(),
                    'model_size:warmup': ['512:4000','512:8000','256:4000'][idx]
                }
            )
            for idx in range(len(opts))
        ]
    )

    return(
        alt.Chart(opts_data)
        .mark_line()
        .properties(width=800)
        .encode(
            x='step',
            y='learning_rate',
            color='model_size\\:warmup:N'
        )
        .interactive()
    )

# chart= example_learning_schedule()
# chart.save('/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001_example_learning_schedule.html')

# Regularization
# During training, we employed label smoothing of value 0.1.
# This hurts perplexity, as the model learns to be more unsure, but improves accuracy and BLEU score.
# We implement label smoothing using the Kullback-Leibler divergence between the predicted distribution and the smoothed distribution.
# Instead of using a one-hot target distribution, we create a distribution that has confidence of the correct word and the rest of the smoothing mass distributed throughout the vocabulary.
class LabelSmoothing(nn.Module):
    """
    Implement label smoothing.
    """

    def __init__(self, size, padding_idx, smoothing=0.0):
        super().__init__()
        self.criterion= nn.KLDivLoss(reduction='sum')
        self.padding_idx= padding_idx
        self.confidence= 1.0 - smoothing
        self.smoothing= smoothing
        self.size= size
        self.true_dist= None

    def forward(self, x, target):
        assert x.size(1) == self.size # vocab_size
        true_dist= x.data.clone() # clone the data to avoid in-place operation
        true_dist.fill_(self.smoothing / (self.size - 2))
        true_dist.scatter_(1, target.data.unsqueeze(1), self.confidence)
        true_dist[:, self.padding_idx]= 0 # ignore the category of padding_idx
        mask= torch.nonzero(target == self.padding_idx)
        if mask.dim() > 0:
            true_dist.index_fill_(0, mask.squeeze(), 0.0)
        self.true_dist= true_dist
        return self.criterion(x, true_dist.clone().detach())

def example_label_smoothing():
    crit= LabelSmoothing(5, 0, 0.1)
    predict= torch.tensor(
        [
            [0, 0.2, 0.7, 0.1, 0],
            [0, 0.2, 0.7, 0.1, 0],
            [0, 0.2, 0.7, 0.1, 0],
            [0, 0.2, 0.7, 0.1, 0],
            [0, 0.2, 0.7, 0.1, 0],
        ]
    )
    crit(x=predict.log(), target=torch.tensor([2, 1, 0, 3, 3]))
    LS_data = pd.concat(
        [
            pd.DataFrame(
                {
                    "target distribution": crit.true_dist[x, y].flatten().tolist(),
                    "columns": y,
                    "rows": x,
                }
            )
            for y in range(5)
            for x in range(5)
        ]
    )

    return (
        alt.Chart(LS_data)
        .mark_rect(color="Blue", opacity=1)
        .properties(height=200, width=200)
        .encode(
            alt.X("columns:O", title=None),
            alt.Y("rows:O", title=None),
            alt.Color(
                "target distribution:Q", scale=alt.Scale(scheme="viridis")
            ),
        )
        .interactive()
    )

# chart= example_label_smoothing()
# chart.save('/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001_example_label_smoothing.html')

# Label smoothing actually starts to penalize the model if it gets very confident about a given choice.
def loss(x, crit):
    d= x + 3*1
    eps= 1e-9
    predict= torch.tensor([[eps, x/d, 1/d, 1/d, 1/d]])
    predict= predict / predict.sum()
    return crit(predict.log(), target= torch.tensor([1])).data

crit= LabelSmoothing(5, 0, 0.1)
loss_data= pd.DataFrame(
    {
        'loss': [loss(x, crit) for x in range(1, 100)],
        'steps': list(range(1, 100))
    }
)
# loss_data
def penalization_visualization():
    crit = LabelSmoothing(5, 0, 0.1)
    loss_data = pd.DataFrame(
        {
            "Loss": [loss(x, crit) for x in range(1, 100)],
            "Steps": list(range(99)),
        }
    ).astype("float")

    return (
        alt.Chart(loss_data)
        .mark_line()
        .properties(width=350)
        .encode(
            x="Steps",
            y="Loss",
        )
        .interactive()
    )
# chart= penalization_visualization()
# chart.save('/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001_penalization_visualization.html')

# A first example
# We can begin by trying out a simple copy-task.
# Given a random set of input symbols from a small vocabulary, the goal is to generate back those same symbols.
# Synthetic data
def data_gen(V, batch_size, nbatches):
    """
    Generate random data in batches for a src-tgt copy task.
    : V: vocabulary size
    : batch_size: number of samples in a batch
    : nbatches: number of batches
    """
    for i in range(nbatches):
        data= torch.randint(1, V, (batch_size, 10)) # shape: (batch_size, seq_len)
        data[:, 0]= 1
        src= data.requires_grad_(False).clone().detach()
        tgt= data.requires_grad_(False).clone().detach()
        yield Batch(src, tgt, 0) # src and tgt are the same in this case

# loss computation
class SimpleLossCompute:
    """
    A simple loss compute and train function.
    """

    def __init__(self, generator, criterion):
        self.generator= generator
        self.criterion= criterion
        
    def __call__(self, x, target, norm):
        x= self.generator(x)
        sloss= (
            self.criterion(x.contiguous().view(-1, x.size(-1)), target.contiguous().view(-1)) / norm
        )
        return sloss.data * norm, sloss
    
# Greedy decoding
# This code predicts a translation using greedy decoding for simplicity.
def greedy_decode(model, src, src_mask, max_len, start_symbol):
    """
    Take a src and produce a target of max_len.
    : model: the transformer model
    : src: the source sequence
    : src_mask: the source mask
    : max_len: the maximum length of the target sequence
    : start_symbol: the start symbol for the target sequence
    """
    memory= model.encode(src, src_mask)
    ys= torch.ones(1, 1).fill_(start_symbol).type_as(src.data) # (1, 1)
    
    for i in range(max_len-1):
        tgt_mask= subsequent_mask(ys.size(1)).type_as(src.data) # (1, 1, tgt_seq_len)
        out= model.decode(memory, src_mask, ys, tgt_mask) # (1, tgt_seq_len, d_model)
        prob= model.generator(out[:, -1]) # (1, vocab_size)
        _, next_word= torch.max(prob, dim=1) # (1,)
        next_word= next_word[0].item()
        ys= torch.cat([ys, torch.zeros(1,1).type_as(src.data).fill_(next_word)], dim=1) # (1, tgt_seq_len)

    return ys

# Train the simple copy task
def example_simple_model():
    V= 11
    criterion= LabelSmoothing(size=V, padding_idx=0, smoothing=0.0)
    model= make_model(V, V, N=2)
    
    optimizer= torch.optim.Adam(
        model.parameters(), lr= 0.5, betas=(0.9, 0.98), eps=1e-9
    )
    lr_scheduler= LambdaLR(
        optimizer= optimizer,
        lr_lambda= lambda step: rate(
            step, model_size=model.src_embed[0].d_model,
            factor=1, warmup=400
        )
    )
    
    batch_size= 80
    for epoch in range(20):
        model.train()
        run_epoch(
            data_gen(V, batch_size, 1000), model,
            SimpleLossCompute(model.generator, criterion),
            optimizer, lr_scheduler, mode= 'train'
        )
        model.eval()
        run_epoch(
            data_gen(V, batch_size, 5), model,
            SimpleLossCompute(model.generator, criterion),
            DummyOptimizer, DummyScheduler, mode= 'eval'
        )[0]
    
    model.eval()
    src= torch.tensor([[0,1,2,3,4,5,6,7,8,9]])
    max_len= src.shape[1]
    src_mask= torch.ones(1,1,max_len)
    print(greedy_decode(model, src, src_mask, max_len, 0))

# example_simple_model()

# Part 3: a real world example
# Use the Multi30k German-English dataset for training and evaluation.
# We also show how to use multi-gpu processing to make it really fast.
# Data loading
# We will load the dataset using torchtext and spacy for tokenization.
# Load spacy tokenizer models, download them if they haven't been downloaded yet.
def load_tokenizers():
    try:
        spacy_de= spacy.load('de_core_news_sm')
    except IOError:
        os.system('python3.11 -m spacy download de_core_news_sm')
        spacy_de= spacy.load('de_core_news_sm')

    try:
        spacy_en= spacy.load('en_core_web_sm')
    except IOError:
        os.system('python3.11 -m spacy download en_core_web_sm')
        spacy_en= spacy.load('en_core_web_sm')

    return spacy_de, spacy_en

# load_tokenizers()

def tokenize(text, tokenizer):
    """
    Tokenize the text using the specified tokenizer.
    : text: the text to tokenize
    : tokenizer: the tokenizer to use
    """
    tok= [tok.text for tok in tokenizer(text)]
    return tok

# example_en= "This is an example text."
# spacy_en= spacy.load('en_core_web_sm')
# tokens= tokenize(example_en, spacy_en)
# print(tokens)

def yield_tokens(data_iter, tokenizer, index):
    for from_to_tuple in data_iter:
        yield tokenizer(from_to_tuple[index])

# data_iter = [
#     ("This is a source sentence.", "Dies ist ein Satz."),
#     ("Another source sentence.", "Ein weiterer Satz.")
# ]
# def simple_tokenizer(text):
#     return tokenize(text, spacy_en)
# tokens = yield_tokens(data_iter, simple_tokenizer, index=0)
# tokens = list(tokens)
# print(tokens)

def build_vocabulary(spacy_de, spacy_en):
    def tokenize_de(text):
        return tokenize(text, spacy_de)

    def tokenize_en(text):
        return tokenize(text, spacy_en)

    print("Building German Vocabulary ...")
    train, val, test = Multi30k(language_pair=("de", "en"), root= './', split= ("train", "valid", "test"))
    vocab_src = build_vocab_from_iterator(
        yield_tokens(train + val + test, tokenize_de, index=0),
        min_freq=2,
        specials=["<s>", "</s>", "<blank>", "<unk>"],
    )

    print('Building English Vocabulary ...')
    train, val, test = Multi30k(language_pair=("de", "en"), root= './', split= ("train", "valid", "test"))
    vocab_tgt = build_vocab_from_iterator(
        yield_tokens(train + val + test, tokenize_en, index=1),
        min_freq=2,
        specials=["<s>", "</s>", "<blank>", "<unk>"],
    )

    vocab_src.set_default_index(vocab_src["<unk>"])
    vocab_tgt.set_default_index(vocab_tgt["<unk>"])

    return vocab_src, vocab_tgt

def load_vocab(spacy_de, spacy_en):
    if not exists('/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001/vocab.pt'):
        vocab_src, vocab_tgt = build_vocabulary(spacy_de, spacy_en)
        torch.save((vocab_src, vocab_tgt), '/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001/vocab.pt')
    else:
        vocab_src, vocab_tgt = torch.load('/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001/vocab.pt')
    print('Finished.\nVocabulary sizes:')
    print(len(vocab_src), len(vocab_tgt))
    return vocab_src, vocab_tgt

spacy_de, spacy_en = load_tokenizers()
vocab_src, vocab_tgt = load_vocab(spacy_de, spacy_en)

# Batching matters a ton for speed.
# We want to have very evenly divided batches, with absolutely minimal padding.
# To do this we have to hack a bit around the default torchtext batching.
# This code patches their default batching to make sure we search over enough sentences to find tight batches.
# Iterators
def collate_batch(
    batch,
    src_pipeline,
    tgt_pipeline,
    src_vocab,
    tgt_vocab,
    device,
    max_padding= 128,
    pad_idx= 2
):
    bs_id= torch.tensor([0], device=device)
    eos_id= torch.tensor([1], device=device)
    src_list, tgt_list= [], []
    for (_src, _tgt) in batch:
        processed_src= torch.cat(
            [
                bs_id,
                torch.tensor(
                    src_vocab(src_pipeline(_src)),
                    dtype= torch.int64,
                    device=device
                ),
                eos_id
            ],
            0
        )
        processed_tgt= torch.cat(
            [
                bs_id,
                torch.tensor(
                    tgt_vocab(tgt_pipeline(_tgt)),
                    dtype= torch.int64,
                    device=device
                ),
                eos_id
            ],
            0
        )
        src_list.append(
            pad(
                processed_src,
                (
                    0,
                    max_padding - len(processed_src)
                ),
                value= pad_idx
            )
        )
        tgt_list.append(
            pad(
                processed_tgt,
                (
                    0,
                    max_padding - len(processed_tgt)
                ),
                value= pad_idx
            )
        )
    
    src= torch.stack(src_list, dim=0)
    tgt= torch.stack(tgt_list, dim=0)
    return (src, tgt)

def create_dataloaders(
    device,
    vocab_src,
    vocab_tgt,
    spacy_de,
    spacy_en,
    batch_size= 12000,
    max_padding= 128,
    is_distributed= True
):
    def tokenize_de(text):
        return tokenize(text, spacy_de)

    def tokenize_en(text):
        return tokenize(text, spacy_en)

    def collate_fn(batch):
        return collate_batch(
            batch,
            tokenize_de,
            tokenize_en,
            vocab_src,
            vocab_tgt,
            device,
            max_padding=max_padding,
            pad_idx=vocab_src.get_stoi()["<blank>"],
        )
    
    train_iter, val_iter, test_iter = Multi30k(language_pair=("de", "en"), root= './', split= ("train", "valid", "test"))
    train_iter_map= to_map_style_dataset(train_iter) # DistributedSampler needs a dataset len()
    train_sampler= (
        DistributedSampler(train_iter_map)
        if is_distributed
        else None
    )
    valid_iter_map= to_map_style_dataset(val_iter)
    valid_sampler= (
        DistributedSampler(valid_iter_map)
        if is_distributed
        else None
    )
    
    train_dataloader= DataLoader(
        train_iter_map,
        batch_size=batch_size,
        collate_fn=collate_fn,
        sampler=train_sampler,
        shuffle= (train_sampler is None)
    )
    valid_dataloader= DataLoader(
        valid_iter_map,
        batch_size=batch_size,
        collate_fn=collate_fn,
        sampler=valid_sampler,
        shuffle= (valid_sampler is None)
    )
    return train_dataloader, valid_dataloader

# Training the system
def train_worker(
    gpu,
    ngpus_per_node,
    vocab_src,
    vocab_tgt,
    spacy_de,
    spacy_en,
    config,
    is_distributed= True
):
    print(f'Train worker process using GPU: {gpu} for training', flush=True)
    torch.cuda.set_device(gpu)

    pad_idx= vocab_tgt["<blank>"]
    d_model= 512
    model= make_model(len(vocab_src), len(vocab_tgt), N=6)
    model.cuda(gpu)
    module= model

    is_main_process= True
    if is_distributed:
        dist.init_process_group(
            backend='nccl',
            init_method='env://',
            rank=gpu,
            world_size=ngpus_per_node
        )
        model= DDP(model, device_ids=[gpu])
        module= model.module
        is_main_process= gpu == 0
    
    criterion= LabelSmoothing(
        size=len(vocab_tgt),
        padding_idx=pad_idx,
        smoothing=0.1
    )
    criterion.cuda(gpu)

    train_dataloader, valid_dataloader= create_dataloaders(
        gpu,
        vocab_src,
        vocab_tgt,
        spacy_de,
        spacy_en,
        batch_size=config['batch_size'] // ngpus_per_node,
        max_padding=config['max_padding'],
        is_distributed=is_distributed
    )

    optimizer= torch.optim.Adam(
        model.parameters(),
        lr=config['base_lr'],
        betas=(0.9, 0.98),
        eps=1e-9
    )
    lr_scheduler= LambdaLR(
        optimizer= optimizer,
        lr_lambda= lambda step: rate(
            step, model_size=d_model,
            factor=1, warmup=config['warmup']
        )
    )
    train_state= TrainState()

    for epoch in range(config['num_epochs']):
        if is_distributed:
            train_dataloader.sampler.set_epoch(epoch)
            valid_dataloader.sampler.set_epoch(epoch)

        model.train()
        print(f'[GPU {gpu}] Epoch {epoch} Training ====', flush=True)
        _, train_state= run_epoch(
            (Batch(b[0], b[1], pad_idx) for b in train_dataloader),
            model,
            SimpleLossCompute(module.generator, criterion),
            optimizer,
            lr_scheduler,
            mode='train+log',
            accum_iter=config['accum_iter'],
            train_state=train_state
        )

        GPUtil.showUtilization()
        if is_main_process:
            file_path= '%s%.2d.pt' % (config['file_prefix'], epoch)
            torch.save(module.state_dict(), file_path)
        torch.cuda.empty_cache()

        print(f'[GPU {gpu}] Epoch {epoch} Validation ====', flush=True)
        model.eval()
        sloss= run_epoch(
            (Batch(b[0], b[1], pad_idx) for b in valid_dataloader),
            model,
            SimpleLossCompute(module.generator, criterion),
            DummyOptimizer,
            DummyScheduler,
            mode='eval'
        )[0]
        print(f'[GPU {gpu}] Epoch {epoch} Validation Loss: {sloss}', flush=True)
        torch.cuda.empty_cache()

    if is_main_process:
        file_path= '%sfinal.pt' % (config['file_prefix'])
        print(f'Training finished.\nModel saved to {file_path}.pt.', flush=True)
        torch.save(
            module.state_dict(),
            file_path
        )

def train_distribued_model(
    vocab_src,
    vocab_tgt,
    spacy_de,
    spacy_en,
    config,
):

    ngpus= torch.cuda.device_count()
    print(f'Number of GPUs detected: {ngpus}', flush=True)

    os.environ['MASTER_ADDR']= 'localhost'
    os.environ['MASTER_PORT']= '12356'
    print('Spawning processes for distributed training', flush=True)
    mp.spawn(
        train_worker,
        args=(
            ngpus,
            vocab_src,
            vocab_tgt,
            spacy_de,
            spacy_en,
            config,
            True
        ),
        nprocs=ngpus,
    )

def train_model(
    vocab_src,
    vocab_tgt,
    spacy_de,
    spacy_en,
    config
):
    if config['distributed']:
        train_distribued_model(
            vocab_src,
            vocab_tgt,
            spacy_de,
            spacy_en,
            config
        )
    else:
        train_worker(
            0,
            1,
            vocab_src,
            vocab_tgt,
            spacy_de,
            spacy_en,
            config,
            False
        )

def load_trained_model():
    config= {
        'file_prefix': '/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001/multi30k_model_',
        'num_epochs': 10,
        'batch_size': 32,
        'max_padding': 72,
        'base_lr': 0.5,
        'warmup': 4000,
        'accum_iter': 10,
        'distributed': True
    } 
    model_path= '/share/home/lsy_luzhen/self-training/Python/pgm/deepLearning/output/p001/multi30k_model_final.pt'
    if not exists(model_path):
        train_model(
            vocab_src,
            vocab_tgt,
            spacy_de,
            spacy_en,
            config
        )

    model= make_model(
        len(vocab_src),
        len(vocab_tgt),
        N=6
    )
    model.load_state_dict(torch.load(model_path))
    return model


if __name__ == '__main__':
    load_trained_model()

