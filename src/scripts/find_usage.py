import os
from TSV_dict_converter import TSV2dict, dict2TSV


def main():
    input_dict = TSV2dict("remove_terms.tsv")
    icf = TSV2dict(os.path.join("src", "ontology", "icf.tsv"))
    usage_dict = {"robot": {
        "ontology ID": "",
        "label": "",
        "usages": ""
            }
    }
    for id, row in input_dict.items():
        usages = []
        if id == "ID":
            continue
        label = row["Label"]
        for index, rowdict in icf.items():
            for i in [
                "parent",
                "derives from organism", "axiom organism",
                "derives from cell", "axiom cell",
                "derives from tissue", "axiom tissue",
                "having disease", "axiom disease",
                "unified axiom"
            ]:
                if label == rowdict[i] or f"'{label}'" in rowdict[i]:
                    text = rowdict[i]
                    icf_label = rowdict["LABEL"]
                    if len(usages) < 10:
                        usages.append(f"{index} '{icf_label}' [{i}: {text}]")
        usages = ", ".join(usages)
        usage_dict[id] = {
            "ontology ID": id,
            "label": label,
            "usages": usages
        }
    dict2TSV(usage_dict, "terms_to_remove.tsv")


if __name__ == "__main__":
    main()
