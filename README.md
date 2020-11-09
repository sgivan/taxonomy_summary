# taxonomy_summary
Script to summarize the taxonomy content of a list of NCBI gene ID's

Use the -h flag with taxonomy_summary.pl to see the help menu.

## Typical Usage
```
$ bin/taxonomy_summary.pl --help

    Input file should be a list of NCBI sequence ID's, one per line.

    "debug"     =>  $debug,
    "verbose"   =>  $verbose,
    "help"      =>  $help,
    "infile:s"    =>  $infile,
    "outfile:s" =>  $outfile,
    "class"     =>  1 term
    "order"     =>  2 terms
    "family"    =>  3 terms
    "genus"     =>  4 terms, but usually doesn't work -- use --species
    "species"   =>  list taxonomy terms to the species level
    "taxmap"    =>  print a table of gene ID -> taxonomy
    "seq2tax"  =>  print table of sequence names -> taxonomy
    "dna"       =>  input list contains NCBI DNA ID's instead of protein ID's
```

To run, `taxonomy_summary.pl` requires:

1. An input file of NCBI accession numbers, one per line. There is an example file called `idlist.txt` in the `test` directory.
2. If the input file contains accession numbers for DNA sequences, use the `--dna` flag.

A typical invocation of `taxonomy_summary.pl` looks like this:

`taxonomy_summary.pl --infile test/idlist.txt --dna --taxmap`

```
[11/09/20 14:27:40] submit taxonomy_summary/$ bin/taxonomy_summary.pl --infile test/idlist.txt --dna --taxmap
20      Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Hominidae; Homo; Homo sapiens
15      Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Artiodactyla; Ruminantia; Pecora; Bovidae; Caprinae; Ovis; Ovis canadensis canadensis
6       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Carnivora; Feliformia; Felidae; Felinae; Felis; Felis catus
2       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Carnivora; Caniformia; Canidae; Canis; Canis lupus familiaris
2       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Perissodactyla; Equidae; Equus; Equus caballus
1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Cercopithecidae; Cercopithecinae; Macaca; Macaca mulatta
1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Carnivora; Caniformia; Ursidae; Ailuropoda; Ailuropoda melanoleuca
1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Carnivora; Caniformia; Ursidae; Ursus; Ursus maritimus
1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Cercopithecidae; Cercopithecinae; Chlorocebus; Chlorocebus sabaeus
1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Cetartiodactyla; Cetacea; Mysticeti; Balaenopteridae; Balaenoptera; Balaenoptera acutorostrata scammoni
```

And, there will be an output file called `taxmap.txt` that looks like this:
```
[11/09/20 14:29:56] submit taxonomy_summary/$ head taxmap.txt
CP011900.1      1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Artiodactyla; Ruminantia; Pecora; Bovidae; Caprinae; Ovis; Ovis canadensis canadensis
AC112228.3      1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Hominidae; Homo; Homo sapiens
EU153401.1      1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Carnivora; Feliformia; Felidae; Felinae; Felis; Felis catus
CP011888.1      14      Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Artiodactyla; Ruminantia; Pecora; Bovidae; Caprinae; Ovis; Ovis canadensis canadensis
AL118522.32     1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Hominidae; Homo; Homo sapiens
AC198673.7      1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Cercopithecidae; Cercopithecinae; Macaca; Macaca mulatta
AC234646.1      1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Carnivora; Feliformia; Felidae; Felinae; Felis; Felis catus
AY731378.1      1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Perissodactyla; Equidae; Equus; Equus caballus
AC226107.3      1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Euarchontoglires; Primates; Haplorrhini; Catarrhini; Hominidae; Homo; Homo sapiens
XM_008704889.1  1       Eukaryota; Metazoa; Chordata; Craniata; Vertebrata; Euteleostomi; Mammalia; Eutheria; Laurasiatheria; Carnivora; Caniformia; Ursidae; Ursus; Ursus maritimus
```

The columns of the taxmap file are:

1. Accession number
2. Number occurrences of accession number in input list
3. Semicolon-delimited taxonomy list

## Notes

1. In the id file, there can be duplicate accession numbers. A tally of each accession number will be in the taxmap output file.
2. `test/idlist.txt` contains accession numbers for DNA sequences, so be sure to use the `--dna` flag when you run `taxonomy_summary.pl`
