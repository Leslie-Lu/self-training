import numpy as np
a = np.array([1,2,3,4]) #one-dimension array
print(a)
print(a.shape)
print(a.transpose()) #no change

A = np.array([1, 2, 3, 4])
A_t = A[:, np.newaxis] #add a new axis
print(A_t)
print(A_t.shape)

A = np.array([[1, 2, 3, 4]]) #two-dimension array
print(A)
print(A.shape)
print(A.T)

# sum of two vectors
u = np.array([[1,2,3]]).T
v = np.array([[5,6,7]]).T
print(u + v)

# scalar multiplication of a vector
u = np.array([[1, 2, 3]]).T
print(3*u)

# dot product of two vectors
u = np.array([3, 5, 2])
v = np.array([1, 4, 7])
print(np.dot(u, v))
# np.dot should be applied to one-dimension array
u = np.array([[3, 5, 2]])
v = np.array([[1, 4, 7]])
print(np.dot(u,v)) #error with row-based two-dimension array
u = np.array([[3, 5, 2]]).T
v = np.array([[1, 4, 7]]).T
print(np.dot(u,v)) #error with column-based two-dimension array
u = np.array([[3, 5, 2]])
v = np.array([[1, 4, 7]]).T
print(np.dot(u,v)) #also can be written with @, i.e., u @ v

# cross product of two vectors
u = np.array([3, 5])
v = np.array([1, 4])
print(np.cross(u, v))
x = np.array([3, 3, 9])
y = np.array([1, 4, 12])
print(np.cross(x, y))

# linear combination of vectors
u = np.array([[1, 2, 3]]).T
v = np.array([[4, 5, 6]]).T
w = np.array([[7, 8, 9]]).T
print(3*u+4*v+5*w)

# matrix
A = np.array([[1, 2],
              [3, 4],
              [5, 6],
              [7, 8]])
print(A)
print(A.shape)

# square matrix
A = np.array([[1, 1, 1, 1],
              [2, 2, 2, 2],
              [3, 3, 3, 3],
              [4, 4, 4, 4]])
print(A)
print(A.shape) #four-by-four matrix

# transpose of a matrix
A = np.array([[1, 2, 3, 4],
              [5, 6, 7, 8]])
print(A)
print(A.T)

# symmetric matrix
S = np.array([[1, 2, 3, 4],
              [2, 5, 6, 7],
              [3, 6, 8, 9],
              [4, 7, 9, 0]])
print(S)
print(S.T)

# zero matrix
A = np.zeros([5, 3])
print(A)

# diagonal matrix
A = np.diag([1, 2, 3, 4, 5])
print(A)

# identity matrix
I = np.eye(5)
print(I)

# matrix addition
A = np.array([[1, 2],
              [3, 4],
              [5, 6]])
B = np.array([[10, 20],
              [30, 40],
              [50, 60]])
print(A+B)

# scalar multiplication of a matrix
A = np.array([[1, 4],
              [2, 5],
              [3, 6]])
print(2*A)

# matrix multiplication
A = np.array([[1, 2],
              [3, 4],
              [5, 6],
              [7, 8]])
B = np.array([[2, 3, 4, 5],
              [6, 7, 8, 9]])
print(np.dot(A, B))

# matrix-vector multiplication
A = np.array([[1, 2],
              [3, 4],
              [5, 6]])
x = np.array([[4, 5]]).T
print(np.dot(A, x))
