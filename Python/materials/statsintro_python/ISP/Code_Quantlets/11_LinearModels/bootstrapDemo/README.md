
[<img src="../../../../pictures/quantletLogo_FH.png" alt="Intro to Statistics with Python">](https://github.com/thomas-haslwanter/statsintro_python)

## [<Img src="../../../../pictures/qloqo.png" alt="Visit QuantNet">](http://quantlet.de/) **ISP_bootstrapDemo** [<img src="../../../../pictures/QN2.png" width="60" alt="Visit QuantNet 2.0">](http://quantlet.de/)


```yaml
Name of QuantLet: ISP_bootstrapDemo

Published in:  An Introduction to Statistics with Python

Description: 'Example of bootstrapping the confidence interval for the mean of a sample distribution
    This function requires <bootstrap.py>, which is available from
    https://github.com/cgevans/scikits-bootstrap'

Keywords: bootstrap

See also: 'ISP_anscombe, ISP_bivariate, ISP_fitLine,
        ISP_modelImplementations, ISP_simpleModels'


Author: Thomas Haslwanter 

Submitted: October 31, 2015 

```

```py
''' Example of bootstrapping the confidence interval for the mean of a sample distribution
This function requires "bootstrap.py", which is available from
https://github.com/cgevans/scikits-bootstrap
'''

# author: Thomas Haslwanter, date: Sept-2015

# Import standard packages
import matplotlib.pyplot as plt
import scipy as sp
from scipy import stats

# additional packages
import scikits.bootstrap as bootstrap

def generate_data():
    ''' Generate the data for the bootstrap simulation '''
    
    # To get reproducable values, I provide a seed value
    sp.random.seed(987654321)   
    
    # Generate a non-normally distributed datasample
    data = stats.poisson.rvs(2, size=1000)
    
    # Show the data
    plt.plot(data, '.')
    plt.title('Non-normally distributed dataset: Press any key to continue')
    plt.waitforbuttonpress()
    plt.close()    
    
    return(data)
    
def calc_bootstrap(data):
    ''' Find the confidence interval for the mean of the given data set with bootstrapping. '''
    
    # --- >>> START stats <<< ---
    # Calculate the bootstrap
    CIs = bootstrap.ci(data=data, statfunction=sp.mean)
    # --- >>> STOP stats <<< ---
    
    # Print the data: the "*" turns the array "CIs" into a list
    print(('The conficence intervals for the mean are: {0} - {1}'.format(*CIs)))
    
    return CIs

if __name__ == '__main__':
    data = generate_data()
    calc_bootstrap(data)
    input('Done')
```
