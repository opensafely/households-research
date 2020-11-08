#!/usr/bin/env python
# coding: utf-8

# In[1]:


# Process Vo data for a final size analysis by age
# Edit 17 Aug: just look at adults and children to
# Edit 25 Aug: add Cauchemez model and other updates for ONS
# Edit 7 Oct: Try to debug the sub-epidemics problem Lorenzo noticed
# Remember to atleast_2d the design matrices!


# In[2]:


# get_ipython().run_line_magic('matplotlib', 'inline')
import numpy as np
import scipy.stats as st
import scipy.optimize as op
import pandas as pd
from numpy import linalg as LA
import matplotlib.pyplot as plt
from tqdm.notebook import tqdm


# In[3]:


df = pd.read_csv("./vo_data.csv")


# In[4]:


# Indices of ever positive cases
posi = (df["first_sampling"].values == "Positive") | (
    df["second_sampling"].values == "Positive"
)


# In[5]:


hcol = df.household_id.values
hhids = pd.unique(df.household_id)
len(hhids)


# In[6]:


hh_tests = []
ages = []
for hid in hhids:
    dfh = df[df.household_id == hid]
    tests = (dfh["first_sampling"].values == "Positive") | (
        dfh["second_sampling"].values == "Positive"
    )
    aa = dfh.iloc[:, 2].values
    hh_tests.append(tests)
    ages.append(aa)


# In[7]:


age_gs = pd.unique(df.age_group)
age_gs.sort()
age_gs


# In[8]:


nsamp = np.zeros(len(age_gs))
npos = np.zeros(len(age_gs))


# In[9]:


for i, ag in enumerate(age_gs):
    dfa = df[df.age_group == ag]
    nsamp[i] = len(dfa)
    dfp = df[posi]
    dfa = dfp[dfp.age_group == ag]
    npos[i] = len(dfa)


# In[10]:


# Dictionary that puts ages in categories
# 0 is reference class
as2rg = {
    "00-10": 1,
    "11-20": 1,
    "21-30": 0,
    "31-40": 0,
    "41-50": 0,
    "51-60": 0,
    "61-70": 0,
    "71-80": 0,
    "81-90": 0,
    "91+": 0,
}


# In[11]:


na = max(as2rg.values())


# In[12]:


Y = []  # To store outcomes
XX = []  # To store design matrices
for i in range(0, len(hhids)):
    mya = [as2rg[a] for a in ages[i]]
    m = len(mya)
    myx = np.zeros((m, na))
    myy = np.zeros(m)
    for j, a in enumerate(mya):
        if a > 0:
            myx[j, a - 1] = 1
        if hh_tests[i][j]:
            myy[j] = 1
    Y.append(myy)
    XX.append(np.atleast_2d(myx))


# In[13]:


# The above processes the data - now add final size analysis; first do a run through


# In[14]:


def phi(s, logtheta=0.0):
    theta = np.exp(logtheta)
    return (1.0 + theta * s) ** (-1.0 / theta)


def decimal_to_bit_array(d, n_digits):
    powers_of_two = 2 ** np.arange(32)[::-1]
    return ((d & powers_of_two) / powers_of_two)[-n_digits:]


# In[15]:


x = np.array(
    [
        -3.0,
        -2.0,
        0.1,
        0.2,
        0.3,
        0.4,
        0.5,
    ]
)


# In[16]:


llaL = x[0]
llaG = x[1]
logtheta = x[2]
eta = (4.0 / np.pi) * np.arctan(x[3])
alpha = x[4 : (4 + na)]
beta = x[(4 + na) : (4 + 2 * na)]
gamma = x[(4 + 2 * na) :]

nlv = np.zeros(len(hhids))  # Vector of negative log likelihoods
for i in range(0, len(hhids)):
    y = Y[i]
    X = XX[i]
    if np.all(y == 0.0):
        nlv[i] = np.exp(llaG) * np.sum(np.exp(alpha @ (X.T)))
    else:
        # Sort to go zeros then ones WLOG (could do in pre-processing)
        ii = np.argsort(y)
        y = y[ii]
        X = X[ii, :]
        q = sum(y > 0)
        r = 2 ** q
        m = len(y)

        # Quantities that don't vary through the sum
        Bk = np.exp(-np.exp(llaG) * np.exp(alpha @ (X.T)))
        laM = np.exp(llaL) * np.outer(np.exp(beta @ (X.T)), np.exp(gamma @ (X.T)))
        laM *= m ** eta

        BB = np.zeros((r, r))  # To be the Ball matrix
        for jd in range(0, r):
            j = decimal_to_bit_array(jd, m)
            for omd in range(0, jd + 1):
                om = decimal_to_bit_array(omd, m)
                BB[jd, omd] = 1.0 / np.prod(
                    (phi((1 - j) @ laM, logtheta) ** om) * (Bk ** (1 - j))
                )
        nlv[i] = -np.log(LA.solve(BB, np.ones(r))[-1])
        if q > 2:
            break
