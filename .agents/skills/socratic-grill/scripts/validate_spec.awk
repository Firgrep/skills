# Validates a socratic-grill SPEC yaml. Line-oriented: relies on the fixed
# layout described in SKILL.md rather than parsing YAML in general.
#
# Variables (-v): file  path of the spec, for messages
#                 base  basename of the spec
#
# Parser state
#   section / subkey   current top-level / second-level key
#   kind               item being read: outcome | accepted | rejected | ruleset
#   id, item_line      id and line of the current item
#   field[k], field_line[k]   scalar fields seen in the current item
#   items[k]           entries counted in the current item's scenarios / rules
#   list               list field currently being read

BEGIN { SQ = sprintf("%c", 39) }

# Report a problem as "file:line: message" and count it.
function errat(line, msg) {
  printf "%s:%d: %s\n", file, line, msg
  errors++
}

# Print the error count and exit 1, or the success line and exit 0.
function finish(ok_message) {
  if (errors > 0) {
    printf "%d error(s) in %s\n", errors, file
    exit 1
  }
  print ok_message
}

# Number of leading spaces.
function indent(s) {
  match(s, /^ */)
  return RLENGTH
}

# Trim whitespace and one pair of surrounding quotes.
function unquote(v,   first, last) {
  sub(/^[[:space:]]+/, "", v)
  sub(/[[:space:]]+$/, "", v)
  first = substr(v, 1, 1)
  last = substr(v, length(v), 1)
  if (length(v) >= 2 && first == last && (first == "\"" || first == SQ))
    v = substr(v, 2, length(v) - 2)
  return v
}

