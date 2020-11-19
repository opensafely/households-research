#!/usr/bin/env python
# coding: utf-8


import numpy as np
import scipy.stats as st
import scipy.optimize as op
import pandas as pd
from numpy import linalg as LA
import matplotlib.pyplot as plt
import seaborn as sns
import logging
import numba
import os
import sys
import pathlib
import pickle


homedir = pathlib.Path(__file__).resolve().parent.parent

logging.basicConfig(
    filename=homedir / "generate_model_data.log",
    # stream=sys.stdout,
    level=logging.INFO,
    format="%(asctime)s %(message)s",
)
logging.info("Libraries imported and logging started")


def get_df():
    if "test_data" not in sys.argv:
        df = pd.read_stata(
            "hh_analysis_datasetALLVARS.dta", columns=["hh_id", "age", "case"]
        )
    else:
        # test data
        np.random.seed(42)
        patient_count = 1000
        df = pd.DataFrame()
        age_list = range(0, 100)
        case_list = [0] * 10000 + [1]
        hh_id_list = range(0, int(patient_count / 3))

        df["hh_id"] = np.random.choice(hh_id_list, size=patient_count)
        df["age"] = np.random.choice(age_list, size=patient_count)
        df["case"] = np.random.choice(case_list, size=patient_count)
    logging.info("Data Read In")
    return df


def get_storage_lists(df):
    age_bins = [-1, 9, 18, 200]
    age_bitmasks = [2, 1, 0]
    df["age_labels"] = pd.cut(df["age"], bins=age_bins, labels=age_bitmasks, right=True)

    grouped = df.groupby("hh_id")
    cases = grouped["case"].apply(np.array)
    age_categories = grouped["age_labels"].apply(np.array)
    return cases.to_numpy(), age_categories.to_numpy()


def write_outputs():
    cases, age_categories = get_storage_lists(get_df())
    with open("output/case_series.pickle", "wb") as f:
        pickle.dump(cases, f)
    with open("output/age_categories_series.pickle", "wb") as f:
        pickle.dump(age_categories, f)


if __name__ == "__main__":
    write_outputs()
    logging.info("Final format data created")