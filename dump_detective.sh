#!/bin/bash

# Display the new title with creator's name in yellow
echo "  _____                                     "
echo " |  __ \                                    "
echo " | |  | |_   _ _ __ ___  _ __               "
echo " | |  | | | | | '_ \` _ \| '_ \              "
echo " | |__| | |_| | | | | | | |_) |             "
echo " |_____/ \__,_|_| |_| |_| .__/ _            "
echo " |  __ \     | |        | | | (_)           "
echo " | |  | | ___| |_ ___  _|_| |_ ___   _____  "
echo " |  | | |/ _ \ __/ _ \/ __| __| \ \ / / _ \ "
echo " | |__| |  __/ ||  __/ (__| |_| |\ V /  __/ "
echo " |_____/ \___|\__\___|\___|\__|_| \_/ \___| "
echo "                                            "
echo -e "\e[33mCreator: Michael Pacheco\e[0m"  # Yellow text

# Trap to handle Ctrl+C interruption
trap ctrl_c INT

# Function to handle Ctrl+C (SIGINT)
ctrl_c() {
  echo -e "\n\e[31mProcess interrupted by the user. Exiting...\e[0m"
  exit 1  # Immediately exit the script when interrupted
}

# Function to check if Volatility 3 is installed by running `vol`
check_volatility_3_linux() {
  if command -v vol >/dev/null 2>&1; then
    # Run `vol` and check for "Volatility 3 Framework" in the output
    if vol 2>&1 | grep -q "Volatility 3 Framework"; then
      return 0  # Volatility 3 is installed and detected
    else
      return 1  # Volatility 3 command found but not detected correctly
    fi
  else
    return 1  # Volatility 3 not installed
  fi
}

# Function to check if Volatility 2 is installed by running `python2 vol.py`
check_volatility_2() {
  if command -v python2 >/dev/null 2>&1 && [ -f "./vol.py" ]; then
    return 0  # Volatility 2 is installed and detected
  else
    return 1  # Volatility 2 not installed
  fi
}

# Backend detection: Check if Volatility 2 and 3 are installed
vol2_installed=false
vol3_installed=false

if check_volatility_3_linux; then
  vol3_installed=true
fi

if check_volatility_2; then
  vol2_installed=true
fi

# Function to handle manual file path input for Volatility 2 or 3
manual_input_volatility_path() {
  while true; do
    echo -e "\e[31m(Note: This input is case-sensitive)\e[0m"  # Red text for case sensitivity
    read -p "Please enter the full path to vol.py: " VOL_PATH
    if [ -f "$VOL_PATH" ]; then
      echo "File found: $VOL_PATH"
      if [[ "$VOL_VERSION" == "1" ]]; then
        VOL_CMD="python2 $VOL_PATH"
      else
        VOL_CMD="$VOL_PATH"
      fi
      break
    else
      echo "File not found. Please try again."
    fi
  done
}

# Ask the user to choose which version of Volatility to use
while true; do
  echo "Which version of Volatility would you like to use?"
  echo "1) Volatility 2"
  echo "2) Volatility 3"
  read -p "Please enter 1 or 2: " VOL_VERSION

  if [ "$VOL_VERSION" == "1" ]; then
    if [ "$vol2_installed" == true ]; then
      VOL_CMD="python2 ./vol.py"
      USE_PROFILE=true  # Volatility 2 uses --profile
      echo "Using Volatility 2."
      break
    else
      echo "Volatility 2 was not detected."
      echo "1) Enter file path for vol.py manually"
      echo "2) Go back and select another version"
      read -p "Please enter 1 or 2: " VOL_CHOICE
      if [ "$VOL_CHOICE" == "1" ]; then
        manual_input_volatility_path
        USE_PROFILE=true
        break
      elif [ "$VOL_CHOICE" == "2" ]; then
        continue
      else
        echo "Invalid input."
      fi
    fi
  elif [ "$VOL_VERSION" == "2" ]; then
    if [ "$vol3_installed" == true ]; then
      VOL_CMD="vol"
      USE_PROFILE=false  # Volatility 3 does not use --profile
      echo "Using Volatility 3."
      break
    else
      echo "Volatility 3 was not detected."
      echo "1) Enter file path for vol.py manually"
      echo "2) Go back and select another version"
      read -p "Please enter 1 or 2: " VOL_CHOICE
      if [ "$VOL_CHOICE" == "1" ]; then
        manual_input_volatility_path
        USE_PROFILE=false
        break
      elif [ "$VOL_CHOICE" == "2" ]; then
        continue
      else
        echo "Invalid input."
      fi
    fi
  else
    echo "Invalid input. Please choose 1 or 2."
  fi
