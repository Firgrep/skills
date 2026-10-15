#!/usr/bin/env bash
# Validate a socratic-grill SPEC yaml against the layout in SKILL.md.
# Pure bash + POSIX awk: no yq/python needed. Relies on the fixed layout the
# skill emits (2-space indent, block-style lists), not on a general YAML parser.
#
# Usage: validate_spec.sh <path/to/SPEC_name.yaml>
# Exit:  0 valid, 1 validation errors (printed as file:line: message), 2 usage error
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $(basename "$0") <spec.yaml>" >&2
  exit 2
fi
if [[ ! -f "$1" ]]; then
  echo "error: file not found: $1" >&2
  exit 2
fi

awk -v file="$1" -v base="$(basename "$1")" '
function errat(line, msg) { printf "%s:%d: %s\n", file, line, msg; errors++ }
function indent(s) { match(s, /^ */); return RLENGTH }
function unq(v,   f, l) {
  sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v)
  f = substr(v, 1, 1); l = substr(v, length(v), 1)
  if (length(v) >= 2 && f == l && (f == "\"" || f == q)) v = substr(v, 2, length(v) - 2)
  return v
}
# value after "key:" or "- key:" on a line, comment and quotes stripped
function val(s) {
  sub(/^[[:space:]]*(-[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*:/, "", s)
  sub(/[[:space:]]+#.*$/, "", s)
  return unq(s)
}
# list item text after "- "
function itemval(s) {
  sub(/^[[:space:]]*-[[:space:]]*/, "", s)
  sub(/[[:space:]]+#.*$/, "", s)
  return unq(s)
}
function placeholder(v, line, what) {
  if (v ~ /^<.*>$/ || v ~ /\{\{.*\}\}/) errat(line, what ": unfilled template placeholder: " v)
}
function need(k) {
  if (!(k in f)) errat(iline, id ": missing required field \"" k "\"")
  else if (f[k] == "") errat(fl[k], id ": field \"" k "\" is empty")
}
function needlist(k) {
  if (cnt[k] < 1) errat(iline, id ": \"" k "\" must contain at least one item")
}
function flush() {
  if (kind == "") return
  if (kind == "outcome") {
    nout++
    if (id !~ /^OUT-[0-9]+$/) errat(iline, "outcome id \"" id "\" must match OUT-<n>")
    need("description"); need("metric"); need("validation")
  } else if (kind == "accepted") {
    if (id !~ /^DEC-[0-9]+$/) errat(iline, "accepted decision id \"" id "\" must match DEC-<n>")
    need("summary")
  } else if (kind == "rejected") {
    if (id !~ /^DEC-R[0-9]+$/) errat(iline, "rejected decision id \"" id "\" must match DEC-R<n>")
    need("summary"); need("reason")
  } else if (kind == "ruleset") {
    nrule++
    if (id !~ /^RULESET-[0-9]+$/) errat(iline, "ruleset id \"" id "\" must match RULESET-<n>")
    needlist("scenarios"); needlist("rules")
  }
  if (id in seen) errat(iline, "duplicate id " id " (first used on line " seen[id] ")")
  else seen[id] = iline
  kind = ""; curlist = ""
  delete f; delete fl; delete cnt
}
BEGIN { q = sprintf("%c", 39) }

/^[[:space:]]*(#.*)?$/ { next }                       # blank / comment lines
/\t/ { errat(NR, "tab character found; use spaces for indentation") }

/^[A-Za-z_][A-Za-z0-9_]*:/ {                          # top-level key
  flush()
  key = $0; sub(/:.*$/, "", key)
  top[key] = NR; section = key; sub_ = ""
  if (key == "spec_name") { specname = val($0); specline = NR }
  if (key == "status")    { status = val($0); statusline = NR }
  next
}

indent($0) == 2 && /^  [A-Za-z_][A-Za-z0-9_]*:/ {    # second-level key
  flush()
  key = $0; sub(/^  /, "", key); sub(/:.*$/, "", key)
  sub_ = key
  if (section == "business_case" && key == "summary") { bcsummary = val($0); bcsummaryline = NR }
  if (section == "decisions") {
    if (key != "accepted" && key != "rejected") errat(NR, "unknown key \"" key "\" under decisions (expected accepted/rejected)")
    else dsub[key] = NR
  }
  next
}

/^[[:space:]]*-[[:space:]]+id:/ {                      # start of an item
  flush()
  if (section == "business_case" && sub_ == "outcomes") kind = "outcome"
  else if (section == "decisions" && sub_ == "accepted") kind = "accepted"
  else if (section == "decisions" && sub_ == "rejected") kind = "rejected"
  else if (section == "requirements") kind = "ruleset"
  else { errat(NR, "unexpected item outside outcomes/accepted/rejected/requirements"); next }
  id = val($0); iline = NR; fi = indent($0) + 2
  if (id == "") errat(NR, "item has an empty id")
  placeholder(id, NR, "id")
  next
}

kind != "" {
  if (indent($0) == fi && /^ *[A-Za-z_][A-Za-z0-9_]*:/) {
    key = $0; sub(/^ */, "", key); sub(/:.*$/, "", key)
    v = val($0); curlist = ""
    if (key == "scenarios" || key == "rules") {
      curlist = key
      cnt[key] = (v == "" ) ? 0 : ((v == "[]") ? 0 : 1)
    } else {
      f[key] = v; fl[key] = NR
      placeholder(v, NR, id ": " key)
    }
  } else if (curlist != "" && /^[[:space:]]*-[[:space:]]/) {
    v = itemval($0)
    if (v == "") errat(NR, id ": empty " curlist " item")
    else { cnt[curlist]++; placeholder(v, NR, id ": " curlist " item") }
  }
}

END {
  flush()
  n = split("spec_name status business_case decisions requirements", req, " ")
  for (i = 1; i <= n; i++)
    if (!(req[i] in top)) errat(1, "missing top-level key \"" req[i] "\"")

  if (("spec_name" in top) && specname == "") errat(specline, "spec_name is empty")
  placeholder(specname, specline, "spec_name")
  if (base ~ /^SPEC_.*\.yaml$/ && specname != "") {
    expect = substr(base, 6, length(base) - 10)
    if (expect != specname) errat(specline, "spec_name \"" specname "\" does not match filename (expected SPEC_" specname ".yaml)")
  }
  if (("status" in top) && status !~ /^(DRAFT|CONFIRMED|SUPERSEDED)$/)
    errat(statusline, "status \"" status "\" must be DRAFT, CONFIRMED or SUPERSEDED")

  if ("business_case" in top) {
    if (bcsummary == "") errat(top["business_case"], "business_case.summary is missing or empty")
    placeholder(bcsummary, bcsummaryline, "business_case.summary")
    if (nout < 1) errat(top["business_case"], "business_case.outcomes needs at least one outcome")
  }
  if ("decisions" in top) {
    if (!("accepted" in dsub)) errat(top["decisions"], "decisions.accepted is missing")
    if (!("rejected" in dsub)) errat(top["decisions"], "decisions.rejected is missing")
  }
  if (("requirements" in top) && nrule < 1) errat(top["requirements"], "requirements needs at least one ruleset")

  if (errors > 0) { printf "%d error(s) in %s\n", errors, file; exit 1 }
  printf "OK: %s (%d outcomes, %d rulesets)\n", file, nout, nrule
}
' "$1"
