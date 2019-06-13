#!/bin/bash
asciidoctor docs/index.adoc -o dist/index.html
asciidoctor-pdf docs/index.adoc -o dist/index.pdf