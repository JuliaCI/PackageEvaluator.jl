import os
import markdown

# Loop through all md files
index_fp = open('index.html', 'w')
for filename in os.listdir('.'):
  if filename[-3:] != '.md': continue
  if os.path.isfile(filename):
    print(filename)
    index_fp.write('<a href="' + filename[:-3] + '.html">' + filename[:-3] + 
'</a><br>')
    fp = open(filename, mode='r', encoding='utf-8')
    contents = fp.read()
    fp.close()
    contents = '<html><head><meta charset="utf-8"></head><body>' + markdown.markdown(contents) + '</body></html>'
    fp = open(filename[:-3]+'.html', 'w')
    fp.write(contents)
    fp.close()
index_fp.close()
