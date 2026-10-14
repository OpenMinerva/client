
print_info() {
    local color='\e[36m'
    local reset='\e[0m'
    printf "[%b%s%b] %s\n" "$color" "status" "$reset" "$1"
}

# TODO: Check to see if we need to create the venv.
print_info "Creating virtual environment."

if [ ! -d ".venv" ]; then
	python3 -m venv .venv
else
	print_info "Using existing virtual environment."
fi

print_info "Activating environment."
source .venv/bin/activate

print_info "Installing requirements."
pip install -r requirements.txt

print_info "Executing python script."
echo " --- "
python doctool.py

