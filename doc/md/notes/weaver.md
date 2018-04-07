------
1. TOC
{:toc}
------
# Weaver

  Our weaver is responsible for creating presentation views from a document.
This is in keeping with Dr. Knuth's original method of literate programming,
where the weave was properly typeset code printed on paper. 


Grimoire intends to support (La)TeX output, and thereby physical printing.
We don't consider it especially important.  Grimoire offers few advantages
over Markdown for those exclusively concerned with prosaic contents, and 
authors who work only with prose have no special motive to adopt it. 


The core use case for our weave is producing views of the Orb files of a 
full ingenium.  Thus our weaves are themselves software, and this may in
turn interact with the original document if desired.


We start by supporting a simple, static view of the original Grimoire
documents.  Thus the very first output we intend to support is just good ol'
Git-Flavored Markdown. 


With this written we actually have a fairly capable system. It can invert a
source tree into the `````orb````` directory, knit a sorcery directory from that,
and produce documentation which GitHub can display natively. 


Add a little shim to Sublime to display Grimoire documents and I'm ready to
start working on the editor and the quipu, and then Lun and Clu. 
