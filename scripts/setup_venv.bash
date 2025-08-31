#!/usr/bin/bash

function setup_venv() {
  # Create virtual environment
  /usr/bin/python -m venv env || return

  # Activate the virtual environment
  source env/bin/activate || return

  # Extract import statements and generate requirements.txt
  {
    grep -E '^import (\w+)' *.py | cut -f2 -d ' '
    grep -E '^from (\w+) import' *.py | cut -f2 -d ' '
  } | sort -u >>requirements.txt

  # Check if requirements.txt exists and is not empty
  if [ -f requirements.txt ] && [ -s requirements.txt ]; then
    python -m pip install -r requirements.txt
  else
    echo "No dependencies found or requirements.txt is empty."
  fi
}

alias setup_venv='setup_venv'