done

# Main loop allowing the user to go back to previous steps
while true; do
  # Prompt the user to input the location of the memory file
  read -p "Please enter the full path of the memory file: " MEMORY_FILE

  # Prompt the user to specify the directory for saving output files
  read -p "Please enter the directory where you want to save the output files: " OUTPUT_DIR

  # Ensure the output directory exists
  if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Directory does not exist. Please create it or specify an existing directory."
    continue
  fi

  # Check if the memory file exists
  if [ ! -f "$MEMORY_FILE" ]; then
    echo "Error: File not found!"
    continue
  fi

  # Profile selection loop for Volatility 2 (Volatility 3 doesn't need profile)
  PROFILE=""
  if [ "$USE_PROFILE" == true ]; then
    while true; do
      # Ask the user to input the suggested profile or press Enter to skip
      echo "Please input the name of the suggested profile (e.g., Win7SP1x64 or WinXPSP2x86) or press Enter to run imageinfo:"
      read -p "Profile name: " PROFILE

      # If no profile is entered, run imageinfo to suggest profiles
      if [ -z "$PROFILE" ];then
        echo "Running imageinfo to suggest profiles..."
        
        # Run imageinfo and capture the output to extract profiles
        $VOL_CMD -f "$MEMORY_FILE" imageinfo | tee imageinfo_output.txt
        if [ $? -eq 1 ]; then  # If interrupted, exit the program
          echo "Process interrupted. Exiting..."
          exit 1
        fi
        
        # Extract profiles from the output, only picking the part after the colon
        PROFILES=$(grep "Suggested Profile(s)" imageinfo_output.txt | cut -d ':' -f2 | tr ',' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//')

        echo "Available profiles:"
        select PROFILE in $PROFILES; do
          if [ -n "$PROFILE" ]; then
            echo "You have selected profile: $PROFILE"
            break
          else
            echo "Invalid selection, please choose again."
          fi
        done
      else
        # Confirm profile input
        echo "You have selected profile: $PROFILE"
      fi

      # Now ask if the user wants to proceed with this profile or go back to select another
      while true; do
        echo "1) Proceed with this profile"
        echo "2) Go back and select another profile"
        read -p "Please enter 1 or 2: " PROFILE_CHOICE
        
        if [ "$PROFILE_CHOICE" == "1" ]; then
          echo "Proceeding with profile: $PROFILE"
          break 2  # Proceed with command selection
        elif [ "$PROFILE_CHOICE" == "2" ]; then
          echo "Going back to profile selection..."
          break  # Go back to profile selection
        else
          echo "Invalid input. Please enter 1 or 2."
        fi
      done
    done
  fi

  # Proceed to the command selection menu
  while true; do
    echo "Available commands:"
    if [ "$USE_PROFILE" == true ]; then
      echo -e "\e[31m1)\e[0m \e[33mpslist\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" --profile=\"$PROFILE\" pslist)"
      echo -e "\e[31m2)\e[0m \e[33mpstree\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" --profile=\"$PROFILE\" pstree)"
      echo -e "\e[31m3)\e[0m \e[33mdlllist\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" --profile=\"$PROFILE\" dlllist)"
      echo -e "\e[31m4)\e[0m \e[33mnetscan\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" --profile=\"$PROFILE\" netscan)"
      echo -e "\e[31m5)\e[0m \e[33mfilescan\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" --profile=\"$PROFILE\" filescan)"
      echo -e "\e[31m6)\e[0m \e[33mmftparser\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" --profile=\"$PROFILE\" mftsparser)"
      echo -e "\e[31m7)\e[0m \e[33mmalfind\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" --profile=\"$PROFILE\" malfind)"
      echo -e "\e[31m8)\e[0m Exit"
    else
      echo -e "\e[31m1)\e[0m \e[33mpslist\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" windows.pslist.PsList)"
      echo -e "\e[31m2)\e[0m \e[33mpstree\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" windows.pslist.PsTree)"
      echo -e "\e[31m3)\e[0m \e[33mdlllist\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" windows.dlllist.DllList)"
      echo -e "\e[31m4)\e[0m \e[33mnetscan\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" windows.netscan.NetScan)"
      echo -e "\e[31m5)\e[0m \e[33mfilescan\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" windows.filescan.FileScan)"
      echo -e "\e[31m6)\e[0m \e[33mMFTscan\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" windows.mftscan.MFTScan)"
      echo -e "\e[31m7)\e[0m \e[33mmalfind\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" windows.malfind.Malfind)"
      echo -e "\e[31m8)\e[0m Exit"
    fi
    read -p "Please select a command to run: " COMMAND

    case $COMMAND in
      1)
        OUTPUT_FILE="${OUTPUT_DIR}/pslist.txt"
        if [ "$USE_PROFILE" == true ]; then
          $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" pslist | tee "$OUTPUT_FILE"
        else
          $VOL_CMD -f "$MEMORY_FILE" windows.pslist.PsList | tee "$OUTPUT_FILE"
        fi
        if [ $? -eq 1 ]; then  # If interrupted, exit the program
          echo "Process interrupted. Exiting..."
          exit 1
        fi
        ;;
      2)
        OUTPUT_FILE="${OUTPUT_DIR}/pstree.txt"
        if [ "$USE_PROFILE" == true ]; then
          $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" pstree | tee "$OUTPUT_FILE"
        else
          $VOL_CMD -f "$MEMORY_FILE" windows.pslist.PsTree | tee "$OUTPUT_FILE"
        fi
        if [ $? -eq 1 ]; then  # If interrupted, exit the program
          echo "Process interrupted. Exiting..."
          exit 1
        fi
        ;;
      3)
        OUTPUT_FILE="${OUTPUT_DIR}/dlllist_all.txt"
        if [ "$USE_PROFILE" == true ]; then
          $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" dlllist | tee "$OUTPUT_FILE"
        else
          $VOL_CMD -f "$MEMORY_FILE" windows.dlllist.DllList | tee "$OUTPUT_FILE"
        fi
        if [ $? -eq 1 ]; then  # If interrupted, exit the program
          echo "Process interrupted. Exiting..."
          exit 1
        fi
        ;;
      4)
        OUTPUT_FILE="${OUTPUT_DIR}/netscan.txt"
        if [ "$USE_PROFILE" == true ]; then
          $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" netscan | tee "$OUTPUT_FILE"
        else
          $VOL_CMD -f "$MEMORY_FILE" windows.netscan.NetScan | tee "$OUTPUT_FILE"
        fi
        if [ $? -eq 1 ]; then  # If interrupted, exit the program
          echo "Process interrupted. Exiting..."
          exit 1
        fi
        ;;
      5)
        OUTPUT_FILE="${OUTPUT_DIR}/filescan.txt"
        if [ "$USE_PROFILE" == true ]; then
          $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" filescan | tee "$OUTPUT_FILE"
        else
          $VOL_CMD -f "$MEMORY_FILE" windows.filescan.FileScan | tee "$OUTPUT_FILE"
        fi
        if [ $? -eq 1 ]; then  # If interrupted, exit the program
          echo "Process interrupted. Exiting..."
          exit 1
        fi
        ;;
      6)
        OUTPUT_FILE="${OUTPUT_DIR}/mftscan.txt"
        if [ "$USE_PROFILE" == true ]; then
          $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" mftparser | tee "$OUTPUT_FILE"
        else
          $VOL_CMD -f "$MEMORY_FILE" windows.mftscan.MFTScan | tee "$OUTPUT_FILE"
        fi
        if [ $? -eq 1 ]; then  # If interrupted, exit the program
          echo "Process interrupted. Exiting..."
          exit 1
        fi
        ;;
      7)
        OUTPUT_FILE="${OUTPUT_DIR}/malfind.txt"
        if [ "$USE_PROFILE" == true ]; then
          $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" malfind | tee "$OUTPUT_FILE"
        else
          $VOL_CMD -f "$MEMORY_FILE" windows.malfind.Malfind | tee "$OUTPUT_FILE"
        fi
        if [ $? -eq 1 ]; then  # If interrupted, exit the program
          echo "Process interrupted. Exiting..."
          exit 1
        fi
        ;;
      8)
        echo "Exiting..."
        exit 0
        ;;
      *)
        echo "Invalid option, please choose again."
        ;;
    esac
  done
done


