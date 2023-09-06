""" Analysis of Variance (ANOVA)
- Levene test
- ANOVA - oneway
- Do a simple one-way ANOVA, using statsmodels
- Show how the ANOVA can be done by hand.
- For the comparison of two groups, a one-way ANOVA is equivalent to
  a T-test: t^2 = F
"""

# author: Thomas Haslwanter, date: Feb-2021

# Import standard packages
import numpy as np
import scipy.stats as stats
import pandas as pd

# additional packages
from statsmodels.formula.api import ols
from statsmodels.stats.anova import anova_lm
from typing import Tuple


def anova_oneway() -> Tuple[float, float]:
    """ One-way ANOVA: test if results from 3 groups are equal.
    
    Twenty-two patients undergoing cardiac bypass surgery were randomized to
    one of three ventilation groups:
    
    Group I:  Patients received a 50% nitrous oxide and 50% oxygen mixture
              continuously for 24 h.
    Group II: Patients received a 50% nitrous oxide and 50% oxygen mixture
              only dirng the operation.
    Group III: Patients received no nitrous oxide but received 35-50% oxygen
               for 24 h.
    
    The data show red cell folate levels for the three groups
    after 24h of ventilation.
    """
    
    # Get the data
    print('One-way ANOVA: -----------------')

    # inFile = 'C:/Library/Applications/Typora/data/self-training/Python/data/altman_910.txt'
    # data = np.genfromtxt(inFile, delimiter=',')
    # Module for working with Excel-files
    import xlrd
    # First we have to get the Excel-data into Python. This can be done e.g.
    # with the package "xlrd"
    # You have to make sure that you select a valid location on your computer!
    inFile = 'C:/Library/Applications/Typora/data/self-training/Python/data/Table 6.6 Plant experiment.xls'
    book = xlrd.open_workbook(inFile)
    # We assume that the data are in the first sheet. This avoids the language
    # problem "Tabelle/Sheet"
    sheet = book.sheet_by_index(0)
    # Select the columns and rows that you want:
    # The "treatment" information is in column "E",
    #           i.e. you have to skip the first 4 columns
    # The "weight" information is in column "F",
    #           i.e. you have to skip the first 5 columns
    treatment = sheet.col_values(4)
    weight = sheet.col_values(5)
    # The data start in line 4, i.e. you have to skip the first 3
    # I use a "pandas" DataFrame, so that I can assign names to the variables.
    df = pd.DataFrame({'group':treatment[3:], 'weight':weight[3:]})

    
    # # Sort them into groups, according to column 1
    # # group1 = data[data[:,1]==1,0]
    # # group2 = data[data[:,1]==2,0]
    # # group3 = data[data[:,1]==3,0]
    # # # equal
    # df = pd.DataFrame(data, columns=['value', 'treatment'])    
    # grouped= df.groupby('treatment')
    # grouped.mean()
    
    # # --- >>> START stats <<< ---
    # # First, check if the variances are equal, with the "Levene"-test
    # # (W,p) = stats.levene(group1, group2, group3)
    # # # equal
    # W, p= stats.levene(grouped.get_group(1).value,
    #                    grouped.get_group(2).value,
    #                    grouped.get_group(3).value)
    # if p<0.05:
    #     print(f'Warning: the p-value of the Levene test is <0.05: p={p: 1.3f}')
    
    # # Do the one-way ANOVA
    # # F_statistic, pVal = stats.f_oneway(group1, group2, group3)
    # # # equal
    # F_statistic, pVal = stats.f_oneway(grouped.get_group(1).value,
    #                                    grouped.get_group(2).value,
    #                                    grouped.get_group(3).value)
    # # --- >>> STOP stats <<< ---
    
    # # Print the results
    # print('Data form Altman 910:')
    # print((F_statistic, pVal))
    # if pVal < 0.05:
    #     print('One of the groups is significantly different.')
        
    # Elegant alternative implementation, with pandas & statsmodels
    # df = pd.DataFrame(data, columns=['value', 'treatment'])   


    # First, I fit a statistical "ordinary least square (ols)"-model to the data,
    # using the formula language from "patsy". The formula
    #   'weight ~ C(group)'
    # says:
    #   "weight" is a function of the categorical value "group"
    # and the data are taken from the DataFrame "data", which contains
    # "weight" and "group" 
    model = ols('weight ~ C(group)', df).fit()
    # "anova_lm" (where "lm" stands for "linear model") extracts the
    # ANOVA-parameters from the fitted model.
    anovaResults = anova_lm(model)
    print(anovaResults)
    if anovaResults['PR(>F)'][0] < 0.05:
        print('One of the groups is different.')
    
    # Check if the two results are equal. If they are, there is no output
    # np.testing.assert_almost_equal(F_statistic, anovaResults['F'][0])
    
    # should be (3.711335988266943, 0.043589334959179327)
    # return (F_statistic, pVal)
    return(anovaResults['F'][0])


