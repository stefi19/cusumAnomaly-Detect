"""
plot_anomalies.py
Utility script to generate per-sensor PNG plots using the per-sensor CSVs
and the corresponding anomaly CSVs produced by the C++ pipeline.

Behavior:
 - discovers files matching output/*_rez_soft.csv
 - for each, loads the base sensor CSV (output/<sensor>.csv) and the
   anomalies CSV (output/<sensor>_rez_soft.csv)
 - plots value vs id and overlays anomaly points

The script prefers pandas for CSV loading but falls back to the stdlib csv
reader if pandas is not available.
"""

import glob
import os
import csv

# Import matplotlib (required for plotting). If missing, instruct how to install.
try:
    import matplotlib.pyplot as plt
except Exception:
    print("matplotlib is required for plotting. Install it with: pip3 install matplotlib")
    raise

# pandas is optional; if present it simplifies CSV loading.
try:
    import pandas as pd
    _HAS_PANDAS = True
except ImportError:
    _HAS_PANDAS = False


def load_csv_basic(path):
    """Fallback CSV loader for files with header 'id,value'. Returns dict with lists."""
    ids = []
    vals = []
    with open(path, newline='') as f:
        reader = csv.reader(f)
        header = next(reader, None)
        if header is None:
            return {"id": [], "value": []}
        # normalize header entries
        hdr = [h.strip().lower() for h in header]
        try:
            id_i = hdr.index('id')
            val_i = hdr.index('value')
        except ValueError:
            # assume first two columns if header is unexpected
            id_i, val_i = 0, 1
        for row in reader:
            if len(row) <= max(id_i, val_i):
                continue
            try:
                ids.append(int(row[id_i]))
                vals.append(float(row[val_i]))
            except Exception:
                # ignore malformed rows
                continue
    return {"id": ids, "value": vals}


# Discover anomaly result files and plot them.
rez_files = glob.glob("output/*_rez_soft.csv")
if not rez_files:
    print("No *_rez_soft.csv files found in ./output. Nothing to plot.")

for rez in rez_files:
    base = rez.replace("_rez_soft.csv", ".csv")
    if not os.path.exists(base):
        print(f"Base sensor file not found for {rez}, expected {base}. Skipping.")
        continue

    # load data (prefer pandas)
    if _HAS_PANDAS:
        df = pd.read_csv(base)
        a = pd.read_csv(rez)
        x = df['id'].tolist()
        y = df['value'].tolist()
        ax = (a['id'].tolist(), a['value'].tolist()) if not a.empty else ([], [])
    else:
        df = load_csv_basic(base)
        a = load_csv_basic(rez)
        x = df['id']
        y = df['value']
        ax = (a['id'], a['value'])

    # Create the plot and save it next to the base CSV.
    plt.figure()
    plt.plot(x, y, label="value")
    if ax[0]:
        plt.scatter(ax[0], ax[1], color='red', label='anomaly')
    plt.title(os.path.basename(base))
    plt.xlabel("Time (ID)")
    plt.ylabel("Temperature x100")
    plt.grid(True)
    plt.legend()

    out_png = base.replace(".csv", ".png")
    plt.savefig(out_png)
    plt.close()

print("Saved PNG plots for each detected sensor in ./output")
