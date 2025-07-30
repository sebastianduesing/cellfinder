import argparse
import csv
import os


LAST_ID = None


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


def find_next_id(template):
    """
    Generate next available ID
    """
    ids = []
    for key in template.keys():
        if key != "robot":
            ids.append(key)
    sorted_ids = sorted(ids)
    last_id = sorted_ids[-1]
    curie_parts = last_id.split(":")
    base, numerical = curie_parts[0], int(curie_parts[1])
    numerical += 1
    numerical = str(numerical)
    if len(numerical) < 7:
        zero_count = 7 - len(numerical)
        numerical = ("0" * zero_count) + numerical
    next_id = f"{base}:{numerical}"
    return last_id, next_id


def setup_new_row(template):
    """
    Prepare a new row with empty fields and the next available ID
    """
    prev_id, next_id = find_next_id(template)
    row = {}
    for key in template[prev_id].keys():
        if key == "ID":
            row[key] = next_id
        else:
            row[key] = ""
    return next_id, row


def make_disease_term(template, disease):
    """
    Create a grouping term for CLCs from a particular disease
    """
    next_id, row = setup_new_row(template)
    label = f"immortal {disease} cell line cell"
    row["LABEL"] = label
    row["logical type"] = "equivalent"
    row["parent"] = "immortal cell line cell"
    row["textual definition"] = f"An immortal cell line cell derived from a subject with {disease}."
    row["having disease"] = disease
    template[next_id] = row
    print(f"Created term {next_id} '{label}'")


def make_specimen_term(template, specimen_type):
    """
    Create a grouping term for CLCs from a particular specimen type
    """
    next_id, row = setup_new_row(template)
    label = f"immortal {specimen_type} specimen-derived cell line cell"
    row["LABEL"] = label
    row["logical type"] = "equivalent"
    row["parent"] = "immortal cell line cell"
    row["textual definition"] = f"An immortal cell line cell derived from a {specimen_type} specimen."
    row["derives from tissue"] = specimen_type
    template[next_id] = row
    print(f"Created term {next_id} '{label}'")


def check_term(template, termtype, value):
    found = False
    label = ""
    term_id = ""
    term_label = ""
    if termtype == "disease":
        label = f"immortal {value} cell line cell"
    elif termtype == "specimen":
        label = f"immortal {value} specimen-derived cell line cell"
    for id, row in template.items():
        if row["LABEL"] == label:
            term_id = id
            term_label = label
            found = True
            break
    return found, term_id, term_label


def remove_term(template, term_id):
    del template[term_id]
    return template


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["create", "remove"],
                        help="Which action to take [create/remove]")
    parser.add_argument("type", choices=["disease", "specimen"],
                        help="What type of term to act on [disease/specimen]")
    parser.add_argument("value",
                        help="The name of the disease or specimen")
    args = parser.parse_args()
    path = os.path.join("src", "ontology", "icf.tsv")
    template = TSV2dict(path)
    found, term_id, term_label = check_term(template, args.type, args.value)
    if not found:
        if args.action == "create":
            if args.type == "disease":
                make_disease_term(template, args.value)
            elif args.type == "specimen":
                make_specimen_term(template, args.value)
        if args.action == "remove":
            print(f"Didn't find a {args.value} {args.type} term in this template.")
    if found:
        if args.action == "create":
            print(f"Term {term_id} '{term_label}' is already in this template.")
        elif args.action == "remove":
            template = remove_term(template, term_id)
            print(f"Removed {term_id} '{term_label}' from this template.")

    dict2TSV(template, path)


if __name__ == "__main__":
    main()
