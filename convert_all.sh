rm -f **/*.lua
rm -f **/*.toc
for f in *.json; do ruby convert.rb "${f}"; done
cp Guidelime_ClassicWoWdotLive.toc.template Guidelime_ClassicWoWdotLive.toc
for lua in *.lua; do echo ${lua} >> Guidelime_ClassicWoWdotLive.toc; done
