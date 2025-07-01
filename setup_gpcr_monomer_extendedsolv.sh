#!/bin/bash
set -e  # Exit on error

# === USER CONFIGURATION ===
# Set your own directories here
setup_dir="/path/to/your/setup_scripts"         # e.g., /home/yourname/setup_scripts
memembed_bin="/path/to/memembed"                # e.g., /opt/memembed/memembed-master/bin/memembed
gmx_bin="/path/to/gmx"                          # e.g., /opt/gromacs-2023.4/build/bin/gmx
mkdssp_bin="mkdssp"                             # or full path if not in $PATH
insane_script="$setup_dir/insane3-chol.py"      # path to insane3-chol.py
# ===========================

PDB=$1
if [[ -z $PDB ]]; then
    echo "Usage: $0 protein.pdb"
    exit 1
fi

# === Functions ===

align_protein () {
    "$memembed_bin" "$1.pdb"
    cp "${1}_EMBED.pdb" "${1}_EMBED.ready.pdb"
    sed -i '/DUM/d' "${1}_EMBED.ready.pdb"
}

build_protein () {
    martinize2 -f "${pdb_name}_EMBED.ready.pdb" -dssp "$mkdssp_bin" \
        -ff martini3001 -x protein-cg.pdb -o protein-cg.top \
        -elastic -ef 500 -eu 1.0 -el 0.5 -ea 0 -ep 0 \
        -maxwarn 100000 -scfix -merge A,B,C,D,E,F,G,H,I,J,K,L
}

build_membrane () {
    python2 "$insane_script" -f protein-cg.pdb -o all-cg.gro \
        -x 12 -y 30 -z 12 -l POPC:40 -l POPE:40 -l CHOL:20 -sol W -p temp.top
}

build_topology () {
    cp "$setup_dir/template.top" topol.top
    grep -A99 '\[ molecules \]' temp.top >> topol.top
    sed -i 's/Protein/molecule_0/g' topol.top

    echo -e '"non-Protein" & !aW\n"non-Protein" & aW\nq' | "$gmx_bin" make_ndx -f all-cg.gro -o sys.ndx
    sed -i 's/non-Protein_&_!W/LIPID/g' sys.ndx
    sed -i 's/non-Protein_&_W/SOL_ION/g' sys.ndx

    "$gmx_bin" grompp -f "$setup_dir/minimization.mdp" -c all-cg.gro -p topol.top -o ions -maxwarn 3
    echo W | "$gmx_bin" genion -s ions.tpr -p topol.top -neutral -pname NA -nname CL -o ions.pdb -conc 0.0375

    # Optional overlap fix
    # python3 /path/to/overlap.py -f ions.pdb -o out.pdb -overlap 0.4
}

settle () {
    "$gmx_bin" grompp -f "$setup_dir/minimization.mdp" -c ions.pdb -p topol.top -o em -maxwarn 2
    "$gmx_bin" mdrun -v -deffnm em -ntomp 24 -ntmpi 1 -pin on -pinoffset 0

    "$gmx_bin" grompp -f "$setup_dir/equil_1.mdp" -c em.gro -r em.gro -p topol.top -o eq1 -n sys -maxwarn 2
    "$gmx_bin" mdrun -v -deffnm eq1 -ntomp 24 -ntmpi 1 -pin on -pinoffset 0

    "$gmx_bin" grompp -f "$setup_dir/equil_2.mdp" -c eq1.gro -r eq1.gro -p topol.top -o eq2 -n sys -maxwarn 2
    "$gmx_bin" mdrun -v -deffnm eq2 -ntomp 24 -ntmpi 1 -pin on -pinoffset 0

    "$gmx_bin" grompp -f "$setup_dir/md_2023.compressed.mdp" -c eq2.gro -r eq2.gro -p topol.top -o md -n sys -maxwarn 2
}

# === Run pipeline ===
pdb_name="${PDB%.pdb}"
align_protein "$pdb_name"
build_protein
build_membrane
build_topology
settle

