""" Practical demonstration of the central limit theorem
Based on the uniform distribution """

# author: Thomas Haslwanter, date: Feb-2021

# Import standard packages
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os

# additional packages
import sys
sys.path.append(os.path.join('..', '..', 'Utilities'))

try:
# Import formatting commands if directory "Utilities" is available
    from ISP_mystyle import setFonts, showData 
    
except ImportError:
# Ensure correct performance otherwise
    def setFonts(*options):
        return
    def showData(*options):
        plt.show()
        return

def showAsHistogram(axis, data, title) -> None:
    """Subroutine showing a histogram and formatting it"""
    
    axis.hist( data, bins=nbins)
    axis.set_xticks([0, 0.5, 1])
    axis.set_title(title)

    
if __name__ == '__main__':
    # Formatting options
    sns.set(context='poster', style='ticks', palette='muted')
    
    # Input data
    ndata = 100000
    nbins = 50

    setFonts(24)
    # Generate data
    data = np.random.random(ndata)
    
    # Show three histograms, side-by-side
    fig, axs = plt.subplots(1,3)
    
    showAsHistogram(axs[0], data, 'Random data')
    showAsHistogram(axs[1], np.mean(data.reshape((int(ndata/2), 2 )), axis=1),
                    'Average over 2')
    showAsHistogram(axs[2], np.mean(data.reshape((int(ndata/10),10)), axis=1),
                    'Average over 10')
    
    # Format them and show them
    axs[0].set_ylabel('Counts')
    plt.tight_layout()
    showData('CentralLimitTheorem.png')
