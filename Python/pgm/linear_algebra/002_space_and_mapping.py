
# rank of matrix, number of linearly independent columns of a matrix
import numpy as np
A_1 = np.array([[1, 1, 0],
                [1, 0, 1]])
A_2 = np.array([[1, 2, -1],
                [2, 4, -2]])
A_3 = np.array([[1, 0],
                [0, 1],
                [0, -1]])
A_4 = np.array([[1, 2],
                [1, 2],
                [-1, -2]])
A_5 = np.array([[1, 1, 1],
                [1, 1, 2],
                [1, 2, 3]])
print(np.linalg.matrix_rank(A_1))
print(np.linalg.matrix_rank(A_2))
print(np.linalg.matrix_rank(A_3))
print(np.linalg.matrix_rank(A_4))
print(np.linalg.matrix_rank(A_5))

# inverse of matrix
from scipy import linalg
A = np.array([[1, 35, 0],
              [0, 2, 3],
              [0, 0, 4]])
A_n = linalg.inv(A) # inverse of matrix A
print(A_n)
print(np.dot(A, A_n)) # A * A_n = I
# singular matrix, i.e., a matrix that does not have an inverse
B = np.array([[1, 0, 2],
              [0, 1, 3],
              [1, 1, 5]])
B_n = linalg.inv(B)

# solve linear equations
A = np.array([[1, 2, 3],
              [1, -1, 4],
              [2, 3, -1]])
y = np.array([14, 11, 5])
x = linalg.solve(A, y)
print(x)