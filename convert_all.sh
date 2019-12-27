rm -f **/*.lua
rm -f **/*.toc
for  class in Warrior Warlock Mage Paladin Priest Rogue Shaman Druid Hunter; do
  for f in *.json; do ruby convert.rb "${f}" "${class}"; done
  cd Guidelime_ClassicWoWdotLive_${class}
  cp Guidelime_ClassicWoWdotLive_${class}.toc.template Guidelime_ClassicWoWdotLive_${class}.toc
  for lua in *.lua; do echo ${lua} >> Guidelime_ClassicWoWdotLive_${class}.toc; done
  cd -
done
