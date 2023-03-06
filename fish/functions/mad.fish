function mad
  madoko --pdf -vv --odir=out $argv
  open out/$argv.pdf
end
