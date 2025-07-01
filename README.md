# Coarse-Grained Membrane Protein System Setup
This repository contains a Bash script to streamline the setup of coarse-grained molecular dynamics simulations using the MARTIN
---
## ■ Overview
This script:
1. Aligns a protein to the membrane normal using **Memembed**
2. Converts the protein to coarse-grained using **Martinize2**
3. Builds a lipid membrane system using **INSANE**
4. Generates a GROMACS-compatible topology
5. Adds ions and equilibrates the system
---
## ■ Folder Structure
```
.
■■■ run_setup.sh
# Main setup script
■■■ setup_scripts/
# Folder for templates and MDP files
■ ■■■ insane3-chol.py
■ ■■■ template.top
■ ■■■ minimization.mdp
■ ■■■ equil_1.mdp
■ ■■■ equil_2.mdp
■ ■■■ md_2023.compressed.mdp
```
---
## ■■ Requirements
| Tool
| Notes
|
|--------------|----------------------------------|
| GROMACS
| Version 2020+ recommended
|
| Martinize2 | MARTINI 3 support
|
| Memembed | For membrane alignment
|
| INSANE
| Python 2 version (legacy script) |
| DSSP (mkdssp)| Secondary structure assignment |
---
## ■ Setup
1. **Edit `run_setup.sh`**:
Set your own paths at the top of the script:
```bash
setup_dir="/absolute/path/to/setup_scripts"
memembed_bin="/path/to/memembed"
gmx_bin="/path/to/gmx"
mkdssp_bin="mkdssp"
```
2. **Prepare your PDB file**:
Ensure your input protein PDB is clean and named properly (e.g., `yourprotein.pdb`).3. **Run the script**:
```bash
bash run_setup.sh yourprotein.pdb
```
---
## ■ Notes
- The script assumes 12×12×12 nm³ box and a lipid composition of 40% POPC, 40% POPE, and 20% cholesterol.
- Index groups are automatically generated and renamed (`LIPID`, `SOL_ION`, etc.).
- The overlap step is commented out — modify as needed.
---
## ■ Disclaimer
This script is provided as-is for academic and research purposes. Make sure to validate each step based on your specific system a
---
## ■ Contributions
Feel free to fork, modify, or suggest improvements via pull requests. Bug reports welcome.
---
## ■ Acknowledgements
- [MARTINI Force Field](http://cgmartini.nl)
- [GROMACS Molecular Dynamics](http://www.gromacs.org)
- Memembed, Martinize2, INSANE script authors and community contributors
