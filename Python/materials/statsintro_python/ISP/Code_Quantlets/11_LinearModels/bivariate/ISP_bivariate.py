""" Analysis of multivariate data
- Regression line
- Correlation (Pearson-rho, Spearman-rho, and Kendall-tau)
"""

# author: Thomas Haslwanter, date: 2021-01-11

# Import standard packages
import numpy as np
from scipy import stats
import pandas as pd
import statsmodels.formula.api as smf


def regression_line() -> float:
    """Fit a line, using the powerful "ordinary least square" method of pandas.
    
    Data from 24 type 1 diabetic patients, relating fasting blood
    glucose (mmol/l) to mean circumferential shortening velocity (%/sec),
    derived form echocardiography.

    Returns
    -------
    f : test statistic
    """
    
    # Get the data
    inFile = 'altman_11_6.txt'
    data = np.genfromtxt(inFile, delimiter=',')
    
    # Convert them into a pandas DataFrame
    df = pd.DataFrame(data, columns=['glucose', 'Vcf'])

    # --- >>> START stats <<< ---
    # Fit a regression line to the data, and display the model results
    results = smf.ols('Vcf ~ glucose', data=df).fit()
    # model = pd.ols(y=df['Vcf'], x=df['glucose'])
    print(results.summary())
    # --- >>> STOP stats <<< ---
    
    return results.fvalue   # should be 4.414018433146266
    

def correlation() -> float:
    """Pearson correlation, and two types of rank correlation (Spearman,
    Kendall) comparing age and %fat (measured by dual-photon absorptiometry)
    for 18 normal adults.

    Returns
    -------
    corr : Pearson's correlation coefficient

    """
    
    # Get the data
    inFile = 'altman_11_1.txt'
    data = np.genfromtxt(inFile, delimiter=',')
    x = data[:,0]
    y = data[:,1]
    
    # --- >>> START stats <<< ---
    # Calculate correlations
    # Resulting correlation values are stored in a dictionary, so that it is
    # obvious which value belongs to which correlation coefficient.
    corr = {}
    corr['pearson'], _ = stats.pearsonr(x,y)
    corr['spearman'], _ = stats.spearmanr(x,y)
    corr['kendall'], _ = stats.kendalltau(x,y)
    # --- >>> STOP stats <<< ---
    
    print(corr)    
    
    # Assert that Spearman's rho is just the correlation of the ranksorted data
    np.testing.assert_almost_equal(corr['spearman'],
            stats.pearsonr(stats.rankdata(x), stats.rankdata(y))[0])
    
    return corr['pearson']  # should be 0.79208623217849117
    

if __name__ == '__main__':
    regression_line()    
    correlation()