def show_teqf() -> float:
    """Shows the equivalence of t-test and f-test, for comparing two groups

    Returns
    -------
    F_statistic 
    """
    
    # Get the data
    data = pd.read_csv('C:/Library/Applications/Typora/data/self-training/Python/data/galton.csv')
    
    # First, calculate the F- and the T-values, ...
    F_statistic, pVal = stats.f_oneway(data['father'], data['mother'])
    t_val, pVal_t = stats.ttest_ind(data['father'], data['mother'])
    
    # ... and show that t**2 = F
    print('\nT^2 == F: ------------------------------------------')
    print(f'From the t-test we get t^2={t_val**2:5.3f}, ' +
          f'and from the F-test F={F_statistic:5.3f}')
    
    # numeric test
    np.testing.assert_almost_equal(t_val**2, F_statistic)
    
    return F_statistic


def anova_statsmodels() -> float:
    """ Do the ANOVA with a function
    Returns
    -------
    F_statistic 
    """
    
    # Get the data
    data = pd.read_csv('C:/Library/Applications/Typora/data/self-training/Python/data/galton.csv')

    anova_results = anova_lm(ols('height ~ 1 + sex', data).fit())
    print('\nANOVA with "statsmodels" ------------------------------')
    print(anova_results)
    # anova_results['PR(>F?)'][0]
    
    return anova_results['F'][0]


def anova_byHand() -> Tuple[float, float]:
    """ Calculate the ANOVA by hand.
    While you would normally not do that, this function shows
    how the underlying values can be calculated.

    Returns
    -------
    F : test statistic
    p : proability
    """

     # Get the data
    inFile = 'C:/Library/Applications/Typora/data/self-training/Python/data/altman_910.txt'
    data = np.genfromtxt(inFile, delimiter=',')

    # Convert them to pandas-forman and group them by their group value
    df = pd.DataFrame(data, columns=['values', 'group'])
    groups = df.groupby('group')

    # The "total sum-square" is the squared deviation from the mean
    ss_total = np.sum((df['values']-df['values'].mean())**2)
    
    # Calculate ss_treatment and  ss_error
    (ss_treatments, ss_error) = (0, 0)
    for val, group in groups:
        ss_error += sum((group['values'] - group['values'].mean())**2)
        ss_treatments += len(group) * \
                (group['values'].mean() - df['values'].mean())**2

    df_groups = len(groups)-1
    df_residuals = len(data)-len(groups)
    F = (ss_treatments/df_groups) / (ss_error/df_residuals)
    df = stats.f(df_groups,df_residuals)
    p = df.sf(F)

    print(f'\nANOVA-Results: F = {F}, and p= {p}')
    
    return (F, p)
    

if __name__ == '__main__':
    anova_oneway()
    anova_byHand()
    show_teqf()
    anova_statsmodels()    
    input('Done!')
