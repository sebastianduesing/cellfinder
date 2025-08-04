import os
import re
from owl_reader import get_term_info


def clean_termlist(path):
    with open(path, "r") as file:
        output_lines = []
        lines = file.readlines()
        for line in lines:
            obo = re.match(r"http://purl\.\w+\.org/obo/(\w+)_(\d+)", line)
            if obo:
                base = obo.group(1)
                num = obo.group(2)
                curie = f"{base}:{num}"
                line = re.sub(obo.group(0), curie, line)
            curie_form = re.match(r"(\w+):(\d+)", line)
            if curie_form and "#" not in line:
                base = curie_form.group(1)
                num = curie_form.group(2)
                curie = f"{base}:{num}"
                find_file = os.path.join("build", f"{base}_import_source.owl")
                if os.path.isfile(find_file):
                    _, label, _ = get_term_info(curie, find_file)
                    line = re.sub(r"(\w+):(\d+)", f"{curie} # {label}", line)
            output_lines.append(line)
        output_lines = sorted(list(set(output_lines)))
    with open(path, "w") as file:
        file.writelines(output_lines)


def main():
    path = "removed_terms.txt"
    clean_termlist(path)
    print("Organized removed_terms.txt")


if __name__ == "__main__":
    main()
