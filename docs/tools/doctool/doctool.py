
import os, shutil, subprocess, sys, tempfile, shutil
from colorama import Fore, Style
from pathlib import Path

VENV_DIR = ".venv"
TEMP_DIR = tempfile.mkdtemp(prefix="om-doctool-")
CONFIG_PATH = "./config.json"
IGNORE_DIRECTORIES = ["addons"]
DOCTOOL_PATH = "doc/tools/make_rst.py"

def main() -> None:
    print_i(f"Temp Directory: '{TEMP_DIR}'")
    # Check if we have a saved config.

    # Ask if we want to use the saved config.

    # Get user input
    godot = prompt("Path to Godot binary: ")
    if shutil.which(godot) == None:
        print_error(f"Godot not found at: '{godot}'")
        sys.exit(1)

    # Get the target directory of the html files
    html_output = prompt("Path to the output directory: ")
    html_o = Path(html_output)
    if html_o.is_dir() == False:
        print_i("Output directory does not exist. Creating it now.")
        html_o.mkdir(parents=True, exist_ok=True)
    else:
        trash_output_dir = prompt("Your specified directory already exists, remove it? [y/N] ")
        if trash_output_dir.lower() == "y":
            print_i("Removing directory.")
            # TODO: Validate
            # shutil.rmtree(html_output)
            print_i("Creating directory.")
            html_o.mkdir(parents=True, exist_ok=True)

    # Download Godot source tree to get doc tool. :(
    print_i("Because this tool relies on the internal Godot doctool, the whole Godot repo must be downloaded.")
    godot_source_o = Path("./godot")
    if godot_source_o.is_dir() == False:
        print_i("Downloading Godot.")
        subprocess.run(["git", "clone",  "--depth", "1", "https://github.com/godotengine/godot", "./godot"])
    else:
        print_i("Godot already downloaded.")

    # Run doctool generation - output to temp

    print_i("Generating doctool output.")
    subprocess.run([godot, "--path", "../../../src/", "--doctool", TEMP_DIR + "/doctool_raw", "--gdscript-docs", "."])

    # Run downloaded make_rst.py program - output to temp
    print_i("Running make_rst.py program.")
    subprocess.run(["python3", "./godot/" + DOCTOOL_PATH, TEMP_DIR + "/doctool_raw", "-o", TEMP_DIR + "/doctool_rst"])

    # Initialize the folder as a sphinx folder
    print_i("Initializing folder as a sphinx website.")
    subprocess.run(["sphinx-quickstart", html_output])

    # Move .rst files to the html folder
    rst_o = Path(TEMP_DIR + "/doctool_rst")
    for rst in rst_o.glob("*.rst"):
        rst.move(html_o / "source" / rst.name)

    # Run sphinx-build - output to real output
    print_i("Generating sphinx output.")
    subprocess.run(["sphinx-build", "-M", "html", (html_o / "source"), (html_o / "build")])


    # Ask to save information to the config



def prompt(message: String) -> String:
    return input(f"[{Fore.YELLOW} Setup {Style.RESET_ALL}] " + message).strip()


def print_success(message: String) -> None:
    print(f"[{Fore.GREEN} Good {Style.RESET_ALL}] " + message)
    return


def print_i(message: String) -> None:
    print(f"[{Fore.CYAN} Info {Style.RESET_ALL}] " + message)
    return

def print_error(message: String) -> None:
    print(f"[{Fore.RED} Error {Style.RESET_ALL}] " + message)
    return



if __name__ == "__main__":
    main()