nll = np.sum(nlv)


# In[ ]:


# In[17]:


for jd in range(0, r):
    jstr = format(jd, "0" + str(m) + "b")
    j = np.array([int(jstr[x]) for x in range(0, len(jstr))])
    for omd in range(0, jd + 1):
        om = decimal_to_bit_array(omd, m)
        if np.all(om <= j):
            print("({:d},{:d}) j: {}; omega: {}.".format(jd, omd, jstr, omstr))


# In[18]:


om >= j


# In[ ]:


# In[19]:


def mynll(x):
    try:  # Ideally catch the linear algebra fail directly
        llaL = x[0]
        llaG = x[1]
        logtheta = x[2]
        eta = (4.0 / np.pi) * np.arctan(x[3])
        alpha = x[4 : (4 + na)]
        beta = x[(4 + na) : (4 + 2 * na)]
        gamma = x[(4 + 2 * na) :]

        nlv = np.zeros(len(hhids))  # Vector of negative log likelihoods
        for i in range(0, len(hhids)):
            y = Y[i]
            X = XX[i]
            if np.all(y == 0.0):
                nlv[i] = np.exp(llaG) * np.sum(np.exp(alpha @ (X.T)))
            else:
                # Sort to go zeros then ones WLOG (could do in pre-processing)
                ii = np.argsort(y)
                y = y[ii]
                X = X[ii, :]
                q = sum(y > 0)
                r = 2 ** q
                m = len(y)

                # Quantities that don't vary through the sum
                Bk = np.exp(-np.exp(llaG) * np.exp(alpha @ (X.T)))
                laM = np.exp(llaL) * np.outer(
                    np.exp(beta @ (X.T)), np.exp(gamma @ (X.T))
                )
                laM *= m ** eta

                BB = np.zeros((r, r))  # To be the Ball matrix
                for jd in range(0, r):
                    j = decimal_to_bit_array(jd, m)
                    for omd in range(0, jd + 1):
                        om = decimal_to_bit_array(omd, m)
                        if np.all(om <= j):
                            BB[jd, omd] = 1.0 / np.prod(
                                (phi((1 - j) @ laM, logtheta) ** om) * (Bk ** (1 - j))
                            )
                nlv[i] = -np.log(LA.solve(BB, np.ones(r))[-1])
        nll = np.sum(nlv)
        # nll += 7.4*np.sum(x**2) # Add a Ridge if needed
        nll += np.sum(x ** 2)  # Add a Ridge if needed
        return nll
    except:
        nll = np.inf
        return nll


# In[20]:


# Indicative parameters - to do, add bounds and mulitple restarts
x0 = np.array(
    [
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
    ]
)
mynll(x0)


# In[21]:


