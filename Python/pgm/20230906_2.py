""" Two-way Analysis of Variance (ANOVA)
The model is formulated using the "patsy" formula description. This is very
similar to the way models are expressed in R.
"""


# Import standard packages
import numpy as np
import pandas as pd

# additional packages
from statsmodels.formula.api import ols
from statsmodels.stats.anova import anova_lm


def anova_interaction() -> float:
    """ANOVA with interaction: Measurement of fetal head circumference,
    by four observers in three fetuses, from a study investigating the
    reproducibility of ultrasonic fetal head circumference data.

    Returns
    -------
    F : ANOVA test statistic
    """
    
    # Get the data

    inFile = 'C:/Library/Applications/Typora/data/self-training/Python/data/altman_12_6.txt'
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

# # three-way anova                              
# import matplotlib.pyplot as plt
# import seaborn as sns
# sns.set(style= 'whitegrid')
# df= sns.load_dataset('exercise')
# df
# sns.catplot(x= 'time', y= 'pulse', hue= 'kind', col= 'diet',
#             data= df, hue_order= ['rest', 'walking', 'running'],
#             kind= 'point',
#             palette= 'YlGnBu_d', aspect= .75)
# plt.show()


if __name__ == '__main__':
    anova_interaction()










