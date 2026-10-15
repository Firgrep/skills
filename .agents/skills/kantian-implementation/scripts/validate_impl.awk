# Validates a kantian-implementation IMPL yaml and cross-checks it against the
# SPEC it implements. Line-oriented: relies on the fixed layout described in
# SKILL.md rather than parsing YAML in general.
#
# Variables (-v): file      path of the IMPL file, for messages
#                 base      basename of the IMPL file
#                 specfile  path of the SPEC it implements
#
# Parser state
#   section            current top-level key
#   in_task, id, task_line   task being read, its id and first line
#   field[k], field_line[k]  scalar fields seen in the current task
#   has_list[k]        impl / verification / amendments keys seen in the task
#   list               list field being read (rulesets | impl | verification | amendments)
#   in_entry, entry_line, entry_indent, entry[k]   mapping entry inside a list
#   refs[i], ref_line[i], n_refs   rulesets referenced by the current task
#   n_impl, n_verification, n_pass, n_amend   entry counts for the current task
#   spec_rules[ruleset]   rule count per ruleset id defined by the spec

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


# Read ruleset ids and rule counts from the SPEC (what it defines, not
# whether it is valid; that is validate_spec's job).
function load_spec(   line, current, in_requirements, in_rules) {
  while ((getline line < specfile) > 0) {
    if (line ~ /^[A-Za-z_][A-Za-z0-9_]*:/) {
      in_requirements = (line ~ /^requirements:/); current = ""; in_rules = 0
    } else if (!in_requirements) {
      continue
    } else if (line ~ /^[[:space:]]*-[[:space:]]+id:/) {
      current = value_of(line); spec_rules[current] = 0; spec_ids[++n_spec] = current; in_rules = 0
    } else if (line ~ /^    [A-Za-z_][A-Za-z0-9_]*:/) {
      in_rules = (line ~ /^    rules:/)
    } else if (in_rules && current != "" && is_list_item(line)) {
      spec_rules[current]++
    }
  }
  close(specfile)
}


function require_entry(k) {
  if (!(k in entry) || entry[k] == "")
    errat(entry_line, id ": " list " entry needs a non-empty \"" k "\"")
}

function check_entry() {
  if (list == "impl") {
    n_impl++; require_entry("location")
  } else if (list == "verification") {
    n_verification++; require_entry("method"); require_entry("location")
    if (!("result" in entry))
      errat(entry_line, id ": verification entry needs a \"result\"")
    else if (entry["result"] !~ /^(pass|fail|accepted_risk)$/)
      errat(entry_line, id ": verification result \"" entry["result"] "\" must be pass, fail or accepted_risk")
    else if (entry["result"] == "pass")
      n_pass++
  } else if (list == "amendments") {
    n_amend++; require_entry("note")
  }
}

function end_entry() {
  if (!in_entry) return
  check_entry()
  in_entry = 0
  delete entry
}


function require_field(k) {
  if (!(k in field))       errat(task_line, id ": missing required field \"" k "\"")
  else if (field[k] == "") errat(field_line[k], id ": field \"" k "\" is empty")
}

function check_task_fields(   k, lists) {
  if (id !~ /^TASK-[0-9]+$/) errat(task_line, "task id \"" id "\" must match TASK-<n>")
  if (id in seen_at) errat(task_line, "duplicate id " id " (first used on line " seen_at[id] ")")
  else seen_at[id] = task_line

  require_field("name"); require_field("plan"); require_field("status")
  if (("status" in field) && field["status"] !~ /^(PENDING|IMPLEMENTED|VERIFIED)$/)
    errat(field_line["status"], id ": status \"" field["status"] "\" must be PENDING, IMPLEMENTED or VERIFIED")
  else if (field["status"] != "")
    status_count[field["status"]]++

  if (!has_rulesets)    errat(task_line, id ": missing required field \"rulesets\"")
  else if (n_refs < 1)  errat(task_line, id ": \"rulesets\" must reference at least one ruleset")
  split("impl verification amendments", lists, " ")
  for (k = 1; k <= 3; k++)
    if (!(lists[k] in has_list))
      errat(task_line, id ": missing required field \"" lists[k] "\" (use [] when empty)")
}

# A status is a claim; it must be backed by recorded evidence.
function check_task_evidence(   status) {
  status = field["status"]
  if ((status == "IMPLEMENTED" || status == "VERIFIED") && n_impl < 1)
    errat(field_line["status"], id ": status " status " requires at least one impl entry")
  if (status == "VERIFIED" && n_pass < 1)
    errat(field_line["status"], id ": status VERIFIED requires a verification entry with result: pass")
}

# Every reference must exist in the spec; record which rulesets / rules it covers.
function check_task_refs(   i, ref, dot, base_id, rule) {
  for (i = 1; i <= n_refs; i++) {
    ref = refs[i]
    if (ref !~ /^RULESET-[0-9]+(\.[0-9]+)?$/) {
      errat(ref_line[i], id ": ruleset reference \"" ref "\" must match RULESET-<n> or RULESET-<n>.<rule>")
      continue
    }
    dot = index(ref, ".")
    base_id = dot ? substr(ref, 1, dot - 1) : ref
    if (!(base_id in spec_rules)) {
      errat(ref_line[i], id ": " ref " does not exist in the spec")
    } else if (!dot) {
      covered_whole[base_id] = 1
    } else {
      rule = substr(ref, dot + 1) + 0
      if (rule < 1 || rule > spec_rules[base_id])
        errat(ref_line[i], id ": " ref " is out of range (" base_id " has " spec_rules[base_id] " rule(s))")
      else
        covered_rule[base_id, rule] = 1
    }
  }
}

