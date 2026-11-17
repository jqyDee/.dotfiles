// output: matti-fischbach-sheetXX.pdf

#import "@local/templates:0.1.0": *

#show: generic.with(
  title: "Title",
  subtitle: "",
  heading_pagebreak: false
)

#set heading(numbering: "1.1")

= Exercise 01
