#!/usr/bin/bash
cp merged.tsv merged_bak.tsv
node index.js
node merge-editorial.js
node excel.js
diff -q merged.tsv merged_bak.tsv