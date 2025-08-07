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
            id = row["ontology ID"].strip()
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
    if "robot" not in xdict.keys():
        xdict["robot"] = {
            "ontology ID": "ID",
            "label": "",
            "action": "",
            "logical type": "CLASS_TYPE",
            "parent class": "C %"
        }
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


def universalize_all(dir):
    all_terms = {}
    for filename in os.listdir(dir):
        path = os.path.join(dir, filename)
        terms = TSV2dict(path)
        all_terms[filename] = terms
    for filename, terms in all_terms.items():
        other_files = [name for name in all_terms.keys() if name != filename]
        for id, row in terms.items():
            for file in other_files:
                if id not in all_terms[file].keys():
                    all_terms[file][id] = row
    for filename in os.listdir(dir):
        dict2TSV(all_terms[filename], os.path.join(dir, filename))


def main():
    import_dir = os.path.join("src", "ontology", "robot_inputs")
    universalize_all(import_dir)


if __name__ == "__main__":
    main()
