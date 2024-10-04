from collections import Counter
from itertools import chain
import re
import os
import time
from tqdm import tqdm


def generate_ngrams(text, n):
    """
    Generates n-grams from a given text.
    """
    tokens = re.findall(r"\w+", text.lower())
    return zip(*[tokens[i:] for i in range(n)])


def slop_score(reference_corpus, min_ngram=4, max_ngram=6):
    """
    Calculates the slop score for a reference corpus.

    Args:
        reference_corpus (list of str): A list of texts used as a reference corpus.
        max_ngram (int): The maximum length of n-grams to consider.

    Returns:
        float: The normalized slop score (higher means more repetitive/common phrases).
    """
    # Create a Counter to store n-grams from the reference corpus
    reference_ngrams = Counter()
    for text in tqdm(
        reference_corpus, desc="Generating n-grams for slop score calculation"
    ):
        for n in range(min_ngram, max_ngram + 1):
            reference_ngrams.update(generate_ngrams(text, n))

    # Calculate the slop score by summing the frequencies of n-grams
    score = sum(count * (count - 1) for count in reference_ngrams.values() if count > 1)

    # Normalize the score by the total number of n-grams
    total_ngrams = sum(reference_ngrams.values())
    if total_ngrams > 0:
        score /= total_ngrams

    return score, reference_ngrams


def monitor_folder(folder_path, top_x=10, min_ngram=4, max_ngram=6):
    """
    Monitors a folder for new text files and performs slop analysis on the entire corpus.

    Args:
        folder_path (str): Path to the folder to monitor.
        top_x (int): Number of top n-grams to display.
        max_ngram (int): Maximum n-gram length to consider.
    """
    processed_files = set()
    reference_corpus = []
    while True:
        # Get list of all text files in the folder
        text_files = [f for f in os.listdir(folder_path) if f.endswith(".txt")]

        # Process new files
        new_files = [f for f in text_files if f not in processed_files]
        for text_file in tqdm(new_files, desc="Processing new files"):
            file_path = os.path.join(folder_path, text_file)
            with open(file_path, "r") as f:
                reference_corpus.extend(f.readlines())

            # Mark file as processed
            processed_files.add(text_file)

        # Perform slop analysis on the entire corpus if new files were added
        if new_files:
            score, reference_ngrams = slop_score(reference_corpus, min_ngram, max_ngram)
            print(f"Slop Score for the entire corpus: {score}")

            # Print interesting statistics
            for n in range(min_ngram, max_ngram + 1):
                ngram_counter = Counter()
                for text in tqdm(reference_corpus, desc=f"Generating {n}-grams"):
                    ngram_counter.update(generate_ngrams(text, n))

                print(f"\nTop {top_x} {n}-grams:")
                for ngram, count in ngram_counter.most_common(top_x):
                    print(f"{' '.join(ngram)} (count: {count})")
                print(f"Total unique {n}-grams: {len(ngram_counter)}")

        break
        # Wait before checking the folder again
        time.sleep(5)


if __name__ == "__main__":
    folder_path = "./xtc-cydonia"  # Replace with the path to your folder
    monitor_folder(folder_path)
