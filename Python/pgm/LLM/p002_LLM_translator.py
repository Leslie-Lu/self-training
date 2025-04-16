###############################################################################################
# PROJECT NAME      : Python\pgm\LLM\p002_LLM_translator.py
# DESCRIPTION       : Translate the qmd file to English using LLM
# DATE CREATED      : 2025-04-16
# INPUT             : Any qmd file
# OUTPUT            : Translated English qmd file
# PYTHON VERSION    : 3.13.1
# LIBRARIES         : openai, python-frontmatter, python-dotenv
# INSPIRED BY       : https://github.com/Rico00121/hugo-translator
# AUTHOR            : Zhen Lu
################################################################################################
# DATE MODIFIED     : 2025-04-16
# REASON            : Initial version
################################################################################################

from http import client
import openai
import os
import frontmatter
import sys
from dotenv import load_dotenv

def get_translation(llm_type, messages):
    """
    call llm to get translation
    """
    model= 'gpt-4o' if llm_type== 'openai' else 'deepseek-ai/DeepSeek-R1-Distill-Qwen-32B'
    response= client.chat.completions.create(
        model= model,
        messages= messages,
        stream=False
    )
    return response.choices[0].message.content

def translate_text(text, llm_type):
    """
    translate text to english using llm
    """
    total_length= len(text)
    translated_text= ''

    print(f'Start translating the main text...')
    # translate in chunks to show progress
    chunk_size= 1000
    for i in range(0, total_length, chunk_size):
        chunk= text[i:i+chunk_size]
        translated_text+= get_translation(llm_type,
                                          [
                                            {
                                            'role': 'system', 
                                            'content': 'You are a professional translator. '
                                                        'Translate the following Chinese text into English. '
                                                        'Strictly preserve the original text format in qmd file, including line breaks, indentation, and any special characters for inserting codes. '
                                                        'Do not add, remove, or modify any content. '
                                                        'Only return the translated text without any additional explanation, comments, or extra content.'
                                            },
                                            {
                                            'role': 'user', 
                                            'content': chunk
                                            }
                                          ]
                                         )
        progress= min((i+chunk_size)/total_length*100, 100)
        print(f'Tranlation progress: {progress: .2f}%')
    
    return translated_text

def translate_title(text, llm_type):
    """
    translate title to english using llm
    """
    print(f'Start translating the title...')
    translated_title= get_translation(llm_type,
                                      [
                                        {
                                        'role': 'system', 
                                        'content': 'You are a professional translator. '
                                                   'Translate the following Chinese text into English. '
                                                   'Strictly preserve the original text format in qmd file, including line breaks, indentation, and any special characters for inserting codes. '
                                                   'Do not add, remove, or modify any content. '
                                                   'Only return the translated text without any additional explanation, comments, or extra content.'
                                        },
                                        {
                                        'role': 'user', 
                                        'content': text
                                        }
                                      ]
                                     )
    return translated_title

import frontmatter

def process_post_of_qmd(file_path, llm_type):
    """
    Process a QMD file:
    1. Load the QMD file.
    2. Translate the title and content to English using LLM.
    3. Save the translated content to a new QMD file.
    """
    try:
        # Load the QMD file
        with open(file_path, 'r', encoding='utf-8') as f:
            post = frontmatter.load(f)

        # Get the title and content of the post
        title = post.metadata.get('title', 'Untitled')
        content = post.content

        # Translate the title and content
        en_title = translate_title(title, llm_type)
        en_content = translate_text(content, llm_type)

        # Prepare metadata for the translated post
        en_metadata = post.metadata.copy()
        en_metadata['title'] = en_title

        # Create a new post with translated content
        en_post = frontmatter.Post(content=en_content, **en_metadata)

        # Save the translated post to a new file
        en_file_path = file_path.replace('.qmd', '_en.qmd')
        with open(en_file_path, "w", encoding="utf-8") as f:
            f.write(frontmatter.dumps(en_post))

        print(f'Successfully translated the post to {en_file_path}')
    except Exception as e:
        print(f"Error processing the file {file_path}: {e}")


if __name__ == '__main__':
    # check the file path
    file_path= 'index.qmd'
    if not os.path.exists(file_path):
        print(f'The file {file_path} does not exist.')
        sys.exit(1)

    # check the qmd file
    if not file_path.endswith('.qmd'):
        print(f'The file {file_path} is not a qmd file.')
        sys.exit(1)

    # get the llm type, default is deepseek
    llm_type= 'deepseek-ai/DeepSeek-R1-Distill-Qwen-32B'
    if llm_type not in ['openai', 'deepseek-ai/DeepSeek-R1-Distill-Qwen-32B']:
        print(f'The llm type {llm_type} is not supported.')
        sys.exit(1)
    
    # load the env file
    load_dotenv('Python/materials/.env', override= True)
    if not os.path.exists('Python/materials/.env'):
        print(f'The file .env does not exist.')
        sys.exit(1)
    if not os.getenv('OPENAI_API_KEY'):
        print(f'The OPENAI_API_KEY is not set.')
        sys.exit(1)
    
    client= None
    if llm_type== 'openai':
        client= openai.OpenAI(api_key= os.getenv('OPENAI_API_KEY'))
        print('Using OpenAI to translate the post...')
    else:
        client= openai.OpenAI(
            api_key= os.getenv('OPENAI_API_KEY'),
            base_url= os.getenv('DEEPSEEK_API_URL')
        )
        print('Using DeepSeek to translate the post...')
    
    process_post_of_qmd(file_path, llm_type)
    print('All done!')
