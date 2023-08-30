
[<img src="../../../../pictures/quantletLogo_FH.png" alt="Intro to Statistics with Python">](https://github.com/thomas-haslwanter/statsintro_python)

## [<img src="../../../../pictures/qloqo.png" alt="Visit QuantNet">](http://quantlet.de/)  **ISP_anovaTwoway** [<img src="../../../../pictures/QN2.png" width="60" alt="Visit QuantNet 2.0">](http://quantlet.de/)


```yaml
Name of QuantLet: ISP_anovaTwoway

Published in:  An Introduction to Statistics with Python

Description: 'Two-way Analysis of Variance (ANOVA)
    The model is formulated using the <patsy> formula description. This is very
    similar to the way models are expressed in R.'

Keywords: plot, fitting, two-way anova

See also: 'ISP_anovaOneway, ISP_kruskalWallis,
    ISP_multipleTesting, ISP_oneGroup, ISP_twoGroups' 

Author: Thomas Haslwanter 

Submitted: October 31, 2015 

Datafile: altman_12_6.txt 

```

```py
''' Two-way Analysis of Variance (ANOVA)
The model is formulated using the "patsy" formula description. This is very
similar to the way models are expressed in R.
'''

# author: Thomas Haslwanter, date: Oct-2015

# Import standard packages
import numpy as np
import pandas as pd

# additional packages
from statsmodels.formula.api import ols
from statsmodels.stats.anova import anova_lm

def anova_interaction():
    '''ANOVA with interaction: Measurement of fetal head circumference,
    by four observers in three fetuses, from a study investigating the
    reproducibility of ultrasonic fetal head circumference data.
    '''
    
    # Get the data
    inFile = 'altman_12_6.txt'
    data = np.genfromtxt(inFile, delimiter=',')
    
    # Bring them in DataFrame-format
    df = pd.DataFrame(data, columns=['hs', 'fetus', 'observer'])
    
    # --- >>> START stats <<< ---
    # Determine the ANOVA with interaction
    formula = 'hs ~ C(fetus) + C(observer) + C(fetus):C(observer)'
    lm = ols(formula, df).fit()
    anovaResults = anova_lm(lm)
    # --- >>> STOP stats <<< ---
    print(anovaResults)

    return  anovaResults['F'][0]
                              
if __name__ == '__main__':
    anova_interaction()
```
