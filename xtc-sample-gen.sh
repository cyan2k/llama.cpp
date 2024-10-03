#!/bin/bash

xtc_threshold_list="0.1,0.2,0.3,0.4,0.9"  # Example list of xtc_threshold values
xtc_probability_list="0.5,0.7,1.0"  # Example list of xtc_probability values
xtc_chain=false 
tokens=4096
seed=42
temp=1.0
min_p=0.1
top_p=0.95
model="gemma-2-Ifable-9B.Q8_0.gguf"
prompt="Science Fiction: The Last Transmission - Write a story that takes place entirely within a spaceship's cockpit as the sole surviving crew member attempts to send a final message back to Earth before the ship's power runs out. The story should explore themes of isolation, sacrifice, and the importance of human connection in the face of adversity. 800-1000 words."
outputfolder="xtc-gemma"  # Output folder for results

write_prompt_file() {
    local output_file=$1
    cat <<EOL > "${output_file}/prompt.txt"
Model: ${model}
Prompt: ${prompt}
Tokens: ${tokens}
Seed: ${seed}
Temperature: ${temp}
Min P: ${min_p}
Top P: ${top_p}
XTC Threshold: ${xtc_threshold_list}
XTC Probability: ${xtc_probability_list}
XTC Chain: ${xtc_chain}
EOL
}

# Create output folder if it doesn't exist
if [ ! -d "$outputfolder" ]; then
    mkdir -p "$outputfolder"
    echo "Created output folder: $outputfolder"
fi

write_prompt_file "${outputfolder}"

# Single run with xtc_chain=false, xtc_probability=0, xtc_threshold=0
echo "Starting preliminary run: xtc_chain=false, xtc_probability=0, xtc_threshold=0"
output_file="${outputfolder}/output_${model}__s_${seed}_preliminary_run.txt"
./llama-cli -m ${model} -p "${prompt}" -n ${tokens} -c ${tokens} -s ${seed} --temp ${temp} --top-p ${top_p} --min-p ${min_p} --xtc-threshold 0 --xtc-probability 0 | tee "${output_file}"

# Convert comma-separated lists into arrays
IFS=',' read -r -a xtc_threshold_array <<< "$xtc_threshold_list"
IFS=',' read -r -a xtc_probability_array <<< "$xtc_probability_list"

# Calculate the total number of combinations
total_combinations=$(( ${#xtc_threshold_array[@]} * ${#xtc_probability_array[@]} * ${#seed_array[@]} ))
current_combination=1  # Start at the first combination

# Loop over every combination of xtc_threshold, xtc_probability, and seed
for xtc_threshold in "${xtc_threshold_array[@]}"; do
    for xtc_probability in "${xtc_probability_array[@]}"; do

            # Print the progress message
            echo "Processing combination ${current_combination} of ${total_combinations}: xtc_threshold=${xtc_threshold}, xtc_probability=${xtc_probability}, seed=${seed}"

            # Set xtc_chain flag and chain_filename based on xtc_chain value
            if [ "$xtc_chain" = true ]; then
                chain_flag="--xtc-chain"
                chain_filename="_xtcchain"
            else
                chain_flag=""
                chain_filename=""
            fi

            # Define the output file name
            output_file="${outputfolder}/output_${model}_t_${xtc_threshold}_p_${xtc_probability}${chain_filename}_s_${seed}.txt"

            # Run the command, save output to the file, and display it in the CLI
            ./llama-cli -m ${model} -p "${prompt}" -n ${tokens} -c ${tokens} -s ${seed} --temp ${temp} --top-p ${top_p} --min-p ${min_p} --xtc-threshold ${xtc_threshold} --xtc-probability ${xtc_probability} ${chain_flag} | tee "${output_file}"

            # Increment the combination counter
            current_combination=$(( current_combination + 1 ))

    done
done