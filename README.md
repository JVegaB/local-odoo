
### Dependencies:

- https://cli.github.com/ (Used to clone private repositories PR. For ex to apply enterprise patches).
- https://github.com/pyenv/pyenv (To install python dependencies).

### Prerequisites:

- Run `gh auth login`.
- Change into your correct Python version using `pyenv install {version}; pyenv global {version}`.

### Steps

- Change dir into a clean directory, to create your new workspace.
- Update the variables.sh file to your preferences.
- Give `./main.sh` execution permisions with `chmod +x ./main.sh`.
- Run the `./main.sh`.sh file.
- When finalized, copy the last output, to your odoo config file (saved in the root dir in the workspace just created), in the addons path section.
