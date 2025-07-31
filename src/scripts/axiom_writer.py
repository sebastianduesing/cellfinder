"""
Combine several columns in a template of cell line cells into one unified axiom
"""


import csv
import os


def TSV2dict(path):
    """
    Make a dict from a ROBOT template with ontology IDs as dict keys
    """
    header_row = None
    with open(path, "r", encoding="UTF-8") as infile:
        reader = csv.DictReader(infile, delimiter="\t")
        output = {}
        for row in reader:
            if not header_row:
                header_row = list(row.keys())
            id = row["ID"].strip()
            if id == "":
                continue
            if id == "ID":
                for i in row:
                    output["robot"] = row
            else:
                for i in row:
                    output[id] = row
        return output


def dict2TSV(xdict, path):
    """
    Make a ROBOT template from a dict input with ontology IDs as dict keys
    """
    rows = [i for i in xdict.keys()]
    first = rows[0]
    fieldnames = [i for i in xdict[first].keys()]
    ids = []
    for key in xdict.keys():
        if key != "robot":
            ids.append(key)
    sorted_ids = sorted(ids)
    with open(path, "w", newline="\n", encoding='utf-8') as tsv:
        writer = csv.DictWriter(tsv, fieldnames=fieldnames, delimiter="\t")
        writer.writeheader()
        writer.writerow(xdict["robot"])
        for id in sorted_ids:
            writer.writerow(xdict[id])


def write_axiom(row):
    """
    Generate a combined axiom based on other columns
    """
    cell = row["derives from cell"]
    organism = row["derives from organism"]
    tissue = row["derives from tissue"]
    disease = row["having disease"]
    axiom = ""
    c_phrase = ""
    c_sep = ""
    d_phrase = ""
    o_phrase = ""
    o_sep = ""
    t_phrase = ""
    t_sep = ""
    if disease != "":
        d_phrase = f" and ('has disease' some '{disease}'"
        if organism == "":
            organism = "organism"
        o_sep, t_sep, c_sep = "(", "(", "("
    if organism != "":
        o_phrase = f" and ('part of' some {o_sep}'{organism}'"
        t_sep, c_sep = "(", "("
    if tissue != "":
        t_phrase = f" and ('part of' some {t_sep}'{tissue}'"
        c_sep = "("
    if cell == "":
        cell = "cell"
    c_phrase = f"'derives from' some {c_sep}'{cell}'"
    axiom = f"{c_phrase}{t_phrase}{o_phrase}{d_phrase}"
    open_parenthesis_count = axiom.count("(")
    closed_parenthesis_count = axiom.count(")")
    add_parenthesis_count = open_parenthesis_count - closed_parenthesis_count
    if add_parenthesis_count > 0:
        axiom += (")" * add_parenthesis_count)
    return axiom


def main():
    path = os.path.join("src", "ontology", "icf.tsv")
    template = TSV2dict(path)
    for id, row in template.items():
        if id == "robot":
            row["unified axiom"] = "C %"
            continue
        row["unified axiom"] = write_axiom(row)
    dict2TSV(template, path)


if __name__ == "__main__":
    main()
