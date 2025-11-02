# Create a new LaTeX file from a template
texnew() {
local fname="$1"
if [[ -z "$fname" ]]; then
    printf "New LaTeX filename (without .tex): "
    IFS= read -r fname
fi
if [[ -z "$fname" ]]; then
    echo "Aborted: empty filename."
    return 1
fi

# Ensure .tex extension

[[ "$fname" != *.tex ]] && fname="${fname}.tex"

# Confirm overwrite

if [[ -e "$fname" ]]; then
    if ! read -q "REPLY?File '$fname' exists. Overwrite? [y/N] "; then
      echo
      echo "Aborted."
      return 1
    fi
    echo
fi

# Write template

cat > "$fname" <<'EOF'
% !TeX TS-program = pdflatex
\documentclass{article}
\usepackage{amsmath,hyperref}
\title{VimTeX Test} \author{You}
\begin{document}
\maketitle

Hello, \LaTeX{} from VimTeX!

\section{Equation}
\begin{equation}\label{eq:test}
  E = mc^2
\end{equation}

See Eq.~\ref{eq:test}. Visit \href{https://example.com}{a link}.
\end{document}
EOF

echo "Created '$fname'. Open with: nvim '$fname'"
}
