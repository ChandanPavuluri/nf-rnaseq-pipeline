import sys
import os
import pandas as pd
import glob

if len(sys.argv) < 2:
    raise SystemExit("Usage: python merge_salmon.py <project_dir>")

projectDir = sys.argv[1]
salmon_dir = os.path.join(projectDir, "output","salmon")


os.chdir(salmon_dir)

quant_files = glob.glob("*_salmon/quant.sf")
if not quant_files:
    raise FileNotFoundError(f"No quant.sf files found in {salmon_dir}")

tpm_list = []
count_list = []

for q in quant_files:
    sample = os.path.dirname(q).replace("_salmon", "")

    df = pd.read_csv(q, sep="\t")

    # TPM
    tpm_df = df[['Name', 'TPM']].copy()
    tpm_df.columns = ['Name', sample]
    tpm_list.append(tpm_df)

    # NumReads
    cnt_df = df[['Name', 'NumReads']].copy()
    cnt_df.columns = ['Name', sample]
    count_list.append(cnt_df)

# Merge TPM
tpm_merged = tpm_list[0]
for df in tpm_list[1:]:
    tpm_merged = tpm_merged.merge(df, on="Name")

# Merge Counts
cnt_merged = count_list[0]
for df in count_list[1:]:
    cnt_merged = cnt_merged.merge(df, on="Name")


tpm_merged.to_csv(os.path.join(salmon_dir,"salmon_tpm_matrix.csv"), sep=",", index=False)
cnt_merged.to_csv(os.path.join(salmon_dir,"salmon_counts_matrix.csv"), sep=",", index=False)

print("Created salmon_counts_matrix.csv and salmon_tpm_matrix.csv")
