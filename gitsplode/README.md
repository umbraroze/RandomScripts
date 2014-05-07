
# gitsplode

The `gitsplode.rb` script feebly attempts to exports the entire
history of a single file from a Git repository. "Feebly attempts to",
because *\*ahem\** Git's notion of single file identity *is what it
is*.

This was mostly made to assist me in researching how my writing
projects are proceeding (i.e. *"In (date) my word count was (x)"*),
and I tend to keep those projects in single files as much as possible,
so if your use case diverts too much from that, you'll luck will
probably run out.

The program will spit out each revision in a file that is named after
the commit date, and also spits out an XML summary file
(`summary.xml`) that is pretty much self-explanatory:

    <commitdata>
        <commit>
            <filename>foo.1234_56_78.12_34_56.txt</filename>
            <date unix="123456">Thursday of Human-Readable Date Whenever</date>
            <message>This is a commit message and stuff...</message>
        </commit>
	    <!-- ... -->
	</commitdata>

## Requirements

* Ruby. Dunno what versions. Worked fine on 1.9, seems to run on 2.x
  just fine. It only uses standard library REXML at the moment, but I
  may migrate to Nokogiri at some point, so get yer gems ready.
* Git. Normal Debian junk. Not sure what extras. Requires command line
  calls so I will check out if it can be made to run at all on
  Windows, but I doubt it.


