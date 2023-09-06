""" Comparison of two groups
- Analysis of paired data
- Analysis of unpaired data
"""


# Import standard packages
import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats


def paired_data() -> float:
    """Analysis of paired data
    Compare mean daily intake over 10 pre-menstrual
    and 10 post-menstrual days (in kJ).

    Returns
    -------
    p : probability of the Wilcoxon-test
    """
    
    # Get the data:  daily intake of energy in kJ for 11 women
    inFile = 'C:/Library/Applications/Typora/data/self-training/Python/data/altman_93.txt'
    data = np.genfromtxt(inFile, delimiter=',')
    
    np.mean(data, axis=0)
    np.std(data, axis=0, ddof=1)
    
    pre = data[:,0]
    post = data[:,1]
    
    # --- >>> START stats <<< ---
    # paired t-test: doing two measurments on the same experimental unit
    # e.g., before and after a treatment
    t_statistic, p_value = stats.ttest_1samp(post - pre, 0)
    # equal to
    # stats.ttest_rel(pre, post)

    # test
    # stats.ttest_ind(pre, post)
    
    # p < 0.05 => alternative hypothesis:
    # the difference in mean is not equal to 0
    print(f"paired t-test: {p_value: 1.3f}")
    
    # alternative to paired t-test when data has an ordinary scale or when not
    # normally distributed
    rankSum, p_value = stats.wilcoxon(post - pre, mode='approx')
    # --- >>> STOP stats <<< ---
    print(f"Wilcoxon-Signed-Rank-Sum test: {p_value: 1.3f}")
    
    return p_value # should be 0.0033300139117459797
    # z-value -2.9341


def unpaired_data() -> float:
    """ Then some unpaired comparison: 24 hour total energy
    expenditure (MJ/day), in groups of lean and obese women

    Returns
    -------
    p : probability of the Mann-Whitney test
    """

    print('Two groups of data =========================================')
    
    # Get the data: energy expenditure in mJ and stature (0=obese, 1=lean)
    inFile = 'C:/Library/Applications/Typora/data/self-training/Python/data/altman_94.txt'
    energ = np.genfromtxt(inFile, delimiter=',')
    
    # # Group them
    # group1 = energ[:, 1] == 0
    # group1 = energ[group1][:, 0]
    # group2 = energ[:, 1] == 1
    # group2 = energ[group2][:, 0]
    
    # np.mean(group1)
    # np.mean(group2)
    
    # # --- >>> START stats <<< ---
    # # two-sample t-test
    # # null hypothesis: the two groups have the same mean
    # # this test assumes the two groups have the same variance...
    # # (can be checked with tests for equal variance)
    # # independent groups: e.g., how boys and girls fare at an exam
    # # dependent groups: e.g., how the same class fare at 2 different exams
    # t_statistic, p_value = stats.ttest_ind(group1, group2)
    
    # # p_value < 0.05 => alternative hypothesis:
    # # they don't have the same mean at the 5% significance level
    # print(f'two-sample t-test: p = {p_value: 1.3f}')
    
    # # For non-normally distributed data, perform the two-sample wilcoxon rank sum test
    # # a.k.a Mann Whitney U
    # u, p_value = stats.mannwhitneyu(group1, group2)
    # print(f'Mann-Whitney test: p = {p_value:5.3f}')
    # # --- >>> STOP stats <<< ---
    
    # # Plot the data
    # plt.plot(group1, 'bx', label='obese')
    # plt.plot(group2, 'ro', label='lean')
    # plt.legend(loc=0)
    # plt.show()
    
    # The same calculations, but implemented with pandas, would be:
    import pandas as pd
    df = pd.DataFrame(energ, columns = ['energy', 'weightClass'])
    grouped = df.groupby('weightClass')
    grouped.mean()

    # Normality test 
    print('\n Normality test ----------------------------------------------')
    # To do the test for both data-sets, make a tuple with "(... , ...)",
    # add a counter with "enumerate", and iterate over the set:
    for ii, data in enumerate((grouped.get_group(0).energy, grouped.get_group(1).energy)):
        (_, pval) = stats.normaltest(data)
        if pval > 0.05:
            print(f'Dataset # {ii} is normally distributed')

    t_statistic, p_value = stats.ttest_ind(grouped.get_group(0).energy,
                                           grouped.get_group(1).energy)    
    grouped.energy.plot(marker='o', lw=0)
    plt.legend(['obese', 'lean'])
    plt.show()

    # Mann-Whitney test -----------------------------------------------------
    print('\n Mann-Whitney test --------------------------------------------')
    u, pval = stats.mannwhitneyu(grouped.get_group(0).energy,
                                 grouped.get_group(1).energy)
    if pval < 0.05:
        print('With the Mann-Whitney test, data1 and data2 are'+
              f' significantly different(p = {pval:5.3f})')
    else:
        print('No difference between data1 and data2 with Mann-Whitney test.')
    
    return p_value  # should be 0.001060806692940024

def t_reg() -> float:
    """perform statistical inference and statistical modelling

    Returns
    -------
    p: probability of statistical inference
    """

    # get data
    np.random.seed(123)
    race_1= np.round(np.random.randn(20)*10 + 90)
    race_2= np.round(np.random.randn(20)*10 + 85)

    # statistical inference
    t, pval= stats.ttest_rel(race_1, race_2)
    print(f'The probibility that the two distributions are equal is {pval: 1.3f}.')

    # statistical modelling
    import pandas as pd
    import statsmodels.formula.api as sm
    df= pd.DataFrame({'Race1': race_1, 'Race2': race_2})
    result= sm.ols(formula= 'I(Race2-Race1) ~ 1', data= df).fit()
    print(result.summary())

    return pval


if __name__ == '__main__':
    p = paired_data()    
    
    p = unpaired_data()
    p= t_reg()
    input('\nDone!\n'+
          'Hit any key to finish.')
