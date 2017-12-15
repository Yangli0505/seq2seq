#!/usr/bin/env bash

data_dir=data/IWSLT14
mkdir -p ${data_dir}

config/IWSLT14/prepare-mixer.sh
mv prep/*.{en,de} ${data_dir}
rename s/.de-en// ${data_dir}/*
rename s/valid/dev/ ${data_dir}/*

scripts/prepare-data.py ${data_dir}/train de en ${data_dir} --mode vocab --vocab-size 0 --min-count 3

rm -rf prep orig

cat ${data_dir}/train.{de,en} > ${data_dir}/train.concat
scripts/learn_bpe.py -i ${data_dir}/train.concat -o ${data_dir}/bpe.joint.en -s 30000
cp ${data_dir}/bpe.joint.en ${data_dir}/bpe.joint.de

scripts/prepare-data.py ${data_dir}/train concat ${data_dir} --mode vocab --vocab-size 0 --character-level
mv ${data_dir}/vocab.concat ${data_dir}/vocab.char.en
cp ${data_dir}/vocab.char.en ${data_dir}/vocab.char.de

scripts/prepare-data.py ${data_dir}/train de en ${data_dir} --subwords --bpe-path ${data_dir}/bpe.joint \
--output train.jsub --dev-prefix dev.jsub --test-prefix test.jsub --test-corpus ${data_dir}/test \
--dev-corpus ${data_dir}/dev --vocab-size 0 --vocab-prefix vocab.jsub --no-tokenize

cp ${data_dir}/train.en ${data_dir}/train.char.en
cp ${data_dir}/train.de ${data_dir}/train.char.de
cp ${data_dir}/dev.en ${data_dir}/dev.char.en
cp ${data_dir}/dev.de ${data_dir}/dev.char.de

cat ${data_dir}/train.jsub.{en,de} > ${data_dir}/train.jsub.concat
cp ${data_dir}/bpe.joint.en ${data_dir}/bpe.concat

scripts/prepare-data.py ${data_dir}/train.jsub concat ${data_dir} --subwords --bpe-path ${data_dir}/bpe \
--vocab-size 0 --vocab-prefix vocab.jsub --mode vocab


wget http://opus.nlpl.eu/download/OpenSubtitles2018/mono/OpenSubtitles2018.de.gz -O ${data_dir}
wget http://opus.nlpl.eu/download/TED2013/mono/TED2013.en.gz -O ${data_dir}

gunzip ${data_dir}/TED2013.en.gz --stdout | scripts/lowercase.perl > ${data_dir}/TED.en
gunzip ${data_dir}/OpenSubtitles2018.de.gz --stdout  | scripts/lowercase.perl > ${data_dir}/OpenSubtitles.de

python3 -c "lines = set(list(open('${data_dir}/dev.en')) + list(open('${data_dir}/test.en'))); print(''.join(line for line in open('${data_dir}/TED.en') if line not in lines))" > ${data_dir}/TED.filtered.en
python3 -c "lines = set(list(open('${data_dir}/dev.de')) + list(open('${data_dir}/test.de'))); print(''.join(line for line in open('${data_dir}/OpenSubtitles.de') if line not in lines))" > ${data_dir}/OpenSubtitles.filtered.de
mv ${data_dir}/TED.filtered.en ${data_dir}/TED.en
mv ${data_dir}/OpenSubtitles.filtered.de ${data_dir}/OpenSubtitles.de

scripts/apply_bpe.py -i ${data_dir}/TED.en -o ${data_dir}/TED.jsub.en -c ${data_dir}/bpe.joint.en
scripts/apply_bpe.py -i ${data_dir}/OpenSubtitles.de -o ${data_dir}/OpenSubtitles.jsub.de -c ${data_dir}/bpe.joint.de
