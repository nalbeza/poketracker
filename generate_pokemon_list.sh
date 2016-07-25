#!/bin/sh

TMP_FILE='tmplist.json'
OUTPUT_FILE='pokemon-list.json'

ruby fetch_pokemons.rb $TMP_FILE
if [[ $? -eq 0 ]]
then
  python -m 'json.tool' < $TMP_FILE > $OUTPUT_FILE
  rm -f $TMP_FILE
fi
