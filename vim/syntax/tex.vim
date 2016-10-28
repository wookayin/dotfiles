" additional and custom syntax for LaTeX documents

" treat \begin{comment}...\end{comment} region as comment
syn region texComment     start="\\begin{comment}"  end="\\end{comment}\|%stopzone\>"