bb = np.array(
    [
        [-5.0, 0.0],
        [-5.0, 0.0],
        [-10.0, 10.0],
        [-10.0, 10.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
        [-3.0, 3.0],
    ]
)


# In[22]:


def callbackF(x, x2=0.0, x3=0.0):
    print(
        "Evaluated at [{:.3f},{:.3f},{:.3f},{:.3f},{:.3f},{:.3f},{:.3f}]: {:.8f}".format(
            x[0], x[1], x[2], x[3], x[4], x[5], x[6], mynll(x)
        )
    )


# In[23]:


# First try from (essentially) the origin
foutstore = []
fout = op.minimize(
    mynll, x0, method="TNC", callback=callbackF, bounds=bb, options={"maxiter": 10000}
)
# xhat = fout.x
foutstore.append(fout)


# In[24]:


# Because box bounded, try multiple restarts with stable algorithm
np.random.seed(46)
nrestarts = 20
for k in range(0, nrestarts):
    nll0 = np.nan
    while (np.isnan(nll0)) or (np.isinf(nll0)):
        xx0 = np.random.uniform(bb[:, 0], bb[:, 1])
        nll0 = mynll(xx0)
    try:
        print("Starting at:")
        print(xx0)
        print(nll0)
        fout = op.minimize(
            mynll,
            xx0,
            bounds=bb,
            method="TNC",
            callback=callbackF,
            options={"maxiter": 1000, "ftol": 1e-9},
        )
        print("Found:")
        print(fout.x)
        print("")
        foutstore.append(fout)
    except:
        k -= 1


# In[25]:


foutstore


# In[26]:


ff = np.inf * np.ones(len(foutstore))
for i in range(0, len(foutstore)):  # In case of crash
    if foutstore[i].success:
        ff[i] = foutstore[i].fun


# In[27]:


xhat = foutstore[ff.argmin()].x
print(xhat)


# In[28]:


pn = len(x0)
delta = (
    1e-2  # This will need some tuning, but here set at sqrt(default delta in optimiser)
)
dx = delta * xhat
ej = np.zeros(pn)
ek = np.zeros(pn)
Hinv = np.zeros((pn, pn))
for j in tqdm(range(0, pn)):
    ej[j] = dx[j]
    for k in range(0, j):
        ek[k] = dx[k]
        Hinv[j, k] = (
            mynll(xhat + ej + ek)
            - mynll(xhat + ej - ek)
            - mynll(xhat - ej + ek)
            + mynll(xhat - ej - ek)
        )
        ek[k] = 0.0
    Hinv[j, j] = (
        -mynll(xhat + 2 * ej)
        + 16 * mynll(xhat + ej)
        - 30 * mynll(xhat)
        + 16 * mynll(xhat - ej)
        - mynll(xhat - 2 * ej)
    )
    ej[j] = 0.0
Hinv += np.triu(Hinv.T, 1)
Hinv /= 4.0 * np.outer(dx, dx) + np.diag(
    8.0 * dx ** 2
)  # TO DO: replace with a chol ...
covmat = LA.inv(0.5 * (Hinv + Hinv.T))
stds = np.sqrt(np.diag(covmat))
stds


# In[29]:


print(
    "Baseline probability of infection from outside is {:.1f} ({:.1f},{:.1f}) %".format(
        100.0 * (1.0 - np.exp(-np.exp(xhat[1]))),
        100.0 * (1.0 - np.exp(-np.exp(xhat[1] - 1.96 * stds[1]))),
        100.0 * (1.0 - np.exp(-np.exp(xhat[1] + 1.96 * stds[1]))),
    )
)

# phi gets bigger as xhat[1] gets smaller and bigger as xhat[2] gets bigger
# 'Safest' method is Monte Carlo - sample

mymu = xhat[[0, 2, 3]]
mySig = covmat[[0, 2, 3], :][:, [0, 2, 3]]
m = 4000

for k in range(2, 7):
    sarvec = np.zeros(m)
    for i in range(0, m):
        uu = np.random.multivariate_normal(mymu, mySig)
        eta = (4.0 / np.pi) * np.arctan(uu[2])
        sarvec[i] = 100.0 * (1.0 - phi(np.exp(uu[0]) * (k ** eta), uu[1]))

    eta = (4.0 / np.pi) * np.arctan(xhat[3])
    print(
        "HH size {:d} baseline pairwise infection probability is {:.1f} ({:.1f},{:.1f}) %".format(
            k,
            100.0 * (1.0 - phi(np.exp(xhat[0]) * (k ** eta), xhat[2])),
            np.percentile(sarvec, 2.5),
            np.percentile(sarvec, 97.5),
        )
    )


print(
    "Relative external exposure for <=20yo {:.1f} ({:.1f},{:.1f}) %".format(
        100.0 * np.exp(xhat[4]),
        100.0 * np.exp(xhat[4] - 1.96 * stds[4]),
        100.0 * np.exp(xhat[4] + 1.96 * stds[4]),
    )
)
print(
    "Relative susceptibility for <=20yo {:.1f} ({:.1f},{:.1f}) %".format(
        100.0 * np.exp(xhat[5]),
        100.0 * np.exp(xhat[5] - 1.96 * stds[5]),
        100.0 * np.exp(xhat[5] + 1.96 * stds[5]),
    )
)
print(
    "Relative transmissibility for <=20yo {:.1f} ({:.1f},{:.1f}) %".format(
        100.0 * np.exp(xhat[6]),
        100.0 * np.exp(xhat[6] - 1.96 * stds[6]),
        100.0 * np.exp(xhat[6] + 1.96 * stds[6]),
    )
)


# In[ ]:

