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
echo " |  | |/ _ \ __/ _ \/ __| __| \ \ / / _ \ "
echo " | |__| |  __/ ||  __/ (__| |_| |\ V /  __/ "
echo " |_____/ \___|\__\___|\___|\__|_| \_/ \___| "
echo "                                            "
echo -e "\e[33mCreator: The404treatment\e[0m"  # Yellow text

# Trap to handle Ctrl+C interruption
trap ctrl_c INT

# Function to handle Ctrl+C (SIGINT)
ctrl_c() {
  echo -e "\n\e[31mProcess interrupted by the user. Exiting...\e[0m"
  exit 1  # Immediately exit the script when interrupted
}

# Available commands for Volatility 2 in the command options menu
volatility_2_commands=(
    "pslist" "pstree" "dlllist" "malfind" "connscan" "filescan" 
    "hivelist" "hashdump" "sockscan" "psscan" "handles" "modules"
    "getsids" "vadinfo" "cmdscan" "ldrmodules" "procdump"
)

# Available commands for Volatility 3 (Windows) in the command options menu
volatility_3_commands_windows=(
    "windows.pslist.PsList" "windows.pstree.PsTree" "windows.dlllist.DllList"
    "windows.malfind.Malfind" "windows.network.ConnScan" "windows.filescan.FileScan"
    "windows.registry.HiveList" "windows.hashdump.Hashdump" "windows.sockets.SockScan"
    "windows.psscan.PsScan" "windows.handles.Handles" "windows.modules.Modules"
    "windows.getsids.GetSIDs" "windows.vadinfo.VadInfo" "windows.cmdscan.CmdScan"
    "windows.procdump.ProcDump"
)

# Expanded command list for manual command input (Volatility 2)
volatility_2_manual_commands=(
    "pslist" "pstree" "dlllist" "malfind" "connscan" "filescan" 
    "hivelist" "hashdump" "sockscan" "psscan" "handles" "modules"
    "getsids" "vadinfo" "cmdscan" "ldrmodules" "procdump" "svcscan"
    "envars" "iehistory" "netscan" "mftparser" "shimcache" "yarascan"
    "memdump" "malfind" "procdump" "dumpfiles" "timeliner"
)

# Expanded command list for manual command input (Volatility 3 - Windows)
volatility_3_manual_commands_windows=(
    "windows.pslist.PsList" "windows.pstree.PsTree" "windows.dlllist.DllList"
    "windows.malfind.Malfind" "windows.network.ConnScan" "windows.filescan.FileScan"
    "windows.registry.HiveList" "windows.hashdump.Hashdump" "windows.sockets.SockScan"
    "windows.psscan.PsScan" "windows.handles.Handles" "windows.modules.Modules"
    "windows.getsids.GetSIDs" "windows.vadinfo.VadInfo" "windows.cmdscan.CmdScan"
    "windows.procdump.ProcDump" "windows.memdump.MemDump" "windows.shimcache.ShimCache"
    "windows.netscan.NetScan" "windows.envars.Envars" "windows.yarascan.YaraScan"
    "windows.timeliner.Timeliner" "windows.registry.Shimcache"
)

# Function to search for vol.py using locate or find
search_for_vol_py() {
  local version=$1  # Volatility version (2 or 3)

  # Try using locate first (faster)
  VOL_PATH=$(locate vol.py | grep -i "volatility${version}" | head -n 1)

  if [ -z "$VOL_PATH" ];then
    # If locate fails, fall back on find (slower)
    VOL_PATH=$(find /usr /opt $HOME -name vol.py 2>/dev/null | grep -i "volatility${version}" | head -n 1)
  fi

  echo "$VOL_PATH"
}

# Function to handle manual file path input for Volatility 2 or 3
manual_input_volatility_path() {
  while true; do
    echo -e "\e[31m(Note: The path is case-sensitive. e.g., /path/to/Volatility2/vol.py)\e[0m"
    read -p "Please enter the full path to vol.py: " VOL_PATH
    if [ -f "$VOL_PATH" ];then
      echo "File found: $VOL_PATH"
      VOL_CMD="python2 $VOL_PATH"
      break
    else
      echo "File not found. Please try again."
    fi
  done
}

# ------------------ MAIN LOGIC FOR DETECTION AND FALLBACK ------------------ #

# Ask the user to choose which version of Volatility to use
while true; do
  echo "Which version of Volatility would you like to use?"
  echo "1) Volatility 2"
  echo "2) Volatility 3"
  read -p "Please enter 1 or 2: " VOL_VERSION

  if [ "$VOL_VERSION" == "1" ];then
    # Volatility 2 detection
    VOL_PATH=$(search_for_vol_py 2)
    if [ -n "$VOL_PATH" ];then
      echo -e "\e[32mFound vol.py at: $VOL_PATH\e[0m"
      read -p "Do you want to use this path? (y/n): " USE_FOUND_PATH
      if [ "$USE_FOUND_PATH" == "y" ] || [ "$USE_FOUND_PATH" == "Y" ];then
        VOL_CMD="python2 $VOL_PATH"
      else
        manual_input_volatility_path
      fi
    else
      echo -e "\e[31mvol.py not found. Please enter the path manually.\e[0m"
      manual_input_volatility_path
    fi
    USE_PROFILE=true
    break

  elif [ "$VOL_VERSION" == "2" ];then
    # Volatility 3 detection
    VOL_CMD="vol"
    USE_PROFILE=false
    echo "Using Volatility 3."
    break

  else
    echo "Invalid input. Please choose 1 or 2."
  fi
done

# ------------------ COMMAND OPTIONS SECTION ------------------ #
# Ensure the memory file and output directory are only asked for once, not multiple times
MEMORY_FILE=""
OUTPUT_DIR=""
PROFILE=""

while true; do
  if [ -z "$MEMORY_FILE" ];then
    read -p "Please enter the full path of the memory file: " MEMORY_FILE
    if [ ! -f "$MEMORY_FILE" ];then
      echo "Error: Memory file not found! Please enter a valid path."
      MEMORY_FILE=""
      continue
    fi
  fi

  if [ -z "$OUTPUT_DIR" ];then
    read -p "Please enter the directory where you want to save the output files: " OUTPUT_DIR
    if [ ! -d "$OUTPUT_DIR" ];then
      echo "Directory does not exist! Please create it or specify an existing directory."
      OUTPUT_DIR=""
      continue
    fi
  fi

  # Profile selection loop for Volatility 2 (Volatility 3 doesn't need profile)
  if [ "$USE_PROFILE" == true ] && [ -z "$PROFILE" ];then
    while true; do
      # Ask the user to input the suggested profile or press Enter to skip
      echo "Please input the name of the suggested profile (e.g., Win7SP1x64 or WinXPSP2x86) or press Enter to run imageinfo:"
      read -p "Profile name: " PROFILE

      # If no profile is entered, run imageinfo to suggest profiles
      if [ -z "$PROFILE" ];then
        echo "Running imageinfo to suggest profiles..."
        $VOL_CMD -f "$MEMORY_FILE" imageinfo > imageinfo_output.txt
        if [ $? -eq 1 ];then
          echo "Process interrupted. Exiting..."
          exit 1
        fi

        # Extract profiles from imageinfo output
        PROFILES=$(grep "Suggested Profile(s)" imageinfo_output.txt | cut -d ':' -f2 | tr ',' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//')
        echo "Available profiles:"
        select PROFILE_NAME in $PROFILES;do
          if [ -n "$PROFILE_NAME" ];then
            echo "You have selected profile: $PROFILE_NAME"
            PROFILE=$PROFILE_NAME
            break
          else
            echo "Invalid selection, please choose again."
          fi
        done
      else
        echo "You have selected profile: $PROFILE"
      fi

      break
    done
  fi

  # Command selection menu
  while true; do
    echo "Available commands:"
    if [ "$USE_PROFILE" == true ];then
      for ((i=0; i<${#volatility_2_commands[@]}; i++));do
        echo -e "\e[31m$((i+1)))\e[0m \e[33m${volatility_2_commands[$i]}\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" --profile=\"$PROFILE\" ${volatility_2_commands[$i]})"
      done
    else
      for ((i=0; i<${#volatility_3_commands_windows[@]}; i++));do
        echo -e "\e[31m$((i+1)))\e[0m \e[33m${volatility_3_commands_windows[$i]}\e[0m ($VOL_CMD -f \"$MEMORY_FILE\" ${volatility_3_commands_windows[$i]})"
      done
    fi
    echo -e "\e[31m$((i+1)))\e[0m Enter manual command"
    echo -e "\e[31m$((i+2)))\e[0m Exit"

    # Command selection
    read -p "Please select a command to run: " COMMAND
    CMD_INDEX=$((COMMAND-1))

    if [ "$USE_PROFILE" == true ] && [ "$CMD_INDEX" -lt "${#volatility_2_commands[@]}" ];then
      OUTPUT_FILE="${OUTPUT_DIR}/${volatility_2_commands[$CMD_INDEX]}.txt"
      $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" "${volatility_2_commands[$CMD_INDEX]}" > "$OUTPUT_FILE"

      # Check if the output file is empty
      if [ ! -s "$OUTPUT_FILE" ];then
        echo -e "\e[31mWarning: The output file is empty. This may be due to an invalid profile or no data found for this command.\e[0m"
        echo "Would you like to try another command or re-enter the profile?"
        echo "1) Re-enter profile"
        echo "2) Select another command"
        read -p "Please enter 1 or 2: " CHOICE
        if [ "$CHOICE" == "1" ];then
          PROFILE=""
          continue
        else
          continue
        fi
      else
        echo "Command output saved to $OUTPUT_FILE"
      fi

    elif [ "$USE_PROFILE" == false ] && [ "$CMD_INDEX" -lt "${#volatility_3_commands_windows[@]}" ];then
      OUTPUT_FILE="${OUTPUT_DIR}/${volatility_3_commands_windows[$CMD_INDEX]}.txt"
      $VOL_CMD -f "$MEMORY_FILE" "${volatility_3_commands_windows[$CMD_INDEX]}" > "$OUTPUT_FILE"

      # Check if the output file is empty
      if [ ! -s "$OUTPUT_FILE" ];then
        echo -e "\e[31mWarning: The output file is empty. This may be due to no data found or an invalid command.\e[0m"
        echo "Would you like to try another command?"
        echo "1) Select another command"
        read -p "Please enter 1: " CHOICE
        continue
      else
        echo "Command output saved to $OUTPUT_FILE"
      fi

    elif [ "$COMMAND" -eq $((i+1)) ];then
      # Manual command handling
      while true; do
        read -p "Please enter the manual command: " MANUAL_CMD

        # Check if the manual command exists in the expanded command list
        if [[ "$USE_PROFILE" == true && ! " ${volatility_2_manual_commands[*]} " =~ " $MANUAL_CMD " ]] || \
           [[ "$USE_PROFILE" == false && ! " ${volatility_3_manual_commands_windows[*]} " =~ " $MANUAL_CMD " ]]; then
          echo -e "\e[31mError: Command '$MANUAL_CMD' not found.\e[0m"
          echo "Here are the available manual commands:"
          if [ "$USE_PROFILE" == true ];then
            printf "%s\n" "${volatility_2_manual_commands[@]}"
          else
            printf "%s\n" "${volatility_3_manual_commands_windows[@]}"
          fi
          echo "Please try entering a valid command."
        else
          OUTPUT_FILE="${OUTPUT_DIR}/${MANUAL_CMD}.txt"  # Name the output file based on the manual command
          if [ "$USE_PROFILE" == true ]; then
            $VOL_CMD -f "$MEMORY_FILE" --profile="$PROFILE" $MANUAL_CMD > "$OUTPUT_FILE"
          else
            $VOL_CMD -f "$MEMORY_FILE" $MANUAL_CMD > "$OUTPUT_FILE"
          fi

          # Check if the output file is empty
          if [ ! -s "$OUTPUT_FILE" ];then
            echo -e "\e[31mWarning: The manual command returned no output.\e[0m"
            echo "Would you like to re-enter the manual command?"
            echo "1) Re-enter command"
            echo "2) Select another command"
            read -p "Please enter 1 or 2: " MANUAL_CHOICE
            if [ "$MANUAL_CHOICE" == "1" ];then
              continue
            else
              break
            fi
          else
            echo "Manual command output saved to $OUTPUT_FILE"
            break
          fi
        fi
      done

    elif [ "$COMMAND" -eq $((i+2)) ];then
      echo "Exiting..."
      exit 0
    else
      echo "Invalid option, please choose again."
    fi
  done
done
