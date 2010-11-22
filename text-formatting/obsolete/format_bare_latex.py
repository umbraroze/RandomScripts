#!/usr/bin/python
# WWWWolf's LaTeX mangler for draft printouts.

import os
import sys
import time
import re
import string
import Cheetah
from Cheetah.Template import Template

sys.path.append(os.path.join(sys.path[0],'python-lib'))
import wordcounts

######################################################################

class Story(Template):
    # None of this shit matters; this whole class is a fucking smokescreen
    # that kind of tries to show how things worked when you're NOT in
    # moonlogic world.
    language = 'english'
    title = 'Untitled story'
    author = 'Unspecified author'
    publication_date = 'unpublished draft'
    creation_date = 'unknown creation date'
    file_name = None
    user_name = None
    word_count = None
    content = None
    def pdfinfo_creation_date(self):
        cd = self.creation_date
        if cd == None or cd == 'unknown creation date':
            return ""
        else:
            cd = cd.translate(string.maketrans('',''),'-: ')
            return "/CreationDate (D:%s)" % cd
class StoryModifiator:
    # The actual "logic" is in this class.
    def __init__(self,story):
        self.story = story
    def pre_process_value(self,value):
        r = value
        # do math mode substitutions
        if value != None:
            r = re.sub(r'(_)',r'$\\\1$',r)
        return r
    def set_by_field(self,field,value):
	value = self.pre_process_value(value)
        if field == 'LANGUAGE':
            story.language = value
        elif field == 'TITLE':
            story.title = value
        elif field == 'AUTHOR':
            story.author = value
        elif field == 'PUBLICATIONDATE':
            story.publication_date = value
        elif field == 'CREATIONDATE':
            story.creation_date = value
        elif field == 'FILENAME':
            story.file_name = value
        elif field == 'USERNAME':
            story.user_name = value
        elif field == 'WORDCOUNT':
            story.word_count = value
    def parse_metadata_entry(self,line):
        m = re.match(r'^(\S+?):\s*(.*)$',line)
        if m == None:
            raise RuntimeError(("'%s' doesn't look like a metadata line."%
                                meta))
        # Allow fields in format "Foo bar: Baz"
        field = re.sub(r'[- ]','',m.group(1).upper())
        value = m.group(2)
        if value == 'NONE':
            value = None
        return (field,value)
    def load_from_meta_file(self,filename):
        f = file(filename,'r')
        metas = map((lambda x: x.strip()), f.readlines())
        f.close()
        metas = filter((lambda x: (not (re.match(r'^$',x)
                                        or re.match(r'^#',x)))), metas)
        for meta in metas:
            (field,value) = self.parse_metadata_entry(meta)
            self.set_by_field(field,value)
    def load_from_latex_file(self,filename):
        f = file(filename,'r')
        l = None
        mode = 0 # Looking for the beginning of the metadata
        while l != '':
            l = f.readline()
            if mode == 0 and re.match(r'%\s*?Metadata:\s*?',l):
                mode = 1 # Reading metadata
            if mode == 1:
                if re.match(r'%\s*?End:\s*?',l):
                    mode = 2 # Metadata has been read
                else:
                    m = re.match(r'%\s*(.*)$',l)
                    (field,value) = self.parse_metadata_entry(m.group(1))
                    self.set_by_field(field,value)
        f.close()
        if mode == 0: # Never found the metadata in the file
            raise RuntimeError("Couldn't find Metadata in the LaTeX file")
    def dump(self):
        print "Language: %s" % story.language
        print "Title: %s" % story.title
        print "Author: %s" % story.author
        print "Publication date: %s" % story.publication_date
        print "Creation date: %s" % story.creation_date
        print "File name: %s" % story.file_name
        print "User name: %s" % story.user_name
        print "Word count: %s" % story.word_count
    # WARNING: ABSOFUCKINGLUTELY HIDEOUS HACK. Please make the class-local
    # version work.
    def update_pdfinfo_creation_date_after_the_fact(self):
        cd = story.creation_date
        if cd == None or cd == 'unknown creation date':
            story.pdfinfo_creation_date = ""
        else:
            cd = cd.translate(string.maketrans('',''),'-: ')
            story.pdfinfo_creation_date = "/CreationDate (D:%s)" % cd

######################################################################

if(len(sys.argv) < 2):
    raise RuntimeError("Usage: %s filename" % sys.argv[0])
filename = os.path.abspath(sys.argv[1])

templatefilename = os.path.abspath(os.path.join(sys.path[0],'templates',
                                                'draft-printout.tex'))
if os.access(templatefilename,os.R_OK) != 1:
    raise RuntimeError("Can't read the template file %s" % templatefilename)

filedir = os.path.dirname(filename)
filebase = re.sub(r'\.tex$','',os.path.basename(filename))
outdir = os.path.abspath(os.path.join(filedir,'out'))
if not os.path.exists(outdir):
    os.mkdir(outdir)
metafilename = os.path.abspath(os.path.join(filedir, "%s.meta" % filebase))
date = time.strftime('%Y%m%d',time.localtime(time.time()))
outputfilename = os.path.abspath(os.path.join(outdir,
                                              '%s-DRAFT-%s.tex' %
                                              (filebase,date)))

# Read template, perform substitutions
#templatefile = file(templatefilename,'r')
#template = templatefile.read()
#templatefile.close()
story = Story(file=templatefilename)
storym = StoryModifiator(story)
story.user_name = os.getlogin() or "Unknown User" # pre-metaload default val
if os.path.exists(metafilename):    
    storym.load_from_meta_file(metafilename)
else:
    metafilename = None
    storym.load_from_latex_file(filename)
story.file_name = storym.pre_process_value(filebase)
story.word_count = str(wordcounts.count_words_latex_file(filename))
storym.update_pdfinfo_creation_date_after_the_fact()

print "\n\nWWWWolf's mysterious LaTeX mangler"
print "=================================="
print
print "Template: %s" % templatefilename
print "Story: %s" % filename
print "Meta: %s" % metafilename
print "Output: %s" % outputfilename
print
storym.dump()
print

# Slurp contentfile in
contentfile = file(filename,'r')
story.content = contentfile.read()
contentfile.close()

# Write to file.
outfile = file(outputfilename,'w')
outfile.write(str(story))
outfile.close()