# Value of a "key: value" or "- key: value" line (inline comment and quotes removed).
function value_of(s) {
  sub(/^[[:space:]]*(-[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*:/, "", s)
  sub(/[[:space:]]+#.*$/, "", s)
  return unquote(s)
}

# Text of a "- item" line.
function item_of(s) {
  sub(/^[[:space:]]*-[[:space:]]*/, "", s)
  sub(/[[:space:]]+#.*$/, "", s)
  return unquote(s)
}

# Key name of a "key: ..." or "- key: ..." line.
function key_of(s) {
  sub(/^[[:space:]]*(-[[:space:]]+)?/, "", s)
  sub(/:.*$/, "", s)
  return s
}

function is_blank_or_comment(s) { return s ~ /^[[:space:]]*(#.*)?$/ }
function is_key_line(s)         { return s ~ /^ *[A-Za-z_][A-Za-z0-9_]*:/ }
function is_list_item(s)        { return s ~ /^[[:space:]]*-[[:space:]]/ }

# Flag values still shaped like the template, e.g. "<short title>" or {{ name }}.
function check_placeholder(v, line, what) {
  if (v ~ /^<.*>$/ || v ~ /\{\{.*\}\}/)
    errat(line, what ": unfilled template placeholder: " v)
}


function require_field(k) {
  if (!(k in field))     errat(item_line, id ": missing required field \"" k "\"")
  else if (field[k] == "") errat(field_line[k], id ": field \"" k "\" is empty")
}

function require_items(k) {
  if (items[k] < 1) errat(item_line, id ": \"" k "\" must contain at least one item")
}

function check_item() {
  if (kind == "outcome") {
    n_outcomes++
    if (id !~ /^OUT-[0-9]+$/) errat(item_line, "outcome id \"" id "\" must match OUT-<n>")
    require_field("description"); require_field("metric"); require_field("validation")
  } else if (kind == "accepted") {
    if (id !~ /^DEC-[0-9]+$/) errat(item_line, "accepted decision id \"" id "\" must match DEC-<n>")
    require_field("summary")
  } else if (kind == "rejected") {
    if (id !~ /^DEC-R[0-9]+$/) errat(item_line, "rejected decision id \"" id "\" must match DEC-R<n>")
    require_field("summary"); require_field("reason")
  } else if (kind == "ruleset") {
    n_rulesets++
    if (id !~ /^RULESET-[0-9]+$/) errat(item_line, "ruleset id \"" id "\" must match RULESET-<n>")
    require_items("scenarios"); require_items("rules")
  }
  if (id in seen_at) errat(item_line, "duplicate id " id " (first used on line " seen_at[id] ")")
  else seen_at[id] = item_line
}

function end_item() {
  if (kind == "") return
  check_item()
  kind = ""; list = ""
  delete field; delete field_line; delete items
}


function check_top_level() {
  n = split("spec_name status business_case decisions requirements", required, " ")
  for (i = 1; i <= n; i++)
    if (!(required[i] in top_line)) errat(1, "missing top-level key \"" required[i] "\"")
}

function check_header() {
  if (("spec_name" in top_line) && spec_name == "") errat(spec_name_line, "spec_name is empty")
  check_placeholder(spec_name, spec_name_line, "spec_name")
  if (base ~ /^SPEC_.*\.yaml$/ && spec_name != "") {
    expected = substr(base, 6, length(base) - 10)
    if (expected != spec_name)
      errat(spec_name_line, "spec_name \"" spec_name "\" does not match filename (expected SPEC_" spec_name ".yaml)")
  }
  if (("status" in top_line) && status !~ /^(DRAFT|CONFIRMED|SUPERSEDED)$/)
    errat(status_line, "status \"" status "\" must be DRAFT, CONFIRMED or SUPERSEDED")
}

function check_business_case() {
  if (!("business_case" in top_line)) return
  if (summary == "") errat(top_line["business_case"], "business_case.summary is missing or empty")
  check_placeholder(summary, summary_line, "business_case.summary")
  if (n_outcomes < 1) errat(top_line["business_case"], "business_case.outcomes needs at least one outcome")
}

function check_decisions() {
  if (!("decisions" in top_line)) return
  if (!("accepted" in decision_line)) errat(top_line["decisions"], "decisions.accepted is missing")
  if (!("rejected" in decision_line)) errat(top_line["decisions"], "decisions.rejected is missing")
}

function check_requirements() {
  if (("requirements" in top_line) && n_rulesets < 1)
    errat(top_line["requirements"], "requirements needs at least one ruleset")
}

function check_document() {
  check_top_level()
  check_header()
  check_business_case()
  check_decisions()
  check_requirements()
}


function on_top_key(   key) {
  end_item()
  key = key_of($0)
  top_line[key] = NR
  section = key; subkey = ""
  if (key == "spec_name") { spec_name = value_of($0); spec_name_line = NR }
  if (key == "status")    { status = value_of($0);    status_line = NR }
}

function on_second_key(   key) {
  end_item()
  key = key_of($0)
  subkey = key
  if (section == "business_case" && key == "summary") { summary = value_of($0); summary_line = NR }
  if (section == "decisions") {
    if (key != "accepted" && key != "rejected")
      errat(NR, "unknown key \"" key "\" under decisions (expected accepted/rejected)")
    else decision_line[key] = NR
  }
}

function on_item_start() {
  end_item()
  if      (section == "business_case" && subkey == "outcomes") kind = "outcome"
  else if (section == "decisions" && subkey == "accepted")     kind = "accepted"
  else if (section == "decisions" && subkey == "rejected")     kind = "rejected"
  else if (section == "requirements")                          kind = "ruleset"
  else { errat(NR, "unexpected item outside outcomes/accepted/rejected/requirements"); return }
  id = value_of($0); item_line = NR; field_indent = indent($0) + 2
  if (id == "") errat(NR, "item has an empty id")
  check_placeholder(id, NR, "id")
}

function on_item_field(   key, v) {
  key = key_of($0); v = value_of($0); list = ""
  if (key == "scenarios" || key == "rules") {
    list = key
    items[key] = (v == "" || v == "[]") ? 0 : 1   # inline value counts as one item
  } else {
    field[key] = v; field_line[key] = NR
    check_placeholder(v, NR, id ": " key)
  }
}

function on_list_entry(   v) {
  v = item_of($0)
  if (v == "") { errat(NR, id ": empty " list " item"); return }
  items[list]++
  check_placeholder(v, NR, id ": " list " item")
}

function on_item_line() {
  if (indent($0) == field_indent && is_key_line($0)) on_item_field()
  else if (list != "" && is_list_item($0))           on_list_entry()
}

function dispatch() {
  if ($0 ~ /\t/) errat(NR, "tab character found; use spaces for indentation")
  if ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*:/)                          on_top_key()
  else if (indent($0) == 2 && $0 ~ /^  [A-Za-z_][A-Za-z0-9_]*:/) on_second_key()
  else if ($0 ~ /^[[:space:]]*-[[:space:]]+id:/)                  on_item_start()
  else if (kind != "")                                           on_item_line()
}


is_blank_or_comment($0) { next }
{ dispatch() }

END {
  end_item()
  check_document()
  finish(sprintf("OK: %s (%d outcomes, %d rulesets)", file, n_outcomes, n_rulesets))
}
