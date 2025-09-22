import argparse
import csv
import os
from owl_reader import get_term_info
from subprocess import run


def TSV2dict(path):
    """
    Make a dict from a TSV with ontology acronyms as dict keys
    """
    header_row = None
    with open(path, "r", encoding="UTF-8") as infile:
        reader = csv.DictReader(infile, delimiter="\t")
        output = {}
        for row in reader:
            if not header_row:
                header_row = list(row.keys())
            if "Ontology" in row.keys():
                id = row["Ontology"].strip()
            else:
                id = row["ontology ID"].strip()
            if id == "ID":
                for i in row:
                    output["robot"] = row
            else:
                for i in row:
                    output[id] = row
        return output


def dict2TSV(xdict, path):
    """
    Make a TSV from a dict input with ontology acronyms as dict keys
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
        if "robot" in xdict.keys():
            writer.writerow(xdict["robot"])
        for id in sorted_ids:
            writer.writerow(xdict[id])


def update_import_source_tsv(path, ontology, iri):
    """
    Specify an IRI of a file to be used as the import source for an ontology
    """
    if os.path.isfile(path):
        import_source_dict = TSV2dict(path)
    else:
        import_source_dict = {}
    import_source_dict[ontology] = {
        "Ontology": ontology,
        "IRI": iri
    }
    dict2TSV(import_source_dict, path)
    print(f"Set source for {ontology} as {iri}")


def remove_import_source(path, ontology):
    """
    Remove a line in the import source file
    """
    if not os.path.isfile(path):
        print(f"Didn't find {path}")
        quit()
    import_source_dict = TSV2dict(path)
    if ontology in import_source_dict.keys():
        del import_source_dict[ontology]
        dict2TSV(import_source_dict, path)
        print(f"Removed source for {ontology}")
    else:
        print(f"No source for {ontology} found in file")


def get_import_source_file(path, ontology):
    """
    Download the import source file for an ontology
    """
    import_source_dict = TSV2dict(path)
    if ontology not in import_source_dict.keys():
        iri = f"http://purl.obolibrary.org/obo/{ontology.lower()}.owl"
    else:
        iri = import_source_dict[ontology]["IRI"]
    file_destination = os.path.join("build", f"{ontology}_import_source.owl")
    run([
        "curl",
        "-sL",
        iri,
        "-o",
        file_destination
    ])
    print(f"Downloaded {ontology} import source file")


def check_input_file(ontology):
    """
    Check that labels in input file are up to date & replace as needed
    """
    input_path = os.path.join("src",
                              "ontology",
                              "robot_inputs",
                              f"{ontology}_input.tsv")
    input_dict = TSV2dict(input_path)
    source_file = os.path.join("build", f"{ontology}_import_source.owl")
    for id, rowdict in input_dict.items():
        if id == "ID":
            continue
        try:
            _, label, _ = get_term_info(id, source_file, listmode=True)
        except TypeError:
            source = id.split(":")
            source = source[0]
            alt_source = os.path.join("build", f"{source}_import_source.owl")
            if not os.path.isfile(alt_source):
                continue
            try:
                print(f"Checking {source} import...")
                _, label, _ = get_term_info(id, alt_source, listmode=True)
            except TypeError:
                continue
        if rowdict["label"] != label:
            rowdict["label"] = label
    dict2TSV(input_dict, input_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["change", "check", "get", "remove"],
                        help="What to do, e.g., change or get the source file")
    parser.add_argument("ontology",
                        help="Which ontology source file to act on, e.g., CLO")
    parser.add_argument("--iri", "-i", default=None,
                        help="An IRI to use as that ontology's source file")
    parser.add_argument("--path", "-p",
                        default="src/ontology/import_sources.tsv",
                        help="A path to the TSV of import source data")
    parser.add_argument("--reload", "-r", action="store_true",
                        help="Gets the new file after a source change")
    args = parser.parse_args()
    path = args.path
    if path is None:
        path = os.path.join("src", "ontology", "import_sources.tsv")
    if args.action == "change":
        update_import_source_tsv(path, args.ontology, args.iri)
    if args.action == "remove":
        remove_import_source(path, args.ontology)
    if args.action == "get" or args.reload:
        get_import_source_file(path, args.ontology)
    if args.action == "check":
        check_input_file(args.ontology)


if __name__ == "__main__":
    main()
