"""Example of a Kruskal-Wallis test (for not normally distributed data)

Taken from http://www.brightstat.com/index.php?option=com_content&task=view&id=41&Itemid=1&limit=1&limitstart=2
"""


# Import standard packages
import numpy as np

# additional packages
from scipy.stats.mstats import kruskalwallis


def main() -> None:
    """ Comparison of the smog levels in four different cities """
    
    # Get the data
    city1 = np.array([68, 93, 123, 83, 108, 122])
    city2 = np.array([119, 116, 101, 103, 113, 84])
    city3 = np.array([70, 68, 54, 73, 81, 68])
    city4 = np.array([61, 54, 59, 67, 59, 70])

    # # First, I get the values from the dataframe
    # g_a = data['weight'][data['group']=='TreatmentA']
    # g_b = data['weight'][data['group']=='TreatmentB']
    # g_c = data['weight'][data['group']=='Control']
    
    # # Note: this could also be accomplished with the "groupby" fct from pandas
    # # groups = pd.groupby(data, 'group')
    # # g_a = groups.get_group('TreatmentA').values[:,1]
    # # g_c = groups.get_group('Control').values[:,1]
    # # g_b = groups.get_group('TreatmentB').values[:,1]
    
    # --- >>> START stats <<< ---
    # Perform the Kruskal-Wallis test
    h, p = kruskalwallis(city1, city2, city3, city4)
    # --- >>> STOP stats <<< ---
    
    # Print the results
    if p<0.05:
        print('There is a significant difference between the cities:')
    else:
        print('No significant difference between the cities:')
    print(f'p = {p:5.3f}')
    
    return h


if __name__ == '__main__':
    main()    
