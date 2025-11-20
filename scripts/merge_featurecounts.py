import sys
import os
import glob
import pandas as pd


# Read projectDir argument

if len(sys.argv) < 2:
    print("Usage: merge_featurecounts.py <projectDir>")
    sys.exit(1)

projectDir = sys.argv[1]
counts_dir = os.path.join(projectDir, "output","counts")

print(f"Looking for FeatureCounts files in: {counts_dir}")


# Locate *_counts.txt files

files = glob.glob(os.path.join(counts_dir, "*_counts.txt"))

if not files:
    raise FileNotFoundError("No *_counts.txt files found in /output/counts/")

tables = []


# Read each FeatureCounts file
# Use ONLY the LAST column (sample counts)

for f in files:
    sample = os.path.basename(f).replace("_counts.txt", "")
    df = pd.read_csv(f, sep="\t", comment="#")

    last_col = df.columns[-1]  # sample column
    df = df[['Geneid', 'Length', last_col]]
    df.columns = ['Geneid', 'Length', sample]

    tables.append(df)


# Merge all samples

merged = tables[0]
for df in tables[1:]:
    merged = merged.merge(df, on=['Geneid', 'Length'], how='inner')


# Calculate TPM

tpm = merged.copy()
gene_lengths_kb = tpm['Length'] / 1000

for sample in tpm.columns[2:]:
    rpk = tpm[sample] / gene_lengths_kb
    scale = rpk.sum() / 1e6
    tpm[sample] = rpk / scale


# Save output files

merged.to_csv(os.path.join(counts_dir, "merged_counts_matrix.csv"), sep=",", index=False)
tpm.to_csv(os.path.join(counts_dir, "merged_TPM_matrix.csv"), sep=",", index=False)

print("created merged_counts_matrix and merged_TPM_matrix ")


