# Volatility Memory Forensics Automation Script

A versatile bash script to automate memory forensics using **Volatility 2** and **Volatility 3** frameworks. This tool allows you to run various memory analysis commands on memory dump files, simplifying the process by providing command options based on the selected Volatility version.

## Features

- **Supports both Volatility 2 and Volatility 3**.
- **Automatic version detection** or allows manual entry of the Volatility file path.
- **Profile selection** for Volatility 2 with the ability to reselect profiles.
- A comprehensive list of commands, including `pslist`, `pstree`, `dlllist`, `netscan`, `filescan`, `connscan`, and `malfind`.
- **Color-coded menus** to distinguish between options and commands for easy navigation.
- **Graceful exit** on `Ctrl+C`, allowing clean termination.

## Requirements

- **Python 2** for Volatility 2 support.
- **Volatility 3** should be installed or available in your system's PATH.
- Tested on Linux (Kali), Ubuntu (WSL), and other Linux-based systems.

## Installation

### Volatility 2 Installation

To install **Volatility 2**, follow these steps:

1. **Clone the Volatility 2 repository**:

    git clone https://github.com/volatilityfoundation/volatility.git
  
2. **Install the necessary dependencies** (Python 2 and `distorm3`):

    sudo apt-get install python2 python2-pip
    pip2 install distorm3 yara pycrypto

3. **Navigate to the Volatility 2 directory** and test the installation:

    cd volatility
    python2 vol.py --help

    For more details on Volatility 2, visit the [Volatility 2 repository](https://github.com/volatilityfoundation/volatility).

### Volatility 3 Installation

To install **Volatility 3**, follow these steps:

1. **Clone the Volatility 3 repository**:

    git clone https://github.com/volatilityfoundation/volatility3.git

2. **Install the necessary dependencies** (Python 3 and the required libraries):

    sudo apt-get install python3 python3-pip
    pip3 install -r volatility3/requirements.txt

3. **Navigate to the Volatility 3 directory** and test the installation:

    cd volatility3
    python3 vol.py --help

    For more details on Volatility 3, visit the [Volatility 3 repository](https://github.com/volatilityfoundation/volatility3).

## Running the Script

Once you have Volatility installed, you can run the script from any directory:

sudo bash ./dump_detected.sh

The script will prompt for the necessary file paths and allow you to select between Volatility 2 and 3.

## Usage

Once the script is run, it will prompt you to choose between **Volatility 2** and **Volatility 3**:

Which version of Volatility would you like to use?
1) Volatility 2
2) Volatility 3

### Volatility 2

If Volatility 2 is chosen, the script will automatically run **`imageinfo`** to suggest memory profiles. You can either select a suggested profile or enter one manually.

Example commands for Volatility 2:

1) pslist
2) pstree
3) dlllist
4) netscan
5) filescan
6) connscan
7) malfind
8) Exit

### Volatility 3

Volatility 3 does not require profile selection. You will directly choose from a set of commands, similar to Volatility 2:

Example commands for Volatility 3:

1) pslist
2) pstree
3) dlllist
4) netscan
5) filescan
6) connscan
7) malfind
8) Exit

### Manual Volatility Path Entry

If the script cannot automatically detect the Volatility version, you will be prompted to manually enter the path to `vol.py` for either Volatility 2 or 3. **This input is case-sensitive**:

Please enter the full path to vol.py:
(Note: This input is case-sensitive)
```

### Graceful Exit

You can exit the script at any time by pressing `Ctrl+C`. The script will handle this gracefully and terminate without proceeding to the next step:

Process interrupted by the user. Exiting...

## Output

The output for each command is saved to a text file in the directory of your choosing. Example output files:

- `pslist.txt`
- `dlllist.txt`
- `netscan.txt`

## Commands Supported

### Volatility 2 Commands

- `pslist`: List running processes.
- `pstree`: Show processes in a tree structure.
- `dlllist`: List loaded DLLs for processes.
- `netscan`: Scan for network connections.
- `filescan`: Scan for file objects in memory.
- `connscan`: Scan for connections.
- `malfind`: Detect hidden or injected code.

### Volatility 3 Commands

- `windows.pslist.PsList`: List running processes.
- `windows.pslist.PsTree`: Show processes in a tree structure.
- `windows.dlllist.DllList`: List loaded DLLs for processes.
- `windows.netscan.NetScan`: Scan for network connections.
- `windows.filescan.FileScan`: Scan for file objects in memory.
- `windows.network.ConnScan`: Scan for connections.
- `windows.malfind.Malfind`: Detect hidden or injected code.

## Credits

Created by **Michael Pacheco**.

## License

Unlicensed