function end_task() {
  end_entry()
  if (!in_task) return
  n_tasks++
  check_task_fields()
  check_task_evidence()
  check_task_refs()
  in_task = 0; list = ""; n_refs = 0; has_rulesets = 0
  n_impl = n_verification = n_pass = n_amend = 0
  delete field; delete field_line; delete has_list; delete refs; delete ref_line
}


function check_top_level() {
  if (!("impl_name" in top_line)) errat(1, "missing top-level key \"impl_name\"")
  if (!("tasks" in top_line))     errat(1, "missing top-level key \"tasks\"")
}

function check_impl_name(   expected) {
  if (!("impl_name" in top_line)) return
  if (impl_name !~ /^IMPL_.+/) {
    errat(impl_name_line, "impl_name \"" impl_name "\" must match IMPL_<feature-name>")
  } else if (base ~ /^IMPL_.*\.yaml$/) {
    expected = substr(base, 1, length(base) - 5)
    if (impl_name != expected)
      errat(impl_name_line, "impl_name \"" impl_name "\" does not match filename (expected " expected ")")
  }
  check_placeholder(impl_name, impl_name_line, "impl_name")
}

# Every spec ruleset must be covered: referenced whole, or via all of its rules.
function check_coverage(   i, spec_id, j, covered) {
  for (i = 1; i <= n_spec; i++) {
    spec_id = spec_ids[i]
    if (spec_id in covered_whole) continue
    covered = 0
    for (j = 1; j <= spec_rules[spec_id]; j++) if ((spec_id, j) in covered_rule) covered++
    if (spec_rules[spec_id] > 0 && covered == spec_rules[spec_id]) continue
    errat(("tasks" in top_line) ? top_line["tasks"] : 1, spec_id " from the spec is not covered by any task")
  }
}

function check_document() {
  check_top_level()
  check_impl_name()
  if (("tasks" in top_line) && n_tasks < 1) errat(top_line["tasks"], "tasks needs at least one task")
  check_coverage()
}


function on_top_key(   key) {
  end_task()
  key = key_of($0)
  top_line[key] = NR
  section = key
  if (key == "impl_name") { impl_name = value_of($0); impl_name_line = NR }
}

function on_task_start() {
  end_task()
  in_task = 1; id = value_of($0); task_line = NR; field_indent = 4
  if (id == "") errat(NR, "task has an empty id")
  check_placeholder(id, NR, "id")
}

# "rulesets: [A, B]"; the block form is handled by on_list_entry.
function read_inline_rulesets(v,   inner, parts, n, i) {
  if (v ~ /^\[.*\]$/) {
    inner = substr(v, 2, length(v) - 2)
    n = split(inner, parts, ",")
    for (i = 1; i <= n; i++) add_ref(parts[i], NR)
  } else if (v != "") {
    errat(NR, id ": \"rulesets\" must be a list such as [RULESET-1]")
  }
}

function add_ref(ref, line) {
  ref = unquote(ref)
  if (ref == "") return
  refs[++n_refs] = ref; ref_line[n_refs] = line
  check_placeholder(ref, line, id ": rulesets item")
}

function on_task_field(   key, v) {
  end_entry()
  key = key_of($0); v = value_of($0); list = ""
  if (key == "impl" || key == "verification" || key == "amendments") {
    has_list[key] = 1; list = key
    if (v != "" && v != "[]")
      errat(NR, id ": \"" key "\" must be [] or a block list of key: value entries")
  } else if (key == "rulesets") {
    has_rulesets = 1; list = "rulesets"
    read_inline_rulesets(v)
  } else {
    field[key] = v; field_line[key] = NR
    check_placeholder(v, NR, id ": " key)
  }
}

function set_entry_field(   key) {
  key = key_of($0)
  entry[key] = value_of($0)
  check_placeholder(entry[key], NR, id ": " list " " key)
}

function on_list_entry() {
  if (list == "rulesets") { add_ref(item_of($0), NR); return }
  end_entry()
  if ($0 !~ /^[[:space:]]*-[[:space:]]+[A-Za-z_][A-Za-z0-9_]*:/) {
    errat(NR, id ": " list " entries must be key: value mappings")
    return
  }
  in_entry = 1; entry_line = NR; entry_indent = indent($0) + 2
  set_entry_field()
}

function on_task_line() {
  if (indent($0) == field_indent && is_key_line($0))         on_task_field()
  else if (list != "" && is_list_item($0))                   on_list_entry()
  else if (in_entry && indent($0) == entry_indent && is_key_line($0)) set_entry_field()
}

function dispatch() {
  if ($0 ~ /\t/) errat(NR, "tab character found; use spaces for indentation")
  if ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*:/)                 on_top_key()
  else if (section != "tasks")                         return
  else if (indent($0) == 2 && $0 ~ /^  -[[:space:]]+id:/) on_task_start()
  else if (in_task)                                    on_task_line()
}


BEGIN { load_spec() }
is_blank_or_comment($0) { next }
{ dispatch() }

END {
  end_task()
  check_document()
  finish(sprintf("OK: %s (%d tasks: %d VERIFIED, %d IMPLEMENTED, %d PENDING)",
                 file, n_tasks, status_count["VERIFIED"], status_count["IMPLEMENTED"], status_count["PENDING"]))
}
